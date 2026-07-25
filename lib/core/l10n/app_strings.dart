import 'package:flutter/widgets.dart';

/// Hand-rolled, locale-aware UI strings.
///
/// This project also carries `l10n.yaml` + ARB files wired for Flutter's
/// `gen-l10n` codegen, but that generated class was never actually imported
/// anywhere — dead scaffolding. This covers the same ground a different way:
/// no build step, so nothing here can silently go stale relative to a
/// generated file nobody regenerates. Extending language coverage means
/// adding a row to [_t] below, same as it would adding a line to an ARB
/// file — if this project's build tooling gets exercised again later,
/// migrating these keys into the ARB files is a mechanical follow-up, not a
/// redesign.
///
/// Covers Horizon, Settings, the obligation row/action sheet, and
/// onboarding — the screens a new install actually opens into. The capture
/// form, CSV import, scan, search, and Exposure screens still read in
/// English regardless of device language; extending coverage there follows
/// the exact same pattern.
class AppStrings {
  const AppStrings(this.languageCode);

  final String languageCode;

  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context).languageCode);

  String _t(String key) {
    final row = _table[key];
    if (row == null) return key;
    return row[languageCode] ?? row['en']!;
  }

  String get navHorizon => _t('navHorizon');
  String get navTimeline => _t('navTimeline');
  String get navExposure => _t('navExposure');
  String get navSettings => _t('navSettings');
  String get captureSemanticLabel => _t('captureSemanticLabel');

  String get horizonTitle => _t('horizonTitle');
  String get searchTooltip => _t('searchTooltip');
  String get groupOverdue => _t('groupOverdue');
  String get groupThisWeek => _t('groupThisWeek');
  String get groupThisMonth => _t('groupThisMonth');
  String get emptyTitle => _t('emptyTitle');
  String get emptyBody => _t('emptyBody');
  String get errorLoad => _t('errorLoad');

  String draftBanner(int count, String firstTitle) {
    if (count == 1) {
      final untitled = _t('untitled');
      return '${_t('draftReadyPrefix')}${firstTitle.isEmpty ? untitled : firstTitle}';
    }
    return _t('draftsAwaiting').replaceAll('{count}', '$count');
  }

  String overflowLink(int count) {
    final key = count == 1 ? 'overflowLinkOne' : 'overflowLinkMany';
    return _t(key).replaceAll('{count}', '$count');
  }

  String get actionResolve => _t('actionResolve');
  String get actionSnooze => _t('actionSnooze');
  String get actionSnooze7 => _t('actionSnooze7');
  String get actionEdit => _t('actionEdit');
  String get actionDelete => _t('actionDelete');

  String get deleteConfirmTitle => _t('deleteConfirmTitle');
  String get deleteConfirmBody => _t('deleteConfirmBody');
  String get cancel => _t('cancel');

  String get tagAutoRenews => _t('tagAutoRenews');
  String get tagNoticeAssumed => _t('tagNoticeAssumed');
  String snoozedUntil(String date) =>
      _t('tagSnoozedUntil').replaceAll('{date}', date);

  String dayLabel(int days) {
    if (days < 0) return _t('dayOver').replaceAll('{count}', '${-days}');
    if (days == 0) return _t('dayToday');
    return _t('dayLeft').replaceAll('{count}', '$days');
  }

  String get settingsTitle => _t('settingsTitle');
  String get sectionSecurity => _t('sectionSecurity');
  String get lockTitle => _t('lockTitle');
  String get lockSubtitle => _t('lockSubtitle');
  String get sectionHelp => _t('sectionHelp');
  String get replayWalkthrough => _t('replayWalkthrough');
  String get sectionAbout => _t('sectionAbout');

  String get lockScreenTitle => _t('lockScreenTitle');
  String get lockScreenBody => _t('lockScreenBody');
  String get lockScreenChecking => _t('lockScreenChecking');
  String get lockScreenUnlock => _t('lockScreenUnlock');

  String get onboardingSkip => _t('onboardingSkip');
  String get onboardingNext => _t('onboardingNext');
  String get onboardingGetStarted => _t('onboardingGetStarted');

  String onboardTitle(int step) => _t('onboardTitle$step');
  String onboardBody(int step) => _t('onboardBody$step');

  // Capture sheet
  String get captureAddTitle => _t('captureAddTitle');
  String get captureManualTitle => _t('captureManualTitle');
  String get captureManualSubtitle => _t('captureManualSubtitle');
  String get captureScanTitle => _t('captureScanTitle');
  String get captureScanSubtitle => _t('captureScanSubtitle');
  String get captureImportTitle => _t('captureImportTitle');
  String get captureImportSubtitle => _t('captureImportSubtitle');

  // Scan capture
  String get scanPrompt => _t('scanPrompt');
  String get scanErrorUnreadable => _t('scanErrorUnreadable');
  String get scanErrorUnavailable => _t('scanErrorUnavailable');
  String get scanErrorGeneric => _t('scanErrorGeneric');
  String get scanReading => _t('scanReading');
  String get scanTakePhoto => _t('scanTakePhoto');
  String get scanChooseLibrary => _t('scanChooseLibrary');

  // CSV import
  String get csvPickIntro => _t('csvPickIntro');
  String get csvPickHint => _t('csvPickHint');
  String get csvErrorRead => _t('csvErrorRead');
  String get csvErrorHeaderRow => _t('csvErrorHeaderRow');
  String get csvErrorGeneric => _t('csvErrorGeneric');
  String get csvReading => _t('csvReading');
  String get csvChooseFile => _t('csvChooseFile');
  String csvFileRowCount(String fileName, int rowCount) {
    final key = rowCount == 1 ? 'csvFileRowCountOne' : 'csvFileRowCountMany';
    return _t(key)
        .replaceAll('{file}', fileName)
        .replaceAll('{count}', '$rowCount');
  }

  String get csvMatchColumns => _t('csvMatchColumns');
  String get csvFieldTitle => _t('csvFieldTitle');
  String get csvFieldDate => _t('csvFieldDate');
  String get csvFieldCategory => _t('csvFieldCategory');
  String get csvFieldCounterparty => _t('csvFieldCounterparty');
  String get csvFieldNotice => _t('csvFieldNotice');
  String get csvFieldValue => _t('csvFieldValue');
  String get csvFieldCurrency => _t('csvFieldCurrency');
  String get csvFieldAutoRenews => _t('csvFieldAutoRenews');
  String get csvNoneOption => _t('csvNoneOption');
  String get csvPreviewButton => _t('csvPreviewButton');
  String csvReadyToImport(int count) =>
      _t('csvReadyToImport').replaceAll('{count}', '$count');
  String csvReadyNeedAttention(int ready, int needAttention) => _t(
        'csvReadyNeedAttention',
      ).replaceAll('{ready}', '$ready').replaceAll(
            '{needAttention}',
            '$needAttention',
          );
  String get csvEditMapping => _t('csvEditMapping');
  String csvRowLabel(int n) => _t('csvRowLabel').replaceAll('{n}', '$n');
  String csvExpires(String date) =>
      _t('csvExpires').replaceAll('{date}', date);
  String get csvImporting => _t('csvImporting');
  String csvImportButton(int count) {
    final key = count == 1 ? 'csvImportButtonOne' : 'csvImportButtonMany';
    return _t(key).replaceAll('{count}', '$count');
  }

  // Search
  String get searchHint => _t('searchHint');
  String get searchPrompt => _t('searchPrompt');
  String searchNoResults(String query) =>
      _t('searchNoResults').replaceAll('{query}', query);

  // Timeline
  String get timelineTitle => _t('timelineTitle');
  String get statThisWeek => _t('statThisWeek');
  String get statThisMonth => _t('statThisMonth');
  String get statNothingCritical => _t('statNothingCritical');
  String statNCritical(int n) =>
      _t('statNCritical').replaceAll('{n}', '$n');
  String get netThisMonth => _t('netThisMonth');
  String get netNothingValued => _t('netNothingValued');
  String get netCaption => _t('netCaption');
  String get nothingDue => _t('nothingDue');

  // Exposure
  String get exposureTitle => _t('exposureTitle');
  String get exposureCommitted12mo => _t('exposureCommitted12mo');
  String exposureEntersWindow(String amount) =>
      _t('exposureEntersWindow').replaceAll('{amount}', amount);
  String get exposureEmptyTitle => _t('exposureEmptyTitle');
  String get exposureEmptyBody => _t('exposureEmptyBody');

  // Obligation form
  String get formReviewDraft => _t('formReviewDraft');
  String get formEditObligation => _t('formEditObligation');
  String get formNewObligation => _t('formNewObligation');
  String get formTitleField => _t('formTitleField');
  String get formExpiryDate => _t('formExpiryDate');
  String get formSelectDate => _t('formSelectDate');
  String get formCategory => _t('formCategory');
  String get formCounterparty => _t('formCounterparty');
  String get formNoticeDays => _t('formNoticeDays');
  String formValue(String currency) =>
      _t('formValue').replaceAll('{currency}', currency);
  String get formYouPay => _t('formYouPay');
  String get formYouReceive => _t('formYouReceive');
  String get formRenewsAutomatically => _t('formRenewsAutomatically');
  String get formRoutine => _t('formRoutine');
  String get formImportant => _t('formImportant');
  String get formCritical => _t('formCritical');
  String get formMoreDetails => _t('formMoreDetails');
  String get formRequired => _t('formRequired');
  String get formSaving => _t('formSaving');
  String get formConfirmButton => _t('formConfirmButton');
  String get formSaveButton => _t('formSaveButton');

  // Recurrence picker
  String get recurrenceTitle => _t('recurrenceTitle');
  String get recurrenceFrequencyLabel => _t('recurrenceFrequencyLabel');
  String get recurrenceEvery => _t('recurrenceEvery');
  String recurrenceNextRenewal(String date) =>
      _t('recurrenceNextRenewal').replaceAll('{date}', date);
  String frequencyLabel(String frequencyName) => _t('freq_$frequencyName');
  String recurrenceUnitLabel(String frequencyName, int interval) {
    final suffix = interval == 1 ? 'one' : 'many';
    return _t('unit_${frequencyName}_$suffix');
  }

  // Month calendar
  String get navPreviousMonth => _t('navPreviousMonth');
  String get navNextMonth => _t('navNextMonth');
  String weekdayLetter(int index) => _t('weekdayLetter$index');
  String weekdayFull(int index) => _t('weekdayFull$index');
  // Obligation category (see ObligationCategoryLabel in obligation.dart,
  // which stays the fallback/canonical English form and what search
  // matches against — this is a display-only localization on top of it)
  String categoryLabel(String categoryName) => _t('cat_$categoryName');

  String dayCellLabel(String formattedDate, bool isToday, int count) {
    final today = isToday ? _t('dayCellToday') : '';
    final due = count == 0
        ? _t('dayCellNothingDue')
        : count == 1
            ? _t('dayCellOneDue')
            : _t('dayCellNDue').replaceAll('{count}', '$count');
    return '$formattedDate$today, $due';
  }
}

