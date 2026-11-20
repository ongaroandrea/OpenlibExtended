// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String readerForFormat(String format) {
    return 'Lecteur $format';
  }

  @override
  String get builtInReader => 'Lecteur intégré';

  @override
  String get askEveryTime => 'Toujours demander';

  @override
  String get systemDefaultReader => 'Application par défaut du système';

  @override
  String get readerSaveFailed =>
      'Impossible d’enregistrer le lecteur. Réessayez.';

  @override
  String get readerLoadFailed =>
      'Impossible de charger le lecteur. Appuyez pour réessayer.';

  @override
  String get readerListFailed => 'Impossible de lister les lecteurs installés.';

  @override
  String get readerListLoading => 'Chargement des lecteurs installés…';

  @override
  String get readerOpenHint => 'Utilisé lorsque vous appuyez sur Ouvrir.';

  @override
  String get readerLoading => 'Chargement du lecteur…';

  @override
  String get readerUnavailable => 'Lecteur indisponible';

  @override
  String get readerOpenFailed =>
      'Impossible d’ouvrir le lecteur sélectionné. Choisissez-en un autre dans les paramètres.';

  @override
  String get noDescriptionAvailable => 'Aucune description disponible';

  @override
  String get searchSource => 'Source de recherche';

  @override
  String get automaticSource => 'Automatique (sources activées)';

  @override
  String get appTitle => 'OpenlibExtended';

  @override
  String get navHome => 'Accueil';

  @override
  String get navSearch => 'Rechercher';

  @override
  String get navMyLibrary => 'Ma bibliothèque';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get add => 'Ajouter';

  @override
  String get delete => 'Supprimer';

  @override
  String get retry => 'Réessayer';

  @override
  String get advancedSearch => 'Recherche avancée';

  @override
  String get author => 'Auteur';

  @override
  String get publisher => 'Éditeur';

  @override
  String get searchLibraryHint =>
      'Rechercher dans la bibliothèque (titre, auteur, éditeur, année)';

  @override
  String get newCollection => 'Nouvelle collection';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String resultsFor(String query) {
    return 'Résultats pour « $query »';
  }

  @override
  String get followSystem => 'Suivre le système';

  @override
  String get lightTheme => 'Thème clair';

  @override
  String get darkTheme => 'Thème sombre';

  @override
  String get languageSetting => 'Langue';

  @override
  String get systemLanguage => 'Langue du système';

  @override
  String get enableNotifications => 'Activer les notifications';

  @override
  String get notificationsExplanation =>
      'OpenlibExtended a besoin de l\'autorisation de notification pour afficher la progression des téléchargements en arrière-plan. Vous pouvez ainsi suivre vos téléchargements de livres même lorsque l\'application est réduite.';

  @override
  String get maybeLater => 'Peut-être plus tard';

  @override
  String get enable => 'Activer';

  @override
  String get statusUnread => 'Non lu';

  @override
  String get statusInProgress => 'En cours';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get collectionNameHint => 'ex. Favoris, Science-fiction';

  @override
  String get manageCollectionsHint =>
      'Appuyez longuement sur un livre pour gérer ses collections';

  @override
  String get results => 'Résultats';

  @override
  String get loading => 'Chargement...';

  @override
  String get unknown => 'Inconnu';

  @override
  String get about => 'À propos';

  @override
  String get aboutDescription =>
      'Une application open source pour télécharger et lire des livres de bibliothèques parallèles (Anna\'s Archive).';

  @override
  String get aboutForkNote =>
      'Version forkée maintenue par warreth pour un usage personnel et des mises à jour communautaires.';

  @override
  String get aboutOriginalNote =>
      'Application originale de dstark5 (https://github.com/dstark5/Openlib).';

  @override
  String get version => 'Version';

  @override
  String get github => 'Github';

  @override
  String get thisForkByWarreth => 'Ce fork (par warreth)';

  @override
  String get reportAnIssue => 'Signaler un problème';

  @override
  String get originalProject => 'Projet original (par dstark5)';

  @override
  String get licence => 'Licence';

  @override
  String get gplLicense => 'Licence GPL v3.0';

  @override
  String couldNotLaunch(String url) {
    return 'Impossible d\'ouvrir $url';
  }

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get searchProvidersSection => 'Sources de recherche';

  @override
  String get libraryInstancesSection => 'Bibliothèque et instances';

  @override
  String get appearanceSection => 'Apparence';

  @override
  String get generalSection => 'Général';

  @override
  String get readerSection => 'Lecteur';

  @override
  String get advancedSection => 'Avancé';

  @override
  String get backupSection => 'Sauvegarde';

  @override
  String get updatesSection => 'Mises à jour';

  @override
  String get aboutSection => 'À propos';

  @override
  String get archiveInstance => 'Instance d\'archive';

  @override
  String get mirrorsAndProviders => 'Miroirs et sources';

  @override
  String get fontSizeTitle => 'Taille de police';

  @override
  String scaleValue(String value) {
    return 'Échelle : ${value}x';
  }

  @override
  String get preview => 'Aperçu';

  @override
  String get folderAccessTitle => 'Autoriser l\'accès à ce dossier ?';

  @override
  String get folderAccessBody =>
      'Android n\'autorise l\'enregistrement dans ce dossier qu\'avec « Accès à tous les fichiers ». OpenlibExtended l\'utilise uniquement pour enregistrer, déplacer et retrouver les livres dans le dossier choisi.\n\nVous n\'en avez pas besoin si vous gardez le dossier actuel. Les livres s\'ouvrent toujours dans les autres applis de lecture.';

  @override
  String get folderAccessAllow => 'Autoriser';

  @override
  String get folderAccessKeep => 'Garder le dossier actuel';

  @override
  String get folderAccessKeptCurrent =>
      'Pas d\'accès à ce dossier. Les livres restent dans le dossier actuel.';

  @override
  String get storageLocation => 'Emplacement de stockage';

  @override
  String get openPdfExternally => 'Ouvrir les PDF à l\'extérieur';

  @override
  String get useDefaultPdfViewer => 'Utiliser votre lecteur PDF par défaut';

  @override
  String get openEpubExternally => 'Ouvrir les EPUB à l\'extérieur';

  @override
  String get useDefaultEpubReader => 'Utiliser votre lecteur EPUB par défaut';

  @override
  String get manualDownloadButton => 'Bouton de téléchargement manuel';

  @override
  String get einkMode => 'Mode e-ink';

  @override
  String get einkModeHint =>
      'Pour les écrans à encre électronique : pas d\'animations, d\'ondulations ni d\'indicateurs rotatifs, le défilement s\'arrête avec le doigt, moins de mises à jour de progression';

  @override
  String get backgroundVerification => 'Vérifier en arrière-plan';

  @override
  String get backgroundVerificationHint =>
      'Résout les vérifications DDoS de façon invisible. Échoue sur certains appareils - désactivez-le pour vérifier dans une fenêtre visible';

  @override
  String get backgroundVerificationFix =>
      'Si la vérification échoue sans arrêt, désactivez « Vérifier en arrière-plan » dans les paramètres - certains appareils ne peuvent pas résoudre les vérifications de façon invisible.';

  @override
  String get showManualDownloadHint =>
      'Afficher le bouton pour lancer les téléchargements manuellement';

  @override
  String get donationKeyTitle => 'Clé de don Anna\'s Archive';

  @override
  String get enterKeyForFasterDownloads =>
      'Saisissez la clé pour des téléchargements plus rapides';

  @override
  String get aboutOpenlib => 'À propos d\'OpenlibExtended';

  @override
  String get redoOnboarding => 'Refaire l\'introduction';

  @override
  String get resetAppSetup => 'Réinitialiser la configuration et recommencer';

  @override
  String get exportLogs => 'Exporter les journaux';

  @override
  String get shareDiagnosticLogs =>
      'Partager les journaux de diagnostic (5 dernières min.)';

  @override
  String failedExportLogs(String error) {
    return 'Échec de l\'export des journaux : $error';
  }

  @override
  String get donationKeyDialog => 'Clé de don';

  @override
  String get enterYourKey => 'Saisissez votre clé';

  @override
  String get instanceChanged => 'Instance modifiée avec succès';

  @override
  String rankingFailed(String error) {
    return 'Échec du classement : $error';
  }

  @override
  String get autoRankInstances => 'Classement automatique des instances';

  @override
  String get sortBySpeedOnStartup =>
      'Trier automatiquement par vitesse au démarrage';

  @override
  String get rankInstancesNow => 'Classer les instances maintenant';

  @override
  String onLatestVersion(String version) {
    return 'Vous utilisez la dernière version ($version)';
  }

  @override
  String failedCheckUpdates(String error) {
    return 'Échec de la vérification des mises à jour : $error';
  }

  @override
  String get includeBetaUpdates => 'Inclure les versions bêta';

  @override
  String get getPreReleaseVersions => 'Recevoir les préversions';

  @override
  String get checkForUpdates => 'Vérifier les mises à jour';

  @override
  String get backupSaved => 'Sauvegarde enregistrée';

  @override
  String failedExportBackup(String error) {
    return 'Échec de l\'export de la sauvegarde : $error';
  }

  @override
  String get backupRestored => 'Sauvegarde restaurée';

  @override
  String failedImportBackup(String error) {
    return 'Échec de l\'import de la sauvegarde : $error';
  }

  @override
  String get atLeastOneSource =>
      'Au moins une source de recherche est nécessaire';

  @override
  String rankedFastest(String name, String time) {
    return 'Classé ! Plus rapide : $name (${time}ms)';
  }

  @override
  String get rankingComplete => 'Classement terminé';

  @override
  String get providerSourceOriginal =>
      'Recherché en dernier - protégé par DDoS-Guard';

  @override
  String get providerLibgenCatalog =>
      'Téléchargements rapides et directs - recherché en premier';

  @override
  String get providerZlibMirrors =>
      'Les miroirs tournent ; connexion parfois requise';

  @override
  String get themeTitle => 'Thème';

  @override
  String get saveBackupTitle => 'Enregistrer la sauvegarde';

  @override
  String get pickBackupFile => 'Choisir un fichier de sauvegarde';

  @override
  String get notABackup =>
      'Ce fichier n\'est pas une sauvegarde OpenlibExtended';

  @override
  String get donationKeyHelper =>
      'Utilisée pour des téléchargements plus rapides sur Anna\'s Archive';

  @override
  String get mirrorsTestedRanked => 'Miroirs testés et classés par vitesse';

  @override
  String testingFailed(String error) {
    return 'Échec du test : $error';
  }

  @override
  String get addCustomMirror => 'Ajouter un miroir personnalisé';

  @override
  String get nameLabel => 'Nom';

  @override
  String get nameHint => 'ex. Mon miroir LibGen';

  @override
  String get serviceLabel => 'Service';

  @override
  String get urlLabel => 'URL';

  @override
  String get urlHint => 'https://example.com';

  @override
  String get pleaseFillAllFields => 'Veuillez remplir tous les champs';

  @override
  String get enterValidUrl =>
      'Veuillez saisir une URL valide avec http:// ou https://';

  @override
  String get mirrorAdded => 'Miroir ajouté avec succès';

  @override
  String get deleteMirror => 'Supprimer le miroir';

  @override
  String deleteMirrorConfirm(String name) {
    return 'Voulez-vous vraiment supprimer « $name » ?';
  }

  @override
  String get mirrorDeleted => 'Miroir supprimé';

  @override
  String get cannotDeleteDefaultMirrors =>
      'Impossible de supprimer les miroirs par défaut';

  @override
  String get manageMirrors => 'Gérer les miroirs';

  @override
  String get noMirrorsAvailable => 'Aucun miroir disponible';

  @override
  String errorLabel(String error) {
    return 'Erreur : $error';
  }

  @override
  String get addMirror => 'Ajouter un miroir';

  @override
  String get testRankMirrors => 'Tester et classer les miroirs par vitesse';

  @override
  String get unreachable => 'inaccessible';

  @override
  String get open => 'Ouvrir';

  @override
  String get unableToOpenFile => 'Impossible d\'ouvrir le fichier !';

  @override
  String get bookDeleted => 'Livre supprimé !';

  @override
  String get deleteBook => 'Supprimer le livre';

  @override
  String get deletePermanentWarning =>
      'Cette action est définitive et ne peut pas être annulée';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get showBlockedContent => 'Afficher le contenu de la page bloquée';

  @override
  String get verifyInBrowser => 'Vérifier dans le navigateur';

  @override
  String get manualVerificationRequired => 'Vérification manuelle requise';

  @override
  String get systemBrowser => 'Navigateur système';

  @override
  String get embeddedBrowser => 'Navigateur intégré';

  @override
  String get unableToOpenVerification =>
      'Impossible d\'ouvrir la page de vérification - aucune URL disponible';

  @override
  String get blockedPageContent => 'Contenu de la page bloquée';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get gotIt => 'Compris !';

  @override
  String get copy => 'Copier';

  @override
  String get tryUsingVpn => 'Essayez d\'utiliser un VPN';

  @override
  String get trending => 'Tendances';

  @override
  String get genres => 'Genres';

  @override
  String get pauseDownload => 'Mettre le téléchargement en pause';

  @override
  String get resumeDownload => 'Reprendre le téléchargement';

  @override
  String get cancelDownload => 'Annuler le téléchargement';

  @override
  String get noMirrors => 'Aucun miroir disponible !';

  @override
  String get downloadLinksFailed =>
      'Impossible de récupérer les liens de téléchargement. Réessayez ou choisissez une autre source.';

  @override
  String get addToMyLibrary => 'Ajouter à ma bibliothèque';

  @override
  String get downloadStartedBackground =>
      'Téléchargement lancé en arrière-plan';

  @override
  String get bookDownloaded => 'Livre téléchargé !';

  @override
  String get selectStorageToContinue =>
      'Veuillez sélectionner un dossier de stockage pour continuer';

  @override
  String get getStarted => 'Commencer';

  @override
  String get next => 'Suivant';

  @override
  String get welcomeTitle => 'Bienvenue sur OpenlibExtended';

  @override
  String get welcomeSubtitle =>
      'Votre porte d\'entrée personnelle vers un monde de connaissances. Préparons tout.';

  @override
  String get whereToStoreBooks => 'Où devons-nous stocker vos livres ?';

  @override
  String get noPathSelected => 'Aucun chemin sélectionné';

  @override
  String get selectFolder => 'Choisir un dossier';

  @override
  String get storageScanNote =>
      'Nous ne chercherons que des fichiers PDF/EPUB dans ce dossier. Aucun scan récursif des sous-dossiers.';

  @override
  String get automaticUpdates => 'Mises à jour automatiques';

  @override
  String get enableAutoUpdates => 'Activer les mises à jour automatiques';

  @override
  String get autoUpdatesFdroidNote =>
      'Déconseillé si vous avez installé via F-Droid (F-Droid gère les mises à jour).';

  @override
  String get enableBetaUpdatesOnboarding => 'Activer les versions bêta';

  @override
  String get betaUpdatesNote =>
      'Recevoir les préversions (bêta) quand elles sont disponibles.';

  @override
  String get supportAnnasArchive => 'Soutenir Anna\'s Archive';

  @override
  String get donationPitch =>
      'Faire un don à Anna\'s Archive permet des téléchargements plus rapides et les aide à maintenir le service pour tous. Vous pouvez saisir votre clé secrète ci-dessous.';

  @override
  String get annasSecretKey => 'Clé secrète Anna\'s Archive';

  @override
  String get supportThisApp => 'Soutenir cette application';

  @override
  String get sponsorPitch =>
      'Si vous aimez cette application, pensez à soutenir son développement. Cela m\'aide à y consacrer plus de temps !';

  @override
  String get sponsorOnGithub => 'Sponsoriser sur GitHub';

  @override
  String get stayUpdated => 'Rester informé';

  @override
  String get notifyOnComplete =>
      'Être notifié lorsque les téléchargements se terminent.';

  @override
  String get chooseTheme => 'Choisir un thème';

  @override
  String get lightThemeShort => 'Clair';

  @override
  String get darkThemeShort => 'Sombre';

  @override
  String get verifyingAccess => 'Vérification de l\'accès';

  @override
  String get done => 'Terminé';

  @override
  String get nothingToRead => 'Rien à lire sur cette page';

  @override
  String get noVoiceAvailable =>
      'Aucune voix disponible pour la lecture à voix haute';

  @override
  String get pauseReadingAloud => 'Mettre la lecture en pause';

  @override
  String get resumeReadingAloud => 'Lire à voix haute';

  @override
  String get stopReadingAloud => 'Arrêter la lecture';

  @override
  String get speechSpeed => 'Vitesse de la voix';

  @override
  String get decreaseFontSize => 'Réduire la taille de police';

  @override
  String get increaseFontSize => 'Augmenter la taille de police';

  @override
  String get close => 'Fermer';

  @override
  String get sortLibrary => 'Trier la bibliothèque';

  @override
  String get reloadHealthData => 'Recharger les données de santé';

  @override
  String addServiceMirror(String title) {
    return 'Ajouter un miroir $title';
  }

  @override
  String get deleteMirrorTooltip => 'Supprimer le miroir';

  @override
  String get ttsEngineMissing =>
      'Aucun moteur de synthèse vocale trouvé. Installez-en un (ex. Services vocaux) dans les paramètres système.';

  @override
  String get previousPage => 'Page précédente';

  @override
  String get nextPage => 'Page suivante';

  @override
  String searchingOn(String source) {
    return 'Résultats de $source';
  }

  @override
  String get sourceLibgen => 'LibGen';

  @override
  String get sourceZlib => 'Z-Library';

  @override
  String get sourceAnnas => 'Anna\'s Archive';

  @override
  String downloadFrom(String source) {
    return 'Téléchargement depuis $source';
  }

  @override
  String get tryingNextSource =>
      'Aucun résultat ici, essai de la source suivante…';

  @override
  String get slowMirrorsSkipped => 'Utilisation de miroirs plus rapides';

  @override
  String whatsNewTitle(String version) {
    return 'Nouveautés de $version';
  }

  @override
  String get whatsNewIntro =>
      'OpenlibExtended a été mis à jour. Voici ce qui a changé.';

  @override
  String get whatsNewTabFeatures => 'Nouvelles fonctionnalités';

  @override
  String get whatsNewTabSources => 'Sources et miroirs';

  @override
  String get whatsNewProvidersHint =>
      'Cette version ajoute de nouveaux fournisseurs de recherche et de nouveaux miroirs. Mettez à jour votre liste pour supprimer les miroirs morts et ajouter les nouveaux ; les trois fournisseurs seront activés.';

  @override
  String get whatsNewUpdateInstances => 'Mettre à jour la liste des miroirs';

  @override
  String get whatsNewInstancesUpdated => 'Liste des miroirs mise à jour';

  @override
  String get whatsNewContinue => 'Continuer';

  @override
  String get whatsNewFeatureSpeed =>
      'Les téléchargements démarrent plus vite : plus de sondage des miroirs, serveurs rapides d\'abord, passerelles IPFS lentes en dernier.';

  @override
  String get whatsNewFeatureSourceLabels =>
      'Chaque résultat de recherche et chaque téléchargement indique maintenant son catalogue d\'origine.';

  @override
  String get whatsNewFeatureCovers =>
      'Les couvertures LibGen manquantes sont récupérées depuis la page détaillée du livre.';

  @override
  String get volumeKeysTurnPages => 'Les touches de volume tournent les pages';

  @override
  String get volumeKeysTurnPagesHint =>
      'Dans les lecteurs intégrés, volume bas passe à la page suivante et volume haut à la précédente. Activé par défaut en mode E-ink';

  @override
  String get loadMoreResults => 'Charger plus';

  @override
  String get readerHelpTitle => 'Commandes du lecteur';

  @override
  String get readerHelpTapTitle => 'Touchez les bords';

  @override
  String get readerHelpTapBody =>
      'Touchez le bord droit pour la page suivante, le bord gauche pour la précédente';

  @override
  String get readerHelpKeysTitle => 'Touches de page';

  @override
  String get readerHelpKeysBody =>
      'Page suiv., Droite, Bas ou Espace : page suivante. Page préc., Gauche, Haut ou Maj+Espace : page précédente';

  @override
  String get readerHelpVolumeTitle => 'Touches de volume';

  @override
  String get readerHelpVolumeBody =>
      'Volume bas : page suivante. Volume haut : page précédente';

  @override
  String get readerHelpTextSizeTitle => 'Taille du texte';

  @override
  String get readerHelpTextSizeBody =>
      'Utilisez les boutons de texte plus petit et plus grand dans la barre du haut';

  @override
  String get readerHelpContentsTitle => 'Sommaire';

  @override
  String get readerHelpContentsBody =>
      'Balayez depuis le bord droit pour afficher la table des matières';

  @override
  String get searchFieldHint => 'Rechercher';

  @override
  String get searchSubmitTooltip => 'Rechercher';

  @override
  String get searchClear => 'Effacer la recherche';

  @override
  String get searchFieldEmpty => 'Le champ de recherche est vide';

  @override
  String get searchFilterType => 'Type';

  @override
  String get searchFilterSort => 'Trier par';

  @override
  String get searchFilterFileType => 'Type de fichier';

  @override
  String get searchFilterLanguage => 'Langue';

  @override
  String get searchFilterYear => 'Année de publication';

  @override
  String get searchFileTypeSupported => 'Formats pris en charge';

  @override
  String get searchFilterAll => 'Tous';

  @override
  String get searchTypeAnyBooks => 'Tous les livres';

  @override
  String get searchTypeUnknownBooks => 'Livres inconnus';

  @override
  String get searchTypeFiction => 'Fiction';

  @override
  String get searchTypeNonFiction => 'Non-fiction';

  @override
  String get searchTypeComic => 'Bandes dessinées';

  @override
  String get searchTypeMagazine => 'Magazine';

  @override
  String get searchTypeStandardsDocument => 'Document normatif';

  @override
  String get searchTypeJournalArticle => 'Article de revue';

  @override
  String get searchSortMostRelevant => 'Plus pertinents';

  @override
  String get searchSortNewest => 'Plus récents';

  @override
  String get searchSortOldest => 'Plus anciens';

  @override
  String get searchSortLargest => 'Plus volumineux';

  @override
  String get searchSortSmallest => 'Plus légers';

  @override
  String get searchYearBefore1980 => 'Avant 1980';

  @override
  String cardTitleByAuthor(String title, String author) {
    return '$title, de $author';
  }

  @override
  String cardSource(String source) {
    return 'Source : $source';
  }

  @override
  String get cardDownloadedBadge => 'Déjà téléchargé';

  @override
  String get errorWhatToDo => 'Que faire';

  @override
  String get errorVpnHint =>
      'Un VPN peut aider à contourner les blocages régionaux.';

  @override
  String get errorVerifyIntro =>
      'Le site veut vérifier que vous êtes humain. Nous allons ouvrir une fenêtre de navigateur pour terminer la vérification.';

  @override
  String get errorVerifyReturnHint =>
      'Une fois terminé, revenez dans l\'app et appuyez sur Réessayer.';

  @override
  String get errorNoContent => 'Aucun contenu disponible';

  @override
  String errorTruncated(int count) {
    return '… (tronqué, $count caractères au total)';
  }

  @override
  String get errorNoInternetTitle => 'Vous êtes hors ligne';

  @override
  String get errorNoInternetBody =>
      'Vérifiez que le Wi-Fi ou les données mobiles sont activés et que le mode avion est désactivé, puis réessayez.';

  @override
  String get errorTimeoutTitle => 'La source a mis trop de temps à répondre';

  @override
  String get errorTimeoutBody =>
      'Votre connexion est peut-être lente, ou le site est surchargé. Réessayez dans un instant ou choisissez une autre source.';

  @override
  String get errorServerUnavailableTitle => 'La source ne répond pas';

  @override
  String get errorServerUnavailableBody =>
      'Le site est peut-être indisponible. Réessayez dans quelques minutes ou choisissez un autre miroir dans les Paramètres.';

  @override
  String get errorBlockedTitle => 'Le site veut vérifier que vous êtes humain';

  @override
  String get errorBlockedBody =>
      'Appuyez sur Vérifier dans le navigateur pour passer la vérification, ou réessayez dans quelques minutes. Un autre réseau ou un VPN peut aussi aider.';

  @override
  String get errorForbiddenTitle => 'Accès refusé';

  @override
  String get errorForbiddenBody =>
      'Le site a refusé la requête. Il est peut-être bloqué dans votre région ; un VPN ou un autre miroir dans les Paramètres peut aider.';

  @override
  String get errorRateLimitedTitle => 'Trop de requêtes';

  @override
  String get errorRateLimitedBody =>
      'Patientez quelques minutes, puis réessayez.';

  @override
  String get errorSslTitle => 'La connexion sécurisée a échoué';

  @override
  String get errorSslBody =>
      'Votre réseau bloque peut-être les connexions sécurisées. Essayez un autre réseau ou un VPN.';

  @override
  String get errorDnsTitle => 'Serveur introuvable';

  @override
  String get errorDnsBody =>
      'Votre réseau ou fournisseur bloque peut-être le site. Essayez le DNS 1.1.1.1, un VPN ou un autre réseau.';

  @override
  String get errorUnknownTitle => 'Une erreur s\'est produite';

  @override
  String get errorUnknownBody => 'Réessayez ou choisissez une autre source.';

  @override
  String get errorSourcesFailedTitle => 'Aucune source n\'a répondu';

  @override
  String errorSourcesFailedBody(String sources) {
    return '$sources n\'a pas répondu. Ces sources sont peut-être indisponibles ou bloquées sur votre réseau. Réessayez, ou essayez un autre réseau ou un VPN.';
  }

  @override
  String resultsSourcesDidNotRespond(String sources) {
    return '$sources n\'a pas répondu';
  }

  @override
  String resultsNoMatchesSourcesDown(String sources) {
    return '$sources n\'a pas répondu, toutes les sources n\'ont donc pas été consultées.';
  }

  @override
  String get resultsNoMatchesHint =>
      'Vérifiez l\'orthographe, utilisez moins de mots ou cherchez dans une autre source.';

  @override
  String get resultsClearFilters => 'Effacer les filtres';

  @override
  String get resultsTryAnotherSource => 'Essayer une autre source';

  @override
  String get resultsEditSearch => 'Modifier la recherche';

  @override
  String resultsEndOfList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fin des résultats · $count livres',
      one: 'Fin des résultats · 1 livre',
    );
    return '$_temp0';
  }

  @override
  String get resultsActiveFilters => 'Filtres actifs';

  @override
  String resultsFilterChip(String label, String value) {
    return '$label : $value';
  }

  @override
  String get resultsRemoveFilter => 'Retirer le filtre';

  @override
  String resultsFiltersIgnored(int count, String filters, String source) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$source ne prend pas en charge $filters : les résultats ne sont pas filtrés par ces critères.',
      one:
          '$source ne prend pas en charge $filters : les résultats ne sont pas filtrés par ce critère.',
    );
    return '$_temp0';
  }

  @override
  String get resultsSortedWithinPage =>
      'Trié au sein de chaque page de résultats';
}
