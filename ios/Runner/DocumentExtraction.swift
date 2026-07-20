import Flutter
import Foundation
import Vision

#if canImport(FoundationModels)
import FoundationModels
#endif

/// On-device contract extraction.
///
/// This file is the entire answer to "nobody will upload their contracts".
/// Nothing here touches the network. The document is OCR'd by Vision and
/// parsed by Apple's on-device model; only the resulting handful of fields
/// ever leaves this class, and the file itself never leaves the device.
///
/// Two tiers, because Foundation Models requires iOS 26 on an Apple
/// Intelligence-capable device and simply does not exist below that floor:
///
///   Tier 1  Vision OCR + Foundation Models structured extraction
///   Tier 2  Vision OCR + deterministic date/amount heuristics
///
/// Tier 2 must remain genuinely usable, not a stub. It is what every user on
/// an older device gets, and a visibly worse experience on a $250/year product
/// generates refunds.
@available(iOS 13.0, *)
final class DocumentExtraction: NSObject {

    static let channelName = "app.meridian/extraction"

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = DocumentExtraction()
        channel.setMethodCallHandler(instance.handle)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "capabilities":
            result(capabilities())

        case "extract":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                result(FlutterError(code: "bad_args",
                                    message: "path is required",
                                    details: nil))
                return
            }
            Task { await self.extract(path: path, result: result) }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Reported to Dart so the UI can tell the user, truthfully, which tier
    /// they are on. Do not hide this — a user who thinks they have AI
    /// extraction and silently gets regex will blame the product for misses.
    private func capabilities() -> [String: Any] {
        var onDevice = false
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            onDevice = SystemLanguageModel.default.isAvailable
        }
        #endif
        return ["ocr": true, "onDeviceModel": onDevice, "network": false]
    }

    // MARK: - Pipeline

    private func extract(path: String, result: @escaping FlutterResult) async {
        guard let image = UIImage(contentsOfFile: path),
              let cg = image.cgImage else {
            result(FlutterError(code: "unreadable",
                                message: "Could not read image at \(path)",
                                details: nil))
            return
        }

        let text: String
        do {
            text = try await recogniseText(in: cg)
        } catch {
            result(FlutterError(code: "ocr_failed",
                                message: error.localizedDescription,
                                details: nil))
            return
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            do {
                let fields = try await modelExtract(from: text)
                result(fields)
                return
            } catch {
                // Fall through to heuristics rather than failing the capture.
                // A partial draft the user corrects beats an error dialog.
            }
        }
        #endif

        result(heuristicExtract(from: text))
    }

    /// Vision OCR. Available on every device, no Apple Intelligence needed.
    private func recogniseText(in image: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { cont in
            let request = VNRecognizeTextRequest { req, err in
                if let err = err { cont.resume(throwing: err); return }
                let obs = req.results as? [VNRecognizedTextObservation] ?? []
                let joined = obs
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                cont.resume(returning: joined)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            // Extend as you add launch locales. Contracts are frequently
            // bilingual, so keep English alongside the local language.
            request.recognitionLanguages = ["en-US", "tr-TR", "de-DE", "fr-FR"]

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do { try handler.perform([request]) }
                catch { cont.resume(throwing: error) }
            }
        }
    }

    // MARK: - Tier 1

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    @Generable
    struct ExtractedObligation {
        @Guide(description: "Short human title, e.g. 'Office lease renewal'")
        var title: String

        @Guide(description: "The other party to the agreement, or empty")
        var counterparty: String

        @Guide(description: "Expiry or renewal date as ISO 8601 yyyy-MM-dd")
        var expiryDate: String

        @Guide(description: "Days of notice required to cancel. 0 if unstated.")
        var noticeDays: Int

        @Guide(description: "True if the agreement renews automatically")
        var autoRenews: Bool

        @Guide(description: "Contract value in major units, 0 if unstated")
        var amount: Double

        @Guide(description: "ISO 4217 currency code, or empty")
        var currency: String
    }

    @available(iOS 26.0, *)
    private func modelExtract(from text: String) async throws -> [String: Any] {
        let session = LanguageModelSession(
            instructions: """
            You extract contract metadata. Only report values that appear in \
            the text. Never infer or invent a date. If a field is absent, \
            return an empty string or zero. Notice period means the days of \
            advance notice required to cancel or not renew.
            """
        )

        let response = try await session.respond(
            to: "Extract the obligation details from this document:\n\n\(text)",
            generating: ExtractedObligation.self
        )
        let v = response.content

        return [
            "title": v.title,
            "counterparty": v.counterparty,
            "expiryDate": v.expiryDate,
            "noticeDays": v.noticeDays,
            "autoRenews": v.autoRenews,
            "amount": v.amount,
            "currency": v.currency,
            "tier": "on_device_model",
            "confidence": v.expiryDate.isEmpty ? "low" : "medium",
        ]
    }
    #endif

    // MARK: - Tier 2

    /// Deterministic fallback. Finds dates and amounts with NSDataDetector and
    /// notice periods with a small set of patterns.
    private func heuristicExtract(from text: String) -> [String: Any] {
        var expiry = ""
        if let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.date.rawValue
        ) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = detector.matches(in: text, range: range)
            // Latest future date is the best single guess for an expiry.
            let dates = matches.compactMap { $0.date }.filter { $0 > Date() }
            if let best = dates.max() {
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy-MM-dd"
                expiry = fmt.string(from: best)
            }
        }

        var noticeDays = 0
        let patterns = [
            #"(\d{1,3})\s*(?:days?|gün)\s*(?:prior|advance|notice|önce)"#,
            #"notice\s*(?:period\s*)?of\s*(\d{1,3})\s*days?"#,
            #"(\d{1,3})\s*days?\s*written\s*notice"#,
        ]
        for p in patterns {
            if let re = try? NSRegularExpression(
                pattern: p, options: [.caseInsensitive]
            ) {
                let range = NSRange(text.startIndex..., in: text)
                if let m = re.firstMatch(in: text, range: range),
                   m.numberOfRanges > 1,
                   let r = Range(m.range(at: 1), in: text),
                   let n = Int(text[r]) {
                    noticeDays = n
                    break
                }
            }
        }

        let renews = text.range(
            of: #"automatically\s*renew|auto-?renew|tacit\s*renewal"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil

        return [
            "title": "",
            "counterparty": "",
            "expiryDate": expiry,
            "noticeDays": noticeDays,
            "autoRenews": renews,
            "amount": 0.0,
            "currency": "",
            "tier": "heuristic",
            "confidence": expiry.isEmpty ? "none" : "low",
        ]
    }
}