const _table = <String, Map<String, String>>{
  'navHorizon': {
    'en': 'Horizon', 'tr': 'Ufuk', 'de': 'Horizont', 'fr': 'Horizon', 'es': 'Horizonte',
  },
  'navTimeline': {
    'en': 'Timeline', 'tr': 'Zaman çizelgesi', 'de': 'Zeitleiste', 'fr': 'Chronologie', 'es': 'Cronología',
  },
  'navExposure': {
    'en': 'Exposure', 'tr': 'Maruziyet', 'de': 'Exponierung', 'fr': 'Exposition', 'es': 'Exposición',
  },
  'navSettings': {
    'en': 'Settings', 'tr': 'Ayarlar', 'de': 'Einstellungen', 'fr': 'Réglages', 'es': 'Ajustes',
  },
  'captureSemanticLabel': {
    'en': 'Add an obligation', 'tr': 'Bir yükümlülük ekle', 'de': 'Verpflichtung hinzufügen', 'fr': 'Ajouter une obligation', 'es': 'Añadir una obligación',
  },
  'horizonTitle': {
    'en': 'Horizon', 'tr': 'Ufuk', 'de': 'Horizont', 'fr': 'Horizon', 'es': 'Horizonte',
  },
  'searchTooltip': {
    'en': 'Search', 'tr': 'Ara', 'de': 'Suchen', 'fr': 'Rechercher', 'es': 'Buscar',
  },
  'groupOverdue': {
    'en': 'Overdue', 'tr': 'Gecikmiş', 'de': 'Überfällig', 'fr': 'En retard', 'es': 'Vencido',
  },
  'groupThisWeek': {
    'en': 'This week', 'tr': 'Bu hafta', 'de': 'Diese Woche', 'fr': 'Cette semaine', 'es': 'Esta semana',
  },
  'groupThisMonth': {
    'en': 'This month', 'tr': 'Bu ay', 'de': 'Diesen Monat', 'fr': 'Ce mois-ci', 'es': 'Este mes',
  },
  'emptyTitle': {
    'en': 'Nothing is waiting on you.', 'tr': 'Bekleyen bir şey yok.', 'de': 'Nichts wartet auf dich.', 'fr': "Rien ne vous attend.", 'es': 'Nada te está esperando.',
  },
  'emptyBody': {
    'en': 'Add your first contract or renewal and Meridian will tell you when you need to act — not when it is already too late.',
    'tr': 'İlk sözleşmenizi veya yenilemenizi ekleyin; Meridian, çok geç olmadan önce ne zaman harekete geçmeniz gerektiğini size söyleyecek.',
    'de': 'Füge deinen ersten Vertrag oder deine erste Verlängerung hinzu — Meridian sagt dir, wann du handeln musst, nicht erst, wenn es zu spät ist.',
    'fr': "Ajoutez votre premier contrat ou renouvellement et Meridian vous dira quand agir — pas quand il sera déjà trop tard.",
    'es': 'Añade tu primer contrato o renovación y Meridian te dirá cuándo actuar, no cuando ya sea demasiado tarde.',
  },
  'errorLoad': {
    'en': 'Could not load your obligations.', 'tr': 'Yükümlülükleriniz yüklenemedi.', 'de': 'Deine Verpflichtungen konnten nicht geladen werden.', 'fr': "Impossible de charger vos obligations.", 'es': 'No se pudieron cargar tus obligaciones.',
  },
  'draftReadyPrefix': {
    'en': 'Draft ready — ', 'tr': 'Taslak hazır — ', 'de': 'Entwurf bereit — ', 'fr': 'Brouillon prêt — ', 'es': 'Borrador listo — ',
  },
  'untitled': {
    'en': 'untitled', 'tr': 'başlıksız', 'de': 'unbenannt', 'fr': 'sans titre', 'es': 'sin título',
  },
  'draftsAwaiting': {
    'en': '{count} drafts awaiting review', 'tr': '{count} taslak incelemenizi bekliyor', 'de': '{count} Entwürfe warten auf Prüfung', 'fr': '{count} brouillons en attente de révision', 'es': '{count} borradores a la espera de revisión',
  },
  'overflowLinkOne': {
    'en': '1 more obligation further out — view Timeline', 'tr': '1 yükümlülük daha ileride — Zaman çizelgesine bak', 'de': 'Noch 1 Verpflichtung weiter in der Zukunft — Zeitleiste ansehen', 'fr': '1 obligation de plus, plus tard — voir la Chronologie', 'es': '1 obligación más adelante — ver la Cronología',
  },
  'overflowLinkMany': {
    'en': '{count} more obligations further out — view Timeline', 'tr': '{count} yükümlülük daha ileride — Zaman çizelgesine bak', 'de': 'Noch {count} Verpflichtungen weiter in der Zukunft — Zeitleiste ansehen', 'fr': '{count} obligations de plus, plus tard — voir la Chronologie', 'es': '{count} obligaciones más adelante — ver la Cronología',
  },
  'actionResolve': {
    'en': 'Resolve', 'tr': 'Tamamla', 'de': 'Erledigen', 'fr': 'Résoudre', 'es': 'Resolver',
  },
  'actionSnooze': {
    'en': 'Snooze', 'tr': 'Ertele', 'de': 'Verschieben', 'fr': 'Reporter', 'es': 'Posponer',
  },
  'actionSnooze7': {
    'en': 'Snooze 7 days', 'tr': '7 gün ertele', 'de': 'Um 7 Tage verschieben', 'fr': 'Reporter de 7 jours', 'es': 'Posponer 7 días',
  },
  'actionEdit': {
    'en': 'Edit', 'tr': 'Düzenle', 'de': 'Bearbeiten', 'fr': 'Modifier', 'es': 'Editar',
  },
  'actionDelete': {
    'en': 'Delete', 'tr': 'Sil', 'de': 'Löschen', 'fr': 'Supprimer', 'es': 'Eliminar',
  },
  'deleteConfirmTitle': {
    'en': 'Delete this obligation?', 'tr': 'Bu yükümlülük silinsin mi?', 'de': 'Diese Verpflichtung löschen?', 'fr': 'Supprimer cette obligation ?', 'es': '¿Eliminar esta obligación?',
  },
  'deleteConfirmBody': {
    'en': 'This removes it and its scheduled alerts permanently. This cannot be undone.',
    'tr': 'Bu işlem, kaydı ve planlanmış uyarılarını kalıcı olarak kaldırır. Geri alınamaz.',
    'de': 'Dies entfernt sie und ihre geplanten Erinnerungen dauerhaft. Das kann nicht rückgängig gemacht werden.',
    'fr': "Cela la supprime ainsi que ses alertes programmées, définitivement. Cette action est irréversible.",
    'es': 'Esto la elimina, junto con sus alertas programadas, de forma permanente. No se puede deshacer.',
  },
  'cancel': {
    'en': 'Cancel', 'tr': 'Vazgeç', 'de': 'Abbrechen', 'fr': 'Annuler', 'es': 'Cancelar',
  },
  'tagAutoRenews': {
    'en': 'Renews unless cancelled', 'tr': 'İptal edilmezse yenilenir', 'de': 'Verlängert sich, sofern nicht gekündigt', 'fr': 'Se renouvelle sauf annulation', 'es': 'Se renueva salvo cancelación',
  },
  'tagNoticeAssumed': {
    'en': 'Notice period assumed', 'tr': 'İhbar süresi varsayıldı', 'de': 'Kündigungsfrist angenommen', 'fr': 'Préavis supposé', 'es': 'Plazo de preaviso asumido',
  },
  'tagSnoozedUntil': {
    'en': 'Snoozed until {date}', 'tr': "{date} tarihine kadar ertelendi", 'de': 'Verschoben bis {date}', 'fr': "Reporté au {date}", 'es': 'Pospuesto hasta el {date}',
  },
  'dayToday': {
    'en': 'Today', 'tr': 'Bugün', 'de': 'Heute', 'fr': "Aujourd'hui", 'es': 'Hoy',
  },
  'dayOver': {
    'en': '{count}d over', 'tr': '{count}g gecikti', 'de': '{count} T. überfällig', 'fr': '{count} j de retard', 'es': '{count} d de retraso',
  },
  'dayLeft': {
    'en': '{count}d', 'tr': '{count}g', 'de': '{count} T.', 'fr': '{count} j', 'es': '{count} d',
  },
  'settingsTitle': {
    'en': 'Settings', 'tr': 'Ayarlar', 'de': 'Einstellungen', 'fr': 'Réglages', 'es': 'Ajustes',
  },
  'sectionSecurity': {
    'en': 'SECURITY', 'tr': 'GÜVENLİK', 'de': 'SICHERHEIT', 'fr': 'SÉCURITÉ', 'es': 'SEGURIDAD',
  },
  'lockTitle': {
    'en': 'Require Face ID / biometric unlock', 'tr': 'Face ID / biyometrik kilit aç zorunlu olsun', 'de': 'Face ID / biometrische Entsperrung erforderlich', 'fr': 'Exiger Face ID / déverrouillage biométrique', 'es': 'Requerir Face ID / desbloqueo biométrico',
  },
  'lockSubtitle': {
    'en': 'Recommended — this app holds contracts and financial details.',
    'tr': 'Önerilir — bu uygulama sözleşmeleri ve finansal bilgileri saklar.',
    'de': 'Empfohlen — diese App enthält Verträge und Finanzdaten.',
    'fr': "Recommandé — cette application contient des contrats et des données financières.",
    'es': 'Recomendado: esta app contiene contratos y datos financieros.',
  },
  'sectionHelp': {
    'en': 'HELP', 'tr': 'YARDIM', 'de': 'HILFE', 'fr': 'AIDE', 'es': 'AYUDA',
  },
  'replayWalkthrough': {
    'en': 'Replay walkthrough', 'tr': 'Tanıtımı tekrar oynat', 'de': 'Einführung erneut ansehen', 'fr': 'Revoir la présentation', 'es': 'Repetir la introducción',
  },
  'sectionAbout': {
    'en': 'ABOUT', 'tr': 'HAKKINDA', 'de': 'ÜBER', 'fr': 'À PROPOS', 'es': 'ACERCA DE',
  },
  'lockScreenTitle': {
    'en': 'Meridian is locked', 'tr': 'Meridian kilitli', 'de': 'Meridian ist gesperrt', 'fr': 'Meridian est verrouillé', 'es': 'Meridian está bloqueado',
  },
  'lockScreenBody': {
    'en': 'Your contracts and financial details stay private.', 'tr': 'Sözleşmeleriniz ve finansal bilgileriniz gizli kalır.', 'de': 'Deine Verträge und Finanzdaten bleiben privat.', 'fr': 'Vos contrats et informations financières restent privés.', 'es': 'Tus contratos y datos financieros permanecen privados.',
  },
  'lockScreenChecking': {
    'en': 'Checking…', 'tr': 'Kontrol ediliyor…', 'de': 'Wird geprüft…', 'fr': 'Vérification…', 'es': 'Comprobando…',
  },
  'lockScreenUnlock': {
    'en': 'Unlock', 'tr': 'Kilidi aç', 'de': 'Entsperren', 'fr': 'Déverrouiller', 'es': 'Desbloquear',
  },
  'onboardingSkip': {
    'en': 'Skip', 'tr': 'Atla', 'de': 'Überspringen', 'fr': 'Passer', 'es': 'Omitir',
  },
  'onboardingNext': {
    'en': 'Next', 'tr': 'İleri', 'de': 'Weiter', 'fr': 'Suivant', 'es': 'Siguiente',
  },
  'onboardingGetStarted': {
    'en': 'Get started', 'tr': "Başla", 'de': 'Loslegen', 'fr': 'Commencer', 'es': 'Empezar',
  },
  'onboardTitle1': {
    'en': 'Meet Meridian', 'tr': "Meridian'la tanışın", 'de': 'Lerne Meridian kennen', 'fr': 'Découvrez Meridian', 'es': 'Conoce Meridian',
  },
  'onboardBody1': {
    'en': 'Every contract, subscription, licence, and deadline that has a real consequence if you miss it — tracked in one place instead of scattered across email and memory.',
    'tr': 'Kaçırıldığında gerçek bir sonucu olan her sözleşme, abonelik, lisans ve son tarih — e-posta ve hafızanıza dağılmak yerine tek bir yerde.',
    'de': 'Jeder Vertrag, jedes Abo, jede Lizenz und jede Frist mit echten Folgen bei Versäumnis — an einem Ort statt verstreut in E-Mails und im Gedächtnis.',
    'fr': "Chaque contrat, abonnement, licence et échéance ayant une vraie conséquence en cas d'oubli — regroupés en un seul endroit au lieu d'être dispersés entre e-mails et mémoire.",
    'es': 'Cada contrato, suscripción, licencia y plazo con una consecuencia real si se te pasa, todo en un solo lugar en vez de disperso entre el correo y la memoria.',
  },
  'onboardTitle2': {
    'en': 'Horizon is home', 'tr': 'Ana ekranınız Ufuk', 'de': 'Horizont ist dein Start', 'fr': "Horizon, c'est l'accueil", 'es': 'Horizonte es tu inicio',
  },
  'onboardBody2': {
    'en': 'Not a calendar — a prioritised list of what actually needs you soon. Overdue first, then this week, then this month. Anything further out stays out of the way until it matters.',
    'tr': 'Bir takvim değil — yakında sizi gerçekten gerektirecek şeylerin öncelikli bir listesi. Önce gecikmiş, sonra bu hafta, sonra bu ay. Daha ileride olanlar, önemli hale gelene kadar yolunuzun dışında kalır.',
    'de': 'Kein Kalender — eine priorisierte Liste dessen, was bald wirklich deine Aufmerksamkeit braucht. Erst Überfälliges, dann diese Woche, dann dieser Monat. Alles Weitere bleibt aus dem Weg, bis es zählt.',
    'fr': "Pas un calendrier — une liste priorisée de ce qui a vraiment besoin de vous bientôt. D'abord le retard, puis cette semaine, puis ce mois-ci. Le reste ne vous encombre pas tant que ça n'a pas d'importance.",
    'es': 'No es un calendario, es una lista priorizada de lo que realmente necesita tu atención pronto. Primero lo vencido, luego esta semana, luego este mes. Lo demás no estorba hasta que importa.',
  },
  'onboardTitle3': {
    'en': 'Capture in seconds', 'tr': 'Saniyeler içinde ekleyin', 'de': 'In Sekunden erfassen', 'fr': 'Ajoutez en quelques secondes', 'es': 'Añade en segundos',
  },
  'onboardBody3': {
    'en': 'Tap the centre button to add something — scan a document, import a spreadsheet, or just type the title and date. Title and date are the only things required.',
    'tr': 'Bir şey eklemek için ortadaki düğmeye dokunun — bir belge tarayın, bir e-tablo içe aktarın veya sadece başlık ve tarihi yazın. Yalnızca başlık ve tarih zorunludur.',
    'de': 'Tippe auf die mittlere Schaltfläche, um etwas hinzuzufügen — scanne ein Dokument, importiere eine Tabelle oder gib einfach Titel und Datum ein. Nur Titel und Datum sind Pflicht.',
    'fr': "Appuyez sur le bouton central pour ajouter un élément — scannez un document, importez un tableur, ou saisissez simplement le titre et la date. Seuls le titre et la date sont requis.",
    'es': 'Toca el botón central para añadir algo: escanea un documento, importa una hoja de cálculo o simplemente escribe el título y la fecha. Solo el título y la fecha son obligatorios.',
  },
  'onboardTitle4': {
    'en': 'Swipe to act', 'tr': 'Hareket etmek için kaydırın', 'de': 'Wischen zum Handeln', 'fr': 'Glissez pour agir', 'es': 'Desliza para actuar',
  },
  'onboardBody4': {
    'en': "On any item: swipe right to resolve it, swipe left to snooze it a week. Long-press for edit, delete, and everything else.",
    'tr': 'Herhangi bir öğede: tamamlamak için sağa, bir hafta ertelemek için sola kaydırın. Düzenleme, silme ve diğer her şey için basılı tutun.',
    'de': 'Bei jedem Eintrag: nach rechts wischen, um ihn zu erledigen, nach links, um ihn eine Woche zu verschieben. Lange drücken für Bearbeiten, Löschen und mehr.',
    'fr': "Sur n'importe quel élément : glissez à droite pour le résoudre, à gauche pour le reporter d'une semaine. Appui long pour modifier, supprimer et le reste.",
    'es': 'En cualquier elemento: desliza a la derecha para resolverlo, a la izquierda para posponerlo una semana. Mantén pulsado para editar, eliminar y lo demás.',
  },
  'onboardTitle5': {
    'en': 'The bigger picture', 'tr': 'Büyük resim', 'de': 'Das große Ganze', 'fr': "La vue d'ensemble", 'es': 'El panorama completo',
  },
  'onboardBody5': {
    'en': "Timeline shows the next 12 months at a glance. Exposure adds up what it's all costing — and earning — you.",
    'tr': 'Zaman çizelgesi önümüzdeki 12 ayı bir bakışta gösterir. Maruziyet, bunların size ne kadara mal olduğunu — ve ne kazandırdığını — toplar.',
    'de': 'Die Zeitleiste zeigt die nächsten 12 Monate auf einen Blick. Exponierung summiert, was dich das alles kostet — und einbringt.',
    'fr': "La Chronologie affiche les 12 prochains mois en un coup d'œil. Exposition additionne ce que tout cela vous coûte — et vous rapporte.",
    'es': 'Cronología muestra los próximos 12 meses de un vistazo. Exposición suma lo que todo esto te cuesta, y lo que te reporta.',
  },

  // --- Capture sheet ---
  'captureAddTitle': {
    'en': 'Add an obligation', 'tr': 'Bir yükümlülük ekle', 'de': 'Verpflichtung hinzufügen', 'fr': 'Ajouter une obligation', 'es': 'Añadir una obligación',
  },
  'captureManualTitle': {
    'en': 'Enter manually', 'tr': 'Elle gir', 'de': 'Manuell eingeben', 'fr': 'Saisir manuellement', 'es': 'Introducir manualmente',
  },
  'captureManualSubtitle': {
    'en': 'Title and date — everything else is optional', 'tr': 'Başlık ve tarih — geri kalan her şey isteğe bağlı', 'de': 'Titel und Datum — alles andere ist optional', 'fr': 'Titre et date — tout le reste est facultatif', 'es': 'Título y fecha; todo lo demás es opcional',
  },
  'captureScanTitle': {
    'en': 'Scan a document', 'tr': 'Bir belge tara', 'de': 'Dokument scannen', 'fr': 'Scanner un document', 'es': 'Escanear un documento',
  },
  'captureScanSubtitle': {
    'en': 'Read on this device. Nothing is uploaded.', 'tr': 'Bu cihazda okunur. Hiçbir şey yüklenmez.', 'de': 'Wird auf diesem Gerät gelesen. Nichts wird hochgeladen.', 'fr': "Lu sur cet appareil. Rien n'est envoyé en ligne.", 'es': 'Se lee en este dispositivo. No se sube nada.',
  },
  'captureImportTitle': {
    'en': 'Import spreadsheet', 'tr': 'E-tablo içe aktar', 'de': 'Tabelle importieren', 'fr': 'Importer un tableur', 'es': 'Importar hoja de cálculo',
  },
  'captureImportSubtitle': {
    'en': 'Bring in a CSV of contracts or renewals at once', 'tr': 'Sözleşme veya yenilemelerinizi bir CSV ile toplu olarak ekleyin', 'de': 'Bringe eine CSV mit Verträgen oder Verlängerungen auf einmal ein', 'fr': "Importez d'un coup un CSV de contrats ou de renouvellements", 'es': 'Importa de una vez un CSV de contratos o renovaciones',
  },

  // --- Scan capture ---
  'scanPrompt': {
    'en': 'Photograph a contract, invoice, or renewal notice.', 'tr': 'Bir sözleşmenin, faturanın veya yenileme bildiriminin fotoğrafını çekin.', 'de': 'Fotografiere einen Vertrag, eine Rechnung oder eine Verlängerungsmitteilung.', 'fr': "Photographiez un contrat, une facture ou un avis de renouvellement.", 'es': 'Fotografía un contrato, una factura o un aviso de renovación.',
  },
  'scanErrorUnreadable': {
    'en': 'Could not read that document. Try a clearer photo, or add it manually.',
    'tr': 'Bu belge okunamadı. Daha net bir fotoğraf deneyin veya elle ekleyin.',
    'de': 'Dieses Dokument konnte nicht gelesen werden. Versuche ein klareres Foto oder füge es manuell hinzu.',
    'fr': 'Impossible de lire ce document. Essayez une photo plus nette ou ajoutez-le manuellement.',
    'es': 'No se pudo leer ese documento. Prueba con una foto más clara o añádelo manualmente.',
  },
  'scanErrorUnavailable': {
    'en': 'On-device extraction is not available on this device. You can still add it manually.',
    'tr': 'Cihaz üzerinde çıkarma bu cihazda kullanılamıyor. Yine de elle ekleyebilirsiniz.',
    'de': 'Die Extraktion auf dem Gerät ist auf diesem Gerät nicht verfügbar. Du kannst es trotzdem manuell hinzufügen.',
    'fr': "L'extraction sur l'appareil n'est pas disponible sur cet appareil. Vous pouvez toujours l'ajouter manuellement.",
    'es': 'La extracción en el dispositivo no está disponible en este dispositivo. Aun así puedes añadirlo manualmente.',
  },
  'scanErrorGeneric': {
    'en': 'Something went wrong reading that document.', 'tr': 'Bu belge okunurken bir sorun oluştu.', 'de': 'Beim Lesen dieses Dokuments ist ein Fehler aufgetreten.', 'fr': "Une erreur s'est produite lors de la lecture de ce document.", 'es': 'Se produjo un error al leer ese documento.',
  },
  'scanReading': {
    'en': 'Reading…', 'tr': 'Okunuyor…', 'de': 'Wird gelesen…', 'fr': 'Lecture…', 'es': 'Leyendo…',
  },
  'scanTakePhoto': {
    'en': 'Take photo', 'tr': 'Fotoğraf çek', 'de': 'Foto aufnehmen', 'fr': 'Prendre une photo', 'es': 'Tomar foto',
  },
  'scanChooseLibrary': {
    'en': 'Choose from library', 'tr': 'Kitaplıktan seç', 'de': 'Aus der Mediathek wählen', 'fr': 'Choisir dans la bibliothèque', 'es': 'Elegir de la galería',
  },

  // --- CSV import ---
  'csvPickIntro': {
    'en': 'Already keep a spreadsheet of contracts, renewals, or deadlines? Import it instead of typing everything by hand.',
    'tr': 'Zaten sözleşme, yenileme veya son tarihlerin bir tablosunu mu tutuyorsunuz? Her şeyi elle yazmak yerine içe aktarın.',
    'de': 'Führst du bereits eine Tabelle mit Verträgen, Verlängerungen oder Fristen? Importiere sie, statt alles von Hand einzutippen.',
    'fr': 'Vous tenez déjà un tableur de contrats, renouvellements ou échéances ? Importez-le au lieu de tout taper à la main.',
    'es': '¿Ya llevas una hoja de cálculo de contratos, renovaciones o plazos? Impórtala en lugar de escribirlo todo a mano.',
  },
  'csvPickHint': {
    'en': 'CSV only for now — export from Excel or Sheets as CSV first.',
    'tr': "Şimdilik yalnızca CSV — önce Excel veya Sheets'ten CSV olarak dışa aktarın.",
    'de': 'Vorerst nur CSV — exportiere zuerst aus Excel oder Sheets als CSV.',
    'fr': "CSV uniquement pour l'instant — exportez d'abord depuis Excel ou Sheets au format CSV.",
    'es': 'Por ahora solo CSV: exporta primero desde Excel o Sheets como CSV.',
  },
  'csvErrorRead': {
    'en': 'Could not read that file.', 'tr': 'Bu dosya okunamadı.', 'de': 'Diese Datei konnte nicht gelesen werden.', 'fr': 'Impossible de lire ce fichier.', 'es': 'No se pudo leer ese archivo.',
  },
  'csvErrorHeaderRow': {
    'en': 'That file needs a header row and at least one row of data.',
    'tr': 'Bu dosyada bir başlık satırı ve en az bir veri satırı olmalı.',
    'de': 'Diese Datei benötigt eine Kopfzeile und mindestens eine Datenzeile.',
    'fr': "Ce fichier a besoin d'une ligne d'en-tête et d'au moins une ligne de données.",
    'es': 'Ese archivo necesita una fila de encabezado y al menos una fila de datos.',
  },
  'csvErrorGeneric': {
    'en': 'Something went wrong reading that file.', 'tr': 'Bu dosya okunurken bir sorun oluştu.', 'de': 'Beim Lesen dieser Datei ist ein Fehler aufgetreten.', 'fr': "Une erreur s'est produite lors de la lecture de ce fichier.", 'es': 'Se produjo un error al leer ese archivo.',
  },
  'csvReading': {
    'en': 'Reading…', 'tr': 'Okunuyor…', 'de': 'Wird gelesen…', 'fr': 'Lecture…', 'es': 'Leyendo…',
  },
  'csvChooseFile': {
    'en': 'Choose a CSV file', 'tr': 'Bir CSV dosyası seç', 'de': 'CSV-Datei auswählen', 'fr': 'Choisir un fichier CSV', 'es': 'Elegir un archivo CSV',
  },
  'csvFileRowCountOne': {
    'en': '{file} — {count} row', 'tr': '{file} — {count} satır', 'de': '{file} — {count} Zeile', 'fr': '{file} — {count} ligne', 'es': '{file} — {count} fila',
  },
  'csvFileRowCountMany': {
    'en': '{file} — {count} rows', 'tr': '{file} — {count} satır', 'de': '{file} — {count} Zeilen', 'fr': '{file} — {count} lignes', 'es': '{file} — {count} filas',
  },
  'csvMatchColumns': {
    'en': 'Match each column to a field. Title and date are required — everything else is optional.',
    'tr': 'Her sütunu bir alanla eşleştirin. Başlık ve tarih zorunludur — geri kalan her şey isteğe bağlıdır.',
    'de': 'Ordne jede Spalte einem Feld zu. Titel und Datum sind erforderlich — alles andere ist optional.',
    'fr': 'Associez chaque colonne à un champ. Le titre et la date sont requis — tout le reste est facultatif.',
    'es': 'Asocia cada columna a un campo. El título y la fecha son obligatorios; todo lo demás es opcional.',
  },
  'csvFieldTitle': {
    'en': 'Title *', 'tr': 'Başlık *', 'de': 'Titel *', 'fr': 'Titre *', 'es': 'Título *',
  },
  'csvFieldDate': {
    'en': 'Expiry date *', 'tr': 'Bitiş tarihi *', 'de': 'Ablaufdatum *', 'fr': "Date d'expiration *", 'es': 'Fecha de vencimiento *',
  },
  'csvFieldCategory': {
    'en': 'Category', 'tr': 'Kategori', 'de': 'Kategorie', 'fr': 'Catégorie', 'es': 'Categoría',
  },
  'csvFieldCounterparty': {
    'en': 'Counterparty', 'tr': 'Karşı taraf', 'de': 'Vertragspartner', 'fr': 'Contrepartie', 'es': 'Contraparte',
  },
  'csvFieldNotice': {
    'en': 'Notice period (days)', 'tr': 'İhbar süresi (gün)', 'de': 'Kündigungsfrist (Tage)', 'fr': 'Préavis (jours)', 'es': 'Plazo de preaviso (días)',
  },
  'csvFieldValue': {
    'en': 'Value', 'tr': 'Tutar', 'de': 'Wert', 'fr': 'Valeur', 'es': 'Valor',
  },
  'csvFieldCurrency': {
    'en': 'Currency', 'tr': 'Para birimi', 'de': 'Währung', 'fr': 'Devise', 'es': 'Moneda',
  },
  'csvFieldAutoRenews': {
    'en': 'Renews automatically', 'tr': 'Otomatik yenilenir', 'de': 'Verlängert sich automatisch', 'fr': 'Se renouvelle automatiquement', 'es': 'Se renueva automáticamente',
  },
  'csvNoneOption': {
    'en': '— None —', 'tr': '— Yok —', 'de': '— Keine —', 'fr': '— Aucun —', 'es': '— Ninguno —',
  },
  'csvPreviewButton': {
    'en': 'Preview', 'tr': 'Önizle', 'de': 'Vorschau', 'fr': 'Aperçu', 'es': 'Vista previa',
  },
  'csvReadyToImport': {
    'en': '{count} ready to import', 'tr': '{count} içe aktarılmaya hazır', 'de': '{count} bereit zum Import', 'fr': '{count} prêt(s) à importer', 'es': '{count} listos para importar',
  },
  'csvReadyNeedAttention': {
    'en': '{ready} ready · {needAttention} need attention', 'tr': '{ready} hazır · {needAttention} tanesi dikkat gerektiriyor', 'de': '{ready} bereit · {needAttention} benötigen Aufmerksamkeit', 'fr': '{ready} prêt(s) · {needAttention} à vérifier', 'es': '{ready} listos · {needAttention} necesitan atención',
  },
  'csvEditMapping': {
    'en': 'Edit mapping', 'tr': 'Eşlemeyi düzenle', 'de': 'Zuordnung bearbeiten', 'fr': 'Modifier la correspondance', 'es': 'Editar la asignación',
  },
  'csvRowLabel': {
    'en': 'Row {n}', 'tr': 'Satır {n}', 'de': 'Zeile {n}', 'fr': 'Ligne {n}', 'es': 'Fila {n}',
  },
  'csvExpires': {
    'en': 'Expires {date}', 'tr': '{date} tarihinde sona eriyor', 'de': 'Läuft ab am {date}', 'fr': 'Expire le {date}', 'es': 'Vence el {date}',
  },
  'csvImporting': {
    'en': 'Importing…', 'tr': 'İçe aktarılıyor…', 'de': 'Wird importiert…', 'fr': 'Importation…', 'es': 'Importando…',
  },
  'csvImportButtonOne': {
    'en': 'Import {count} obligation', 'tr': '{count} yükümlülüğü içe aktar', 'de': '{count} Verpflichtung importieren', 'fr': 'Importer {count} obligation', 'es': 'Importar {count} obligación',
  },
  'csvImportButtonMany': {
    'en': 'Import {count} obligations', 'tr': '{count} yükümlülüğü içe aktar', 'de': '{count} Verpflichtungen importieren', 'fr': 'Importer {count} obligations', 'es': 'Importar {count} obligaciones',
  },

  // --- Search ---
  'searchHint': {
    'en': 'Search obligations', 'tr': 'Yükümlülüklerde ara', 'de': 'Verpflichtungen durchsuchen', 'fr': 'Rechercher des obligations', 'es': 'Buscar obligaciones',
  },
  'searchPrompt': {
    'en': 'Search by title, counterparty, notes, or category.', 'tr': 'Başlık, karşı taraf, not veya kategoriye göre arayın.', 'de': 'Suche nach Titel, Vertragspartner, Notizen oder Kategorie.', 'fr': 'Recherchez par titre, contrepartie, notes ou catégorie.', 'es': 'Busca por título, contraparte, notas o categoría.',
  },
  'searchNoResults': {
    'en': 'Nothing matches "{query}".', 'tr': '"{query}" ile eşleşen bir şey yok.', 'de': 'Nichts entspricht „{query}“.', 'fr': 'Rien ne correspond à « {query} ».', 'es': 'Nada coincide con "{query}".',
  },

  // --- Timeline ---
  'timelineTitle': {
    'en': 'Timeline', 'tr': 'Zaman çizelgesi', 'de': 'Zeitleiste', 'fr': 'Chronologie', 'es': 'Cronología',
  },
  'statThisWeek': {
    'en': 'THIS WEEK', 'tr': 'BU HAFTA', 'de': 'DIESE WOCHE', 'fr': 'CETTE SEMAINE', 'es': 'ESTA SEMANA',
  },
  'statThisMonth': {
    'en': 'THIS MONTH', 'tr': 'BU AY', 'de': 'DIESEN MONAT', 'fr': 'CE MOIS-CI', 'es': 'ESTE MES',
  },
  'statNothingCritical': {
    'en': 'nothing critical', 'tr': 'kritik yok', 'de': 'nichts Kritisches', 'fr': 'rien de critique', 'es': 'nada crítico',
  },
  'statNCritical': {
    'en': '{n} critical', 'tr': '{n} kritik', 'de': '{n} kritisch', 'fr': '{n} critique(s)', 'es': '{n} crítico(s)',
  },
  'netThisMonth': {
    'en': 'NET THIS MONTH', 'tr': 'BU AY NET', 'de': 'NETTO DIESEN MONAT', 'fr': 'NET CE MOIS-CI', 'es': 'NETO ESTE MES',
  },
  'netNothingValued': {
    'en': 'Nothing valued this month', 'tr': 'Bu ay değerlendirilmiş bir şey yok', 'de': 'Diesen Monat nichts Bewertetes', 'fr': 'Rien de chiffré ce mois-ci', 'es': 'Nada valorado este mes',
  },
  'netCaption': {
    'en': 'income minus what you owe, valued obligations only', 'tr': 'gelir eksi borcunuz, yalnızca tutarı girilmiş yükümlülükler', 'de': 'Einnahmen minus das, was du schuldest, nur bewertete Verpflichtungen', 'fr': 'revenus moins ce que vous devez, obligations chiffrées uniquement', 'es': 'ingresos menos lo que debes, solo obligaciones con valor',
  },
  'nothingDue': {
    'en': 'Nothing due', 'tr': 'Vadesi gelen yok', 'de': 'Nichts fällig', 'fr': 'Rien à échéance', 'es': 'Nada pendiente',
  },

  // --- Exposure ---
  'exposureTitle': {
    'en': 'Exposure', 'tr': 'Maruziyet', 'de': 'Exponierung', 'fr': 'Exposition', 'es': 'Exposición',
  },
  'exposureCommitted12mo': {
    'en': 'committed over the next 12 months', 'tr': 'önümüzdeki 12 ay boyunca taahhüt edilen', 'de': 'verpflichtet in den nächsten 12 Monaten', 'fr': 'engagé sur les 12 prochains mois', 'es': 'comprometido en los próximos 12 meses',
  },
  'exposureEntersWindow': {
    'en': '{amount} enters its action window this month', 'tr': '{amount} bu ay işlem penceresine giriyor', 'de': '{amount} tritt diesen Monat in sein Handlungsfenster ein', 'fr': "{amount} entre dans sa fenêtre d'action ce mois-ci", 'es': '{amount} entra en su ventana de acción este mes',
  },
  'exposureEmptyTitle': {
    'en': 'Nothing with a value on the horizon.', 'tr': 'Ufukta değeri olan bir şey yok.', 'de': 'Nichts mit einem Wert am Horizont.', 'fr': "Rien avec une valeur à l'horizon.", 'es': 'Nada con valor en el horizonte.',
  },
  'exposureEmptyBody': {
    'en': 'Add a value to an obligation and it will show up here as committed spend, forecast by month.',
    'tr': 'Bir yükümlülüğe tutar ekleyin, aya göre tahmin edilen taahhüt edilmiş harcama olarak burada görünsün.',
    'de': 'Füge einer Verpflichtung einen Wert hinzu, und sie erscheint hier als verpflichtete Ausgabe, nach Monat prognostiziert.',
    'fr': 'Ajoutez une valeur à une obligation et elle apparaîtra ici comme dépense engagée, prévue par mois.',
    'es': 'Añade un valor a una obligación y aparecerá aquí como gasto comprometido, previsto por mes.',
  },

  // --- Obligation form ---
  'formReviewDraft': {
    'en': 'Review draft', 'tr': 'Taslağı incele', 'de': 'Entwurf prüfen', 'fr': 'Vérifier le brouillon', 'es': 'Revisar borrador',
  },
  'formEditObligation': {
    'en': 'Edit obligation', 'tr': 'Yükümlülüğü düzenle', 'de': 'Verpflichtung bearbeiten', 'fr': "Modifier l'obligation", 'es': 'Editar obligación',
  },
  'formNewObligation': {
    'en': 'New obligation', 'tr': 'Yeni yükümlülük', 'de': 'Neue Verpflichtung', 'fr': 'Nouvelle obligation', 'es': 'Nueva obligación',
  },
  'formTitleField': {
    'en': 'Title', 'tr': 'Başlık', 'de': 'Titel', 'fr': 'Titre', 'es': 'Título',
  },
  'formExpiryDate': {
    'en': 'Expiry date', 'tr': 'Bitiş tarihi', 'de': 'Ablaufdatum', 'fr': "Date d'expiration", 'es': 'Fecha de vencimiento',
  },
  'formSelectDate': {
    'en': 'Select a date', 'tr': 'Bir tarih seçin', 'de': 'Datum auswählen', 'fr': 'Sélectionner une date', 'es': 'Selecciona una fecha',
  },
  'formCategory': {
    'en': 'Category', 'tr': 'Kategori', 'de': 'Kategorie', 'fr': 'Catégorie', 'es': 'Categoría',
  },
  'formCounterparty': {
    'en': 'Counterparty', 'tr': 'Karşı taraf', 'de': 'Vertragspartner', 'fr': 'Contrepartie', 'es': 'Contraparte',
  },
  'formNoticeDays': {
    'en': 'Notice period (days)', 'tr': 'İhbar süresi (gün)', 'de': 'Kündigungsfrist (Tage)', 'fr': 'Préavis (jours)', 'es': 'Plazo de preaviso (días)',
  },
  'formValue': {
    'en': 'Value ({currency})', 'tr': 'Tutar ({currency})', 'de': 'Wert ({currency})', 'fr': 'Valeur ({currency})', 'es': 'Valor ({currency})',
  },
  'formYouPay': {
    'en': 'You pay', 'tr': 'Siz ödüyorsunuz', 'de': 'Du zahlst', 'fr': 'Vous payez', 'es': 'Tú pagas',
  },
  'formYouReceive': {
    'en': 'You receive', 'tr': 'Siz alıyorsunuz', 'de': 'Du erhältst', 'fr': 'Vous recevez', 'es': 'Tú recibes',
  },
  'formRenewsAutomatically': {
    'en': 'Renews automatically', 'tr': 'Otomatik yenilenir', 'de': 'Verlängert sich automatisch', 'fr': 'Se renouvelle automatiquement', 'es': 'Se renueva automáticamente',
  },
  'formRoutine': {
    'en': 'Routine', 'tr': 'Rutin', 'de': 'Routine', 'fr': 'Routine', 'es': 'Rutina',
  },
  'formImportant': {
    'en': 'Important', 'tr': 'Önemli', 'de': 'Wichtig', 'fr': 'Important', 'es': 'Importante',
  },
  'formCritical': {
    'en': 'Critical', 'tr': 'Kritik', 'de': 'Kritisch', 'fr': 'Critique', 'es': 'Crítico',
  },
  'formMoreDetails': {
    'en': 'More details', 'tr': 'Daha fazla ayrıntı', 'de': 'Weitere Details', 'fr': 'Plus de détails', 'es': 'Más detalles',
  },
  'formRequired': {
    'en': 'Required', 'tr': 'Zorunlu', 'de': 'Erforderlich', 'fr': 'Requis', 'es': 'Obligatorio',
  },
  'formSaving': {
    'en': 'Saving…', 'tr': 'Kaydediliyor…', 'de': 'Wird gespeichert…', 'fr': 'Enregistrement…', 'es': 'Guardando…',
  },
  'formConfirmButton': {
    'en': 'Confirm', 'tr': 'Onayla', 'de': 'Bestätigen', 'fr': 'Confirmer', 'es': 'Confirmar',
  },
  'formSaveButton': {
    'en': 'Save', 'tr': 'Kaydet', 'de': 'Speichern', 'fr': 'Enregistrer', 'es': 'Guardar',
  },

  // --- Recurrence picker ---
  'recurrenceTitle': {
    'en': 'Renewal period', 'tr': 'Yenileme süresi', 'de': 'Verlängerungszeitraum', 'fr': 'Période de renouvellement', 'es': 'Periodo de renovación',
  },
  'recurrenceFrequencyLabel': {
    'en': 'Frequency', 'tr': 'Sıklık', 'de': 'Häufigkeit', 'fr': 'Fréquence', 'es': 'Frecuencia',
  },
  'recurrenceEvery': {
    'en': 'Every', 'tr': 'Her', 'de': 'Alle', 'fr': 'Tous les', 'es': 'Cada',
  },
  'recurrenceNextRenewal': {
    'en': 'Next renewal: {date}', 'tr': 'Sonraki yenileme: {date}', 'de': 'Nächste Verlängerung: {date}', 'fr': 'Prochain renouvellement : {date}', 'es': 'Próxima renovación: {date}',
  },
  'freq_weekly': {
    'en': 'Weekly', 'tr': 'Haftalık', 'de': 'Wöchentlich', 'fr': 'Hebdomadaire', 'es': 'Semanal',
  },
  'freq_monthly': {
    'en': 'Monthly', 'tr': 'Aylık', 'de': 'Monatlich', 'fr': 'Mensuel', 'es': 'Mensual',
  },
  'freq_quarterly': {
    'en': 'Quarterly', 'tr': '3 Aylık', 'de': 'Vierteljährlich', 'fr': 'Trimestriel', 'es': 'Trimestral',
  },
  'freq_annual': {
    'en': 'Annually', 'tr': 'Yıllık', 'de': 'Jährlich', 'fr': 'Annuel', 'es': 'Anual',
  },
  'freq_custom': {
    'en': 'Custom (days)', 'tr': 'Özel (gün)', 'de': 'Benutzerdefiniert (Tage)', 'fr': 'Personnalisé (jours)', 'es': 'Personalizado (días)',
  },
  'freq_daily': {
    'en': 'Daily', 'tr': 'Günlük', 'de': 'Täglich', 'fr': 'Quotidien', 'es': 'Diario',
  },
  'freq_none': {
    'en': 'None', 'tr': 'Yok', 'de': 'Keine', 'fr': 'Aucun', 'es': 'Ninguno',
  },
  'unit_weekly_one': {
    'en': 'week', 'tr': 'hafta', 'de': 'Woche', 'fr': 'semaine', 'es': 'semana',
  },
  'unit_weekly_many': {
    'en': 'weeks', 'tr': 'hafta', 'de': 'Wochen', 'fr': 'semaines', 'es': 'semanas',
  },
  'unit_monthly_one': {
    'en': 'month', 'tr': 'ay', 'de': 'Monat', 'fr': 'mois', 'es': 'mes',
  },
  'unit_monthly_many': {
    'en': 'months', 'tr': 'ay', 'de': 'Monate', 'fr': 'mois', 'es': 'meses',
  },
  'unit_quarterly_one': {
    'en': 'quarter', 'tr': 'çeyrek', 'de': 'Quartal', 'fr': 'trimestre', 'es': 'trimestre',
  },
  'unit_quarterly_many': {
    'en': 'quarters', 'tr': 'çeyrek', 'de': 'Quartale', 'fr': 'trimestres', 'es': 'trimestres',
  },
  'unit_annual_one': {
    'en': 'year', 'tr': 'yıl', 'de': 'Jahr', 'fr': 'an', 'es': 'año',
  },
  'unit_annual_many': {
    'en': 'years', 'tr': 'yıl', 'de': 'Jahre', 'fr': 'ans', 'es': 'años',
  },
  'unit_custom_one': {
    'en': 'day', 'tr': 'gün', 'de': 'Tag', 'fr': 'jour', 'es': 'día',
  },
  'unit_custom_many': {
    'en': 'days', 'tr': 'gün', 'de': 'Tage', 'fr': 'jours', 'es': 'días',
  },
  'unit_daily_one': {
    'en': 'day', 'tr': 'gün', 'de': 'Tag', 'fr': 'jour', 'es': 'día',
  },
  'unit_daily_many': {
    'en': 'days', 'tr': 'gün', 'de': 'Tage', 'fr': 'jours', 'es': 'días',
  },
  'unit_none_one': {
    'en': '', 'tr': '', 'de': '', 'fr': '', 'es': '',
  },
  'unit_none_many': {
    'en': '', 'tr': '', 'de': '', 'fr': '', 'es': '',
  },

  // --- Month calendar ---
  'navPreviousMonth': {
    'en': 'Previous month', 'tr': 'Önceki ay', 'de': 'Vorheriger Monat', 'fr': 'Mois précédent', 'es': 'Mes anterior',
  },
  'navNextMonth': {
    'en': 'Next month', 'tr': 'Sonraki ay', 'de': 'Nächster Monat', 'fr': 'Mois suivant', 'es': 'Mes siguiente',
  },
  'weekdayLetter0': {'en': 'M', 'tr': 'P', 'de': 'M', 'fr': 'L', 'es': 'L'},
  'weekdayLetter1': {'en': 'T', 'tr': 'S', 'de': 'D', 'fr': 'M', 'es': 'M'},
  'weekdayLetter2': {'en': 'W', 'tr': 'Ç', 'de': 'M', 'fr': 'M', 'es': 'X'},
  'weekdayLetter3': {'en': 'T', 'tr': 'P', 'de': 'D', 'fr': 'J', 'es': 'J'},
  'weekdayLetter4': {'en': 'F', 'tr': 'C', 'de': 'F', 'fr': 'V', 'es': 'V'},
  'weekdayLetter5': {'en': 'S', 'tr': 'C', 'de': 'S', 'fr': 'S', 'es': 'S'},
  'weekdayLetter6': {'en': 'S', 'tr': 'P', 'de': 'S', 'fr': 'D', 'es': 'D'},
  'weekdayFull0': {
    'en': 'Monday', 'tr': 'Pazartesi', 'de': 'Montag', 'fr': 'Lundi', 'es': 'Lunes',
  },
  'weekdayFull1': {
    'en': 'Tuesday', 'tr': 'Salı', 'de': 'Dienstag', 'fr': 'Mardi', 'es': 'Martes',
  },
  'weekdayFull2': {
    'en': 'Wednesday', 'tr': 'Çarşamba', 'de': 'Mittwoch', 'fr': 'Mercredi', 'es': 'Miércoles',
  },
  'weekdayFull3': {
    'en': 'Thursday', 'tr': 'Perşembe', 'de': 'Donnerstag', 'fr': 'Jeudi', 'es': 'Jueves',
  },
  'weekdayFull4': {
    'en': 'Friday', 'tr': 'Cuma', 'de': 'Freitag', 'fr': 'Vendredi', 'es': 'Viernes',
  },
  'weekdayFull5': {
    'en': 'Saturday', 'tr': 'Cumartesi', 'de': 'Samstag', 'fr': 'Samedi', 'es': 'Sábado',
  },
  'weekdayFull6': {
    'en': 'Sunday', 'tr': 'Pazar', 'de': 'Sonntag', 'fr': 'Dimanche', 'es': 'Domingo',
  },
  'dayCellToday': {
    'en': ', today', 'tr': ', bugün', 'de': ', heute', 'fr': ", aujourd'hui", 'es': ', hoy',
  },
  'dayCellNothingDue': {
    'en': 'nothing due', 'tr': 'vadesi gelen yok', 'de': 'nichts fällig', 'fr': 'rien à échéance', 'es': 'nada pendiente',
  },
  'dayCellOneDue': {
    'en': '1 obligation due', 'tr': '1 yükümlülüğün vadesi geldi', 'de': '1 Verpflichtung fällig', 'fr': '1 obligation à échéance', 'es': '1 obligación pendiente',
  },
  'dayCellNDue': {
    'en': '{count} obligations due', 'tr': '{count} yükümlülüğün vadesi geldi', 'de': '{count} Verpflichtungen fällig', 'fr': '{count} obligations à échéance', 'es': '{count} obligaciones pendientes',
  },

  // --- Obligation categories ---
  'cat_contract': {
    'en': 'Contract', 'tr': 'Sözleşme', 'de': 'Vertrag', 'fr': 'Contrat', 'es': 'Contrato',
  },
  'cat_subscription': {
    'en': 'Subscription', 'tr': 'Abonelik', 'de': 'Abonnement', 'fr': 'Abonnement', 'es': 'Suscripción',
  },
  'cat_payment': {
    'en': 'Payment', 'tr': 'Ödeme', 'de': 'Zahlung', 'fr': 'Paiement', 'es': 'Pago',
  },
  'cat_insurance': {
    'en': 'Insurance', 'tr': 'Sigorta', 'de': 'Versicherung', 'fr': 'Assurance', 'es': 'Seguro',
  },
  'cat_licence': {
    'en': 'Licence / permit', 'tr': 'Lisans / izin', 'de': 'Lizenz / Genehmigung', 'fr': 'Licence / permis', 'es': 'Licencia / permiso',
  },
  'cat_certification': {
    'en': 'Certification', 'tr': 'Sertifikasyon', 'de': 'Zertifizierung', 'fr': 'Certification', 'es': 'Certificación',
  },
  'cat_maintenance': {
    'en': 'Maintenance', 'tr': 'Bakım', 'de': 'Wartung', 'fr': 'Maintenance', 'es': 'Mantenimiento',
  },
  'cat_tax': {
    'en': 'Tax / filing', 'tr': 'Vergi / beyanname', 'de': 'Steuer / Erklärung', 'fr': 'Impôt / déclaration', 'es': 'Impuesto / declaración',
  },
  'cat_warranty': {
    'en': 'Warranty', 'tr': 'Garanti', 'de': 'Garantie', 'fr': 'Garantie', 'es': 'Garantía',
  },
  'cat_document': {
    'en': 'Document', 'tr': 'Belge', 'de': 'Dokument', 'fr': 'Document', 'es': 'Documento',
  },
  'cat_commitment': {
    'en': 'Meeting / commitment', 'tr': 'Toplantı / taahhüt', 'de': 'Termin / Verpflichtung', 'fr': 'Réunion / engagement', 'es': 'Reunión / compromiso',
  },
  'cat_other': {
    'en': 'Other', 'tr': 'Diğer', 'de': 'Sonstiges', 'fr': 'Autre', 'es': 'Otro',
  },
};
