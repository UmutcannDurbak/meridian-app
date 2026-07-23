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

  String get onboardingSkip => _t('onboardingSkip');
  String get onboardingNext => _t('onboardingNext');
  String get onboardingGetStarted => _t('onboardingGetStarted');

  String onboardTitle(int step) => _t('onboardTitle$step');
  String onboardBody(int step) => _t('onboardBody$step');
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
};
