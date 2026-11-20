// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String readerForFormat(String format) {
    return '$format-Lese-App';
  }

  @override
  String get builtInReader => 'Integrierte Lese-App';

  @override
  String get askEveryTime => 'Jedes Mal fragen';

  @override
  String get systemDefaultReader => 'Standard-App des Systems';

  @override
  String get readerSaveFailed =>
      'Die Lese-App konnte nicht gespeichert werden. Bitte erneut versuchen.';

  @override
  String get readerLoadFailed =>
      'Die Lese-App konnte nicht geladen werden. Zum Wiederholen tippen.';

  @override
  String get readerListFailed =>
      'Installierte Lese-Apps konnten nicht aufgelistet werden.';

  @override
  String get readerListLoading => 'Installierte Lese-Apps werden geladen…';

  @override
  String get readerOpenHint => 'Wird beim Tippen auf Öffnen verwendet.';

  @override
  String get readerLoading => 'Lese-App wird geladen…';

  @override
  String get readerUnavailable => 'Lese-App nicht verfügbar';

  @override
  String get readerOpenFailed =>
      'Die ausgewählte Lese-App konnte nicht geöffnet werden. Bitte in den Einstellungen eine andere wählen.';

  @override
  String get noDescriptionAvailable => 'Keine Beschreibung verfügbar';

  @override
  String get searchSource => 'Suchquelle';

  @override
  String get automaticSource => 'Automatisch (aktivierte Quellen)';

  @override
  String get appTitle => 'OpenlibExtended';

  @override
  String get navHome => 'Start';

  @override
  String get navSearch => 'Suche';

  @override
  String get navMyLibrary => 'Meine Bibliothek';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get add => 'Hinzufügen';

  @override
  String get delete => 'Löschen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get advancedSearch => 'Erweiterte Suche';

  @override
  String get author => 'Autor';

  @override
  String get publisher => 'Verlag';

  @override
  String get searchLibraryHint =>
      'Bibliothek durchsuchen (Titel, Autor, Verlag, Jahr)';

  @override
  String get newCollection => 'Neue Sammlung';

  @override
  String get noResultsFound => 'Keine Ergebnisse gefunden';

  @override
  String resultsFor(String query) {
    return 'Ergebnisse für \'$query\'';
  }

  @override
  String get followSystem => 'Dem System folgen';

  @override
  String get lightTheme => 'Helles Design';

  @override
  String get darkTheme => 'Dunkles Design';

  @override
  String get languageSetting => 'Sprache';

  @override
  String get systemLanguage => 'Systemstandard';

  @override
  String get enableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get notificationsExplanation =>
      'OpenlibExtended benötigt die Berechtigung für Benachrichtigungen, um den Download-Fortschritt im Hintergrund anzuzeigen. So behalten Sie Ihre Buch-Downloads auch im minimierten Zustand im Blick.';

  @override
  String get maybeLater => 'Vielleicht später';

  @override
  String get enable => 'Aktivieren';

  @override
  String get statusUnread => 'Ungelesen';

  @override
  String get statusInProgress => 'In Bearbeitung';

  @override
  String get statusCompleted => 'Fertig';

  @override
  String get collectionNameHint => 'z. B. Favoriten, Science-Fiction';

  @override
  String get manageCollectionsHint =>
      'Halten Sie ein Buch lange gedrückt, um seine Sammlungen zu verwalten';

  @override
  String get results => 'Ergebnisse';

  @override
  String get loading => 'Wird geladen...';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get about => 'Über';

  @override
  String get aboutDescription =>
      'Eine Open-Source-App zum Herunterladen und Lesen von Büchern aus Schattenbibliotheken (Anna\'s Archive).';

  @override
  String get aboutForkNote =>
      'Dies ist eine Fork-Version, gepflegt von warreth für den persönlichen Gebrauch und Community-Updates.';

  @override
  String get aboutOriginalNote =>
      'Original-App von dstark5 (https://github.com/dstark5/Openlib).';

  @override
  String get version => 'Version';

  @override
  String get github => 'Github';

  @override
  String get thisForkByWarreth => 'Dieser Fork (von warreth)';

  @override
  String get reportAnIssue => 'Problem melden';

  @override
  String get originalProject => 'Original-Projekt (von dstark5)';

  @override
  String get licence => 'Lizenz';

  @override
  String get gplLicense => 'GPL v3.0 Lizenz';

  @override
  String couldNotLaunch(String url) {
    return 'Konnte $url nicht öffnen';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get searchProvidersSection => 'Suchanbieter';

  @override
  String get libraryInstancesSection => 'Bibliothek & Instanzen';

  @override
  String get appearanceSection => 'Erscheinungsbild';

  @override
  String get generalSection => 'Allgemein';

  @override
  String get readerSection => 'Leser';

  @override
  String get advancedSection => 'Erweitert';

  @override
  String get backupSection => 'Sicherung';

  @override
  String get updatesSection => 'Updates';

  @override
  String get aboutSection => 'Über';

  @override
  String get archiveInstance => 'Archiv-Instanz';

  @override
  String get mirrorsAndProviders => 'Spiegel & Anbieter';

  @override
  String get fontSizeTitle => 'Schriftgröße';

  @override
  String scaleValue(String value) {
    return 'Skalierung: ${value}x';
  }

  @override
  String get preview => 'Vorschau';

  @override
  String get folderAccessTitle => 'Zugriff auf diesen Ordner erlauben?';

  @override
  String get folderAccessBody =>
      'Android erlaubt das Speichern in diesem Ordner nur mit \"Zugriff auf alle Dateien\". OpenlibExtended nutzt ihn nur, um Bücher im gewählten Ordner zu speichern, zu verschieben und zu finden.\n\nWenn du den aktuellen Ordner behältst, brauchst du ihn nicht. Bücher lassen sich weiterhin in anderen Lese-Apps öffnen.';

  @override
  String get folderAccessAllow => 'Erlauben';

  @override
  String get folderAccessKeep => 'Aktuellen Ordner behalten';

  @override
  String get folderAccessKeptCurrent =>
      'Kein Zugriff auf diesen Ordner. Die Bücher bleiben im aktuellen Ordner.';

  @override
  String get storageLocation => 'Speicherort';

  @override
  String get openPdfExternally => 'PDF extern öffnen';

  @override
  String get useDefaultPdfViewer => 'Standard-PDF-Viewer verwenden';

  @override
  String get openEpubExternally => 'EPUB extern öffnen';

  @override
  String get useDefaultEpubReader => 'Standard-EPUB-Reader verwenden';

  @override
  String get manualDownloadButton => 'Manuelle Download-Schaltfläche';

  @override
  String get einkMode => 'E-Ink-Modus';

  @override
  String get einkModeHint =>
      'Für E-Paper-Displays: keine Animationen, Welleneffekte oder Ladekreise, Scrollen stoppt mit dem Finger, seltenere Fortschrittsanzeigen';

  @override
  String get backgroundVerification => 'Verifizierung im Hintergrund';

  @override
  String get backgroundVerificationHint =>
      'Löst DDoS-Prüfungen unsichtbar. Auf manchen Geräten schlägt das fehl - ausschalten, um stattdessen in einem sichtbaren Fenster zu prüfen';

  @override
  String get backgroundVerificationFix =>
      'Falls die Verifizierung immer wieder fehlschlägt, deaktiviere \"Verifizierung im Hintergrund\" in den Einstellungen - manche Geräte können Prüfungen nicht unsichtbar lösen.';

  @override
  String get showManualDownloadHint =>
      'Schaltfläche zum manuellen Starten von Downloads anzeigen';

  @override
  String get donationKeyTitle => 'Anna\'s Archive Spende-Schlüssel';

  @override
  String get enterKeyForFasterDownloads =>
      'Schlüssel für schnellere Downloads eingeben';

  @override
  String get aboutOpenlib => 'Über OpenlibExtended';

  @override
  String get redoOnboarding => 'Onboarding wiederholen';

  @override
  String get resetAppSetup => 'App-Setup zurücksetzen und neu starten';

  @override
  String get exportLogs => 'Protokolle exportieren';

  @override
  String get shareDiagnosticLogs => 'Diagnoseprotokolle teilen (letzte 5 Min.)';

  @override
  String failedExportLogs(String error) {
    return 'Protokolle konnten nicht exportiert werden: $error';
  }

  @override
  String get donationKeyDialog => 'Spende-Schlüssel';

  @override
  String get enterYourKey => 'Schlüssel eingeben';

  @override
  String get instanceChanged => 'Instanz erfolgreich geändert';

  @override
  String rankingFailed(String error) {
    return 'Rangfolge fehlgeschlagen: $error';
  }

  @override
  String get autoRankInstances => 'Instanzen automatisch sortieren';

  @override
  String get sortBySpeedOnStartup =>
      'Beim Start automatisch nach Geschwindigkeit sortieren';

  @override
  String get rankInstancesNow => 'Instanzen jetzt sortieren';

  @override
  String onLatestVersion(String version) {
    return 'Sie nutzen die neueste Version ($version)';
  }

  @override
  String failedCheckUpdates(String error) {
    return 'Update-Prüfung fehlgeschlagen: $error';
  }

  @override
  String get includeBetaUpdates => 'Beta-Updates einbeziehen';

  @override
  String get getPreReleaseVersions => 'Vorabversionen erhalten';

  @override
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String get backupSaved => 'Sicherung gespeichert';

  @override
  String failedExportBackup(String error) {
    return 'Sicherung konnte nicht exportiert werden: $error';
  }

  @override
  String get backupRestored => 'Sicherung wiederhergestellt';

  @override
  String failedImportBackup(String error) {
    return 'Sicherung konnte nicht importiert werden: $error';
  }

  @override
  String get atLeastOneSource => 'Mindestens eine Suchquelle ist erforderlich';

  @override
  String rankedFastest(String name, String time) {
    return 'Sortiert! Schnellste: $name (${time}ms)';
  }

  @override
  String get rankingComplete => 'Sortierung abgeschlossen';

  @override
  String get providerSourceOriginal =>
      'Wird zuletzt durchsucht - durch DDoS-Guard geschützt';

  @override
  String get providerLibgenCatalog =>
      'Schnelle, direkte Downloads - wird zuerst durchsucht';

  @override
  String get providerZlibMirrors =>
      'Spiegel wechseln; Anmeldung kann nötig sein';

  @override
  String get themeTitle => 'Design';

  @override
  String get saveBackupTitle => 'Sicherung speichern';

  @override
  String get pickBackupFile => 'Sicherungsdatei auswählen';

  @override
  String get notABackup => 'Diese Datei ist keine OpenlibExtended-Sicherung';

  @override
  String get donationKeyHelper =>
      'Wird für schnellere Downloads auf Anna\'s Archive verwendet';

  @override
  String get mirrorsTestedRanked =>
      'Spiegel getestet und nach Geschwindigkeit sortiert';

  @override
  String testingFailed(String error) {
    return 'Test fehlgeschlagen: $error';
  }

  @override
  String get addCustomMirror => 'Benutzerdefinierten Spiegel hinzufügen';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameHint => 'z. B. Mein LibGen-Spiegel';

  @override
  String get serviceLabel => 'Dienst';

  @override
  String get urlLabel => 'URL';

  @override
  String get urlHint => 'https://example.com';

  @override
  String get pleaseFillAllFields => 'Bitte alle Felder ausfüllen';

  @override
  String get enterValidUrl =>
      'Bitte eine gültige URL mit http:// oder https:// eingeben';

  @override
  String get mirrorAdded => 'Spiegel erfolgreich hinzugefügt';

  @override
  String get deleteMirror => 'Spiegel löschen';

  @override
  String deleteMirrorConfirm(String name) {
    return 'Möchten Sie \"$name\" wirklich löschen?';
  }

  @override
  String get mirrorDeleted => 'Spiegel gelöscht';

  @override
  String get cannotDeleteDefaultMirrors =>
      'Standard-Spiegel können nicht gelöscht werden';

  @override
  String get manageMirrors => 'Spiegel verwalten';

  @override
  String get noMirrorsAvailable => 'Keine Spiegel verfügbar';

  @override
  String errorLabel(String error) {
    return 'Fehler: $error';
  }

  @override
  String get addMirror => 'Spiegel hinzufügen';

  @override
  String get testRankMirrors =>
      'Spiegel testen und nach Geschwindigkeit sortieren';

  @override
  String get unreachable => 'nicht erreichbar';

  @override
  String get open => 'Öffnen';

  @override
  String get unableToOpenFile => 'Datei konnte nicht geöffnet werden!';

  @override
  String get bookDeleted => 'Buch wurde gelöscht!';

  @override
  String get deleteBook => 'Buch löschen';

  @override
  String get deletePermanentWarning =>
      'Dies ist dauerhaft und kann nicht rückgängig gemacht werden';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get showBlockedContent => 'Gesperrten Seiteninhalt anzeigen';

  @override
  String get verifyInBrowser => 'Im Browser verifizieren';

  @override
  String get manualVerificationRequired =>
      'Manuelle Verifizierung erforderlich';

  @override
  String get systemBrowser => 'Systembrowser';

  @override
  String get embeddedBrowser => 'Eingebetteter Browser';

  @override
  String get unableToOpenVerification =>
      'Verifizierungsseite konnte nicht geöffnet werden – keine URL verfügbar';

  @override
  String get blockedPageContent => 'Gesperrter Seiteninhalt';

  @override
  String get copiedToClipboard => 'In die Zwischenablage kopiert';

  @override
  String get gotIt => 'Verstanden!';

  @override
  String get copy => 'Kopieren';

  @override
  String get tryUsingVpn => 'Versuchen Sie ein VPN';

  @override
  String get trending => 'Beliebt';

  @override
  String get genres => 'Genres';

  @override
  String get pauseDownload => 'Download anhalten';

  @override
  String get resumeDownload => 'Download fortsetzen';

  @override
  String get cancelDownload => 'Download abbrechen';

  @override
  String get noMirrors => 'Keine Spiegel verfügbar!';

  @override
  String get downloadLinksFailed =>
      'Download-Links konnten nicht geladen werden. Versuche es erneut oder wähle eine andere Quelle.';

  @override
  String get addToMyLibrary => 'Zu Meiner Bibliothek hinzufügen';

  @override
  String get downloadStartedBackground => 'Download im Hintergrund gestartet';

  @override
  String get bookDownloaded => 'Buch wurde heruntergeladen!';

  @override
  String get selectStorageToContinue =>
      'Bitte wählen Sie einen Speicherordner aus, um fortzufahren';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get next => 'Weiter';

  @override
  String get welcomeTitle => 'Willkommen bei OpenlibExtended';

  @override
  String get welcomeSubtitle =>
      'Ihr persönliches Tor zu einer Welt voller Wissen. Lassen Sie uns alles einrichten.';

  @override
  String get whereToStoreBooks => 'Wo sollen Ihre Bücher gespeichert werden?';

  @override
  String get noPathSelected => 'Kein Pfad ausgewählt';

  @override
  String get selectFolder => 'Ordner auswählen';

  @override
  String get storageScanNote =>
      'Wir durchsuchen diesen Ordner nur nach PDF-/EPUB-Dateien. Unterordner werden nicht eingescannt.';

  @override
  String get automaticUpdates => 'Automatische Updates';

  @override
  String get enableAutoUpdates => 'Auto-Updates aktivieren';

  @override
  String get autoUpdatesFdroidNote =>
      'Nicht empfohlen bei Installation über F-Droid (F-Droid verwaltet die Updates).';

  @override
  String get enableBetaUpdatesOnboarding => 'Beta-Updates aktivieren';

  @override
  String get betaUpdatesNote =>
      'Vorabversionen (Beta-Updates) erhalten, wenn verfügbar.';

  @override
  String get supportAnnasArchive => 'Anna\'s Archive unterstützen';

  @override
  String get donationPitch =>
      'Eine Spende an Anna\'s Archive ermöglicht schnellere Downloads und hilft, den Dienst für alle am Laufen zu halten. Sie können Ihren geheimen Schlüssel unten eingeben.';

  @override
  String get annasSecretKey => 'Geheimer Schlüssel von Anna\'s Archive';

  @override
  String get supportThisApp => 'Diese App unterstützen';

  @override
  String get sponsorPitch =>
      'Wenn Ihnen diese App gefällt, ziehen Sie in Betracht, die Entwicklung zu unterstützen. So kann ich mehr Zeit in die Verbesserung stecken!';

  @override
  String get sponsorOnGithub => 'Auf GitHub sponsern';

  @override
  String get stayUpdated => 'Auf dem Laufenden bleiben';

  @override
  String get notifyOnComplete =>
      'Benachrichtigung erhalten, wenn Downloads abgeschlossen sind.';

  @override
  String get chooseTheme => 'Design wählen';

  @override
  String get lightThemeShort => 'Hell';

  @override
  String get darkThemeShort => 'Dunkel';

  @override
  String get verifyingAccess => 'Zugriff wird verifiziert';

  @override
  String get done => 'Fertig';

  @override
  String get nothingToRead => 'Nichts auf dieser Seite zu lesen';

  @override
  String get noVoiceAvailable => 'Keine Stimme für das Vorlesen verfügbar';

  @override
  String get pauseReadingAloud => 'Vorlesen anhalten';

  @override
  String get resumeReadingAloud => 'Vorlesen';

  @override
  String get stopReadingAloud => 'Vorlesen beenden';

  @override
  String get speechSpeed => 'Sprechgeschwindigkeit';

  @override
  String get decreaseFontSize => 'Schriftgröße verkleinern';

  @override
  String get increaseFontSize => 'Schriftgröße vergrößern';

  @override
  String get close => 'Schließen';

  @override
  String get sortLibrary => 'Bibliothek sortieren';

  @override
  String get reloadHealthData => 'Gesundheitsdaten neu laden';

  @override
  String addServiceMirror(String title) {
    return '$title-Spiegel hinzufügen';
  }

  @override
  String get deleteMirrorTooltip => 'Spiegel löschen';

  @override
  String get ttsEngineMissing =>
      'Keine Sprachausgabe-Engine gefunden. Installiere eine (z.B. Sprachdienste) in den Systemeinstellungen.';

  @override
  String get previousPage => 'Vorherige Seite';

  @override
  String get nextPage => 'Nächste Seite';

  @override
  String searchingOn(String source) {
    return 'Ergebnisse von $source';
  }

  @override
  String get sourceLibgen => 'LibGen';

  @override
  String get sourceZlib => 'Z-Library';

  @override
  String get sourceAnnas => 'Anna\'s Archive';

  @override
  String downloadFrom(String source) {
    return 'Download von $source';
  }

  @override
  String get tryingNextSource =>
      'Keine Ergebnisse, nächste Quelle wird versucht…';

  @override
  String get slowMirrorsSkipped => 'Schnellere Spiegel werden verwendet';

  @override
  String whatsNewTitle(String version) {
    return 'Neu in $version';
  }

  @override
  String get whatsNewIntro =>
      'OpenlibExtended wurde aktualisiert. Das hat sich geändert.';

  @override
  String get whatsNewTabFeatures => 'Neue Funktionen';

  @override
  String get whatsNewTabSources => 'Quellen & Mirror';

  @override
  String get whatsNewProvidersHint =>
      'Dieses Release fügt neue Suchanbieter und Mirror hinzu. Aktualisiere deine Liste, um tote Mirror zu entfernen und die neuen hinzuzufügen; alle drei Suchanbieter werden aktiviert.';

  @override
  String get whatsNewUpdateInstances => 'Mirror-Liste aktualisieren';

  @override
  String get whatsNewInstancesUpdated => 'Mirror-Liste aktualisiert';

  @override
  String get whatsNewContinue => 'Weiter';

  @override
  String get whatsNewFeatureSpeed =>
      'Downloads starten schneller: keine Mirror-Prüfung mehr, schnelle Hosts zuerst, langsame IPFS-Gateways zuletzt.';

  @override
  String get whatsNewFeatureSourceLabels =>
      'Jedes Suchergebnis und jeder Download zeigt jetzt, aus welchem Katalog er stammt.';

  @override
  String get whatsNewFeatureCovers =>
      'Fehlende LibGen-Cover werden von der Detailseite des Buchs geladen.';

  @override
  String get volumeKeysTurnPages => 'Lautstärketasten blättern um';

  @override
  String get volumeKeysTurnPagesHint =>
      'In den eingebauten Readern blättert Leiser zur nächsten und Lauter zur vorherigen Seite. Im E-Ink-Modus standardmäßig an';

  @override
  String get loadMoreResults => 'Mehr laden';

  @override
  String get readerHelpTitle => 'Reader-Steuerung';

  @override
  String get readerHelpTapTitle => 'Ränder antippen';

  @override
  String get readerHelpTapBody =>
      'Rechten Rand antippen für die nächste Seite, linken Rand für die vorherige';

  @override
  String get readerHelpKeysTitle => 'Blättertasten';

  @override
  String get readerHelpKeysBody =>
      'Bild ab, Rechts, Runter oder Leertaste: nächste Seite. Bild auf, Links, Hoch oder Umschalt+Leertaste: vorherige Seite';

  @override
  String get readerHelpVolumeTitle => 'Lautstärketasten';

  @override
  String get readerHelpVolumeBody =>
      'Leiser: nächste Seite. Lauter: vorherige Seite';

  @override
  String get readerHelpTextSizeTitle => 'Textgröße';

  @override
  String get readerHelpTextSizeBody =>
      'Mit den Tasten für kleineren und größeren Text oben in der Leiste';

  @override
  String get readerHelpContentsTitle => 'Inhalt';

  @override
  String get readerHelpContentsBody =>
      'Vom rechten Rand hineinwischen für das Inhaltsverzeichnis';

  @override
  String get searchFieldHint => 'Suchen';

  @override
  String get searchSubmitTooltip => 'Suchen';

  @override
  String get searchClear => 'Suche löschen';

  @override
  String get searchFieldEmpty => 'Das Suchfeld ist leer';

  @override
  String get searchFilterType => 'Typ';

  @override
  String get searchFilterSort => 'Sortieren nach';

  @override
  String get searchFilterFileType => 'Dateityp';

  @override
  String get searchFilterLanguage => 'Sprache';

  @override
  String get searchFilterYear => 'Erscheinungsjahr';

  @override
  String get searchFileTypeSupported => 'Unterstützte Formate';

  @override
  String get searchFilterAll => 'Alle';

  @override
  String get searchTypeAnyBooks => 'Alle Bücher';

  @override
  String get searchTypeUnknownBooks => 'Unbekannte Bücher';

  @override
  String get searchTypeFiction => 'Belletristik';

  @override
  String get searchTypeNonFiction => 'Sachbücher';

  @override
  String get searchTypeComic => 'Comics';

  @override
  String get searchTypeMagazine => 'Zeitschrift';

  @override
  String get searchTypeStandardsDocument => 'Normdokument';

  @override
  String get searchTypeJournalArticle => 'Fachartikel';

  @override
  String get searchSortMostRelevant => 'Relevanteste';

  @override
  String get searchSortNewest => 'Neueste';

  @override
  String get searchSortOldest => 'Älteste';

  @override
  String get searchSortLargest => 'Größte';

  @override
  String get searchSortSmallest => 'Kleinste';

  @override
  String get searchYearBefore1980 => 'Vor 1980';

  @override
  String cardTitleByAuthor(String title, String author) {
    return '$title, von $author';
  }

  @override
  String cardSource(String source) {
    return 'Quelle: $source';
  }

  @override
  String get cardDownloadedBadge => 'Bereits heruntergeladen';

  @override
  String get errorWhatToDo => 'Was du tun kannst';

  @override
  String get errorVpnHint =>
      'Ein VPN kann helfen, regionale Sperren zu umgehen.';

  @override
  String get errorVerifyIntro =>
      'Die Website möchte prüfen, ob du ein Mensch bist. Wir öffnen ein Browserfenster, in dem du die Prüfung abschließen kannst.';

  @override
  String get errorVerifyReturnHint =>
      'Wenn du fertig bist, kehre zur App zurück und tippe auf „Erneut versuchen“.';

  @override
  String get errorNoContent => 'Kein Inhalt verfügbar';

  @override
  String errorTruncated(int count) {
    return '… (gekürzt, insgesamt $count Zeichen)';
  }

  @override
  String get errorNoInternetTitle => 'Du bist offline';

  @override
  String get errorNoInternetBody =>
      'Prüfe, ob WLAN oder mobile Daten aktiv sind und der Flugmodus aus ist, und versuche es erneut.';

  @override
  String get errorTimeoutTitle => 'Die Quelle hat zu lange gebraucht';

  @override
  String get errorTimeoutBody =>
      'Deine Verbindung ist eventuell langsam oder die Website überlastet. Versuche es gleich noch einmal oder wähle eine andere Quelle.';

  @override
  String get errorServerUnavailableTitle => 'Die Quelle antwortet nicht';

  @override
  String get errorServerUnavailableBody =>
      'Die Website ist eventuell gerade nicht erreichbar. Versuche es in ein paar Minuten erneut oder wähle in den Einstellungen einen anderen Mirror.';

  @override
  String get errorBlockedTitle =>
      'Die Website möchte prüfen, ob du ein Mensch bist';

  @override
  String get errorBlockedBody =>
      'Tippe auf „Im Browser verifizieren“, um die Prüfung zu bestehen, oder versuche es in ein paar Minuten erneut. Ein anderes Netzwerk oder ein VPN kann auch helfen.';

  @override
  String get errorForbiddenTitle => 'Zugriff verweigert';

  @override
  String get errorForbiddenBody =>
      'Die Website hat die Anfrage abgelehnt. Sie ist eventuell in deiner Region gesperrt; ein VPN oder ein anderer Mirror in den Einstellungen kann helfen.';

  @override
  String get errorRateLimitedTitle => 'Zu viele Anfragen';

  @override
  String get errorRateLimitedBody =>
      'Warte ein paar Minuten und versuche es dann erneut.';

  @override
  String get errorSslTitle => 'Sichere Verbindung fehlgeschlagen';

  @override
  String get errorSslBody =>
      'Dein Netzwerk blockiert eventuell sichere Verbindungen. Versuche ein anderes Netzwerk oder ein VPN.';

  @override
  String get errorDnsTitle => 'Server nicht gefunden';

  @override
  String get errorDnsBody =>
      'Dein Netzwerk oder Anbieter sperrt die Website eventuell. Versuche DNS 1.1.1.1, ein VPN oder ein anderes Netzwerk.';

  @override
  String get errorUnknownTitle => 'Etwas ist schiefgelaufen';

  @override
  String get errorUnknownBody =>
      'Versuche es erneut oder wähle eine andere Quelle.';

  @override
  String get errorSourcesFailedTitle => 'Keine Quelle hat geantwortet';

  @override
  String errorSourcesFailedBody(String sources) {
    return '$sources hat nicht geantwortet. Die Quellen sind eventuell ausgefallen oder in deinem Netzwerk gesperrt. Versuche es erneut, mit einem anderen Netzwerk oder einem VPN.';
  }

  @override
  String resultsSourcesDidNotRespond(String sources) {
    return '$sources hat nicht geantwortet';
  }

  @override
  String resultsNoMatchesSourcesDown(String sources) {
    return '$sources hat nicht geantwortet, daher wurden nicht alle Quellen durchsucht.';
  }

  @override
  String get resultsNoMatchesHint =>
      'Prüfe die Schreibweise, verwende weniger Wörter oder durchsuche eine andere Quelle.';

  @override
  String get resultsClearFilters => 'Filter zurücksetzen';

  @override
  String get resultsTryAnotherSource => 'Andere Quelle versuchen';

  @override
  String get resultsEditSearch => 'Suche bearbeiten';

  @override
  String resultsEndOfList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ende der Ergebnisse · $count Bücher',
      one: 'Ende der Ergebnisse · 1 Buch',
    );
    return '$_temp0';
  }

  @override
  String get resultsActiveFilters => 'Aktive Filter';

  @override
  String resultsFilterChip(String label, String value) {
    return '$label: $value';
  }

  @override
  String get resultsRemoveFilter => 'Filter entfernen';

  @override
  String resultsFiltersIgnored(int count, String filters, String source) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$filters werden von $source nicht unterstützt, die Ergebnisse sind danach nicht gefiltert.',
      one:
          '$filters wird von $source nicht unterstützt, die Ergebnisse sind danach nicht gefiltert.',
    );
    return '$_temp0';
  }

  @override
  String get resultsSortedWithinPage =>
      'Innerhalb jeder Ergebnisseite sortiert';
}
