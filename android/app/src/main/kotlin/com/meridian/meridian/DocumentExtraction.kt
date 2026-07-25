package com.meridian.meridian

import android.graphics.BitmapFactory
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.regex.Pattern

/**
 * On-device contract extraction — Android side of app.meridian/extraction.
 *
 * There is no equivalent to iOS's Foundation Models tier here, so this
 * always reports the heuristic tier — see DocumentExtraction.swift for the
 * two-tier design this mirrors and the reasoning behind it. ML Kit's text
 * recognizer model ships inside the app (this uses the bundled-model
 * artifact, not the Play-Services one that fetches a model on first use),
 * so recognition never touches the network, matching the same privacy
 * contract as the iOS side.
 */
class DocumentExtraction : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "app.meridian/extraction"
        private const val MAX_DIMENSION = 2400

        fun register(messenger: BinaryMessenger) {
            MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler(DocumentExtraction())
        }

        /**
         * Reads only the image's dimensions first (inJustDecodeBounds), picks
         * the smallest power-of-two [BitmapFactory.Options.inSampleSize] that
         * keeps both sides under [maxDimension], then decodes at that size.
         * ML Kit's text recognizer needs enough resolution to read text, not
         * the sensor's full output — decoding full-size here is pure memory
         * risk with no accuracy benefit.
         */
        private fun decodeSampledBitmap(path: String, maxDimension: Int): android.graphics.Bitmap? {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

            var sample = 1
            while (bounds.outWidth / (sample * 2) >= maxDimension ||
                bounds.outHeight / (sample * 2) >= maxDimension
            ) {
                sample *= 2
            }

            val opts = BitmapFactory.Options().apply { inSampleSize = sample }
            return BitmapFactory.decodeFile(path, opts)
        }
    }

    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "capabilities" -> result.success(
                mapOf("ocr" to true, "onDeviceModel" to false, "network" to false)
            )
            "extract" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("bad_args", "path is required", null)
                    return
                }
                extract(path, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun extract(path: String, result: MethodChannel.Result) {
        val bitmap = try {
            decodeSampledBitmap(path, MAX_DIMENSION)
        } catch (e: OutOfMemoryError) {
            // A full-resolution camera photo (4000x3000+) decoded without
            // downsampling can exhaust the app heap on real hardware — an
            // emulator or a small test image won't reproduce this. Caught
            // as Throwable-adjacent deliberately: OutOfMemoryError is an
            // Error, not an Exception, so a plain `catch (e: Exception)`
            // here would let it crash the whole app instead of surfacing
            // as a normal "couldn't read that document" result.
            null
        } catch (e: Exception) {
            null
        }
        if (bitmap == null) {
            result.error("unreadable", "Could not read image at $path", null)
            return
        }

        val image = InputImage.fromBitmap(bitmap, 0)
        recognizer.process(image)
            .addOnSuccessListener { visionText -> result.success(heuristicExtract(visionText.text)) }
            .addOnFailureListener { e -> result.error("ocr_failed", e.localizedMessage, null) }
    }

    // MARK equivalent: DocumentExtraction.swift's Tier 2, same field shape.
    private fun heuristicExtract(text: String): Map<String, Any> {
        val expiry = findExpiryDate(text) ?: ""

        var noticeDays = 0
        val noticePatterns = listOf(
            Pattern.compile(
                "(\\d{1,3})\\s*(?:days?|gün)\\s*(?:prior|advance|notice|önce)",
                Pattern.CASE_INSENSITIVE,
            ),
            Pattern.compile(
                "notice\\s*(?:period\\s*)?of\\s*(\\d{1,3})\\s*days?",
                Pattern.CASE_INSENSITIVE,
            ),
            Pattern.compile(
                "(\\d{1,3})\\s*days?\\s*written\\s*notice",
                Pattern.CASE_INSENSITIVE,
            ),
        )
        for (p in noticePatterns) {
            val m = p.matcher(text)
            if (m.find()) {
                noticeDays = m.group(1)?.toIntOrNull() ?: 0
                break
            }
        }

        val renews = Pattern
            .compile("automatically\\s*renew|auto-?renew|tacit\\s*renewal", Pattern.CASE_INSENSITIVE)
            .matcher(text)
            .find()

        return mapOf(
            "title" to "",
            "counterparty" to "",
            "expiryDate" to expiry,
            "noticeDays" to noticeDays,
            "autoRenews" to renews,
            "amount" to 0.0,
            "currency" to "",
            "tier" to "heuristic",
            "confidence" to if (expiry.isEmpty()) "none" else "low",
        )
    }

    /**
     * Android has no NSDataDetector equivalent for free-text date detection,
     * so this matches a fixed set of common written formats instead. A
     * numeric D/M/Y vs M/D/Y match is only accepted when the order is
     * unambiguous — one component greater than 12 — same "never guess an
     * ambiguous date" rule CsvImportService follows; an ambiguous match is
     * skipped rather than resolved by assumption. Picks the latest
     * future-dated match found, same rule as the iOS side.
     */
    private fun findExpiryDate(text: String): String? {
        val now = Date()
        var best: Date? = null

        fun consider(d: Date?) {
            if (d != null && d.after(now) && (best == null || d.after(best))) best = d
        }

        val iso = Pattern.compile("\\b(\\d{4})-(\\d{2})-(\\d{2})\\b")
        var m = iso.matcher(text)
        while (m.find()) {
            consider(safeDate(m.group(1)!!.toInt(), m.group(2)!!.toInt(), m.group(3)!!.toInt()))
        }

        val numeric = Pattern.compile("\\b(\\d{1,2})[/.](\\d{1,2})[/.](\\d{4})\\b")
        m = numeric.matcher(text)
        while (m.find()) {
            val a = m.group(1)!!.toInt()
            val b = m.group(2)!!.toInt()
            val y = m.group(3)!!.toInt()
            val resolved = when {
                a > 12 && b <= 12 -> intArrayOf(y, b, a) // unambiguous D/M
                b > 12 && a <= 12 -> intArrayOf(y, a, b) // unambiguous M/D
                else -> null // ambiguous — never guess
            }
            if (resolved != null) consider(safeDate(resolved[0], resolved[1], resolved[2]))
        }

        val monthNameFirst = Pattern.compile("\\b([A-Za-z]{3,})\\.?\\s+(\\d{1,2}),?\\s+(\\d{4})\\b")
        m = monthNameFirst.matcher(text)
        while (m.find()) {
            val raw = "${m.group(1)} ${m.group(2)} ${m.group(3)}"
            consider(parseWithFormat("MMMM d yyyy", raw) ?: parseWithFormat("MMM d yyyy", raw))
        }

        val dayFirst = Pattern.compile("\\b(\\d{1,2})\\s+([A-Za-z]{3,})\\.?\\s+(\\d{4})\\b")
        m = dayFirst.matcher(text)
        while (m.find()) {
            val raw = "${m.group(1)} ${m.group(2)} ${m.group(3)}"
            consider(parseWithFormat("d MMMM yyyy", raw) ?: parseWithFormat("d MMM yyyy", raw))
        }

        return best?.let { SimpleDateFormat("yyyy-MM-dd", Locale.US).format(it) }
    }

    private fun safeDate(year: Int, month: Int, day: Int): Date? {
        return try {
            val cal = Calendar.getInstance()
            cal.isLenient = false
            cal.set(year, month - 1, day, 0, 0, 0)
            cal.time
        } catch (e: Exception) {
            null
        }
    }

    private fun parseWithFormat(pattern: String, raw: String): Date? {
        return try {
            val fmt = SimpleDateFormat(pattern, Locale.US)
            fmt.isLenient = false
            fmt.parse(raw)
        } catch (e: Exception) {
            null
        }
    }
}
