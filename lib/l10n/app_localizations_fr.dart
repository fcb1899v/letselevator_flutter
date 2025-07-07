// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get letsElevator => 'LETS ELEVATOR';

  @override
  String get menu => 'Menu';

  @override
  String get settings => 'Paramètres';

  @override
  String get start => 'DÉMARRER';

  @override
  String get back => 'RETOUR';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'ANNULER';

  @override
  String get basement => 'Sous-sol ';

  @override
  String floor(Object NUMBER) {
    return '$NUMBERᵉ étage, ';
  }

  @override
  String get ground => 'Rez-de-chaussée, ';

  @override
  String get openDoor => 'Ouverture.';

  @override
  String get closeDoor => 'Fermeture.';

  @override
  String get pushNumber => '';

  @override
  String get upFloor => 'Montée.';

  @override
  String get downFloor => 'Descente.';

  @override
  String get notStop => 'Non desservi.';

  @override
  String get emergency => 'Arrêt d\'urgence pour inspection.';

  @override
  String get return1st => 'Vérification terminée. Retour au premier étage.';

  @override
  String get bypass => 'Passer';

  @override
  String get stop => 'Arrêter';

  @override
  String get changeNumber => 'Changer l\'étage';

  @override
  String get changeBasementNumber => 'Changer l\'étage du sous-sol';

  @override
  String get rooftop => 'Dernier étage, ';

  @override
  String get vip => 'Étage VIP, ';

  @override
  String get spa => 'Étage spa, ';

  @override
  String get parking => 'Étage parking, ';

  @override
  String get platform => 'Étage plateforme, ';

  @override
  String get paradise => 'Étage paradis, ';

  @override
  String get dog => 'Étage animaux, ';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get unlockTitle =>
      'Regardez la vidéo pour\ndéverrouiller le nouveau bouton !';

  @override
  String get unlockDesc =>
      '\nRegardez jusqu\'à la fin\npour utiliser le nouveau bouton.\nAppuyez sur OK !';

  @override
  String get unlockAllTitle => 'Conditions de déverrouillage : 1. ou 2.';

  @override
  String get unlockAll1 =>
      '1. Obtenez plus de 100 points dans le défi de 30 s.';

  @override
  String get unlockAll2 => '2. Déverrouillez toutes les formes de boutons.';

  @override
  String get challenge => 'Défi 30 s';

  @override
  String get best => 'MEILLEUR';

  @override
  String get yourScore => 'SCORE';

  @override
  String get newRecord => 'NOUVEAU RECORD !';

  @override
  String get termsAndPrivacyPolicy =>
      'Conditions et politique de confidentialité';

  @override
  String get terms => 'Conditions';

  @override
  String get officialPage => 'Page officielle';

  @override
  String get officialShop => 'Boutique officielle';

  @override
  String get ranking => 'Classement';
}
