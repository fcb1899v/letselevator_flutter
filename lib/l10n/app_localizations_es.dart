// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get letsElevator => 'LETS ELEVATOR';

  @override
  String get menu => 'Menú';

  @override
  String get settings => 'Configuración';

  @override
  String get start => 'INICIAR';

  @override
  String get back => 'ATRÁS';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get basement => 'Sótano ';

  @override
  String floor(Object NUMBER) {
    return 'Piso $NUMBER, ';
  }

  @override
  String get ground => 'Planta baja, ';

  @override
  String get openDoor => 'Abriendo puertas.';

  @override
  String get closeDoor => 'Cerrando puertas.';

  @override
  String get pushNumber => 'Seleccione piso.';

  @override
  String get upFloor => 'Subiendo.';

  @override
  String get downFloor => 'Bajando.';

  @override
  String get notStop => 'No se detiene en este piso.';

  @override
  String get emergency => 'Parada de emergencia para revisión.';

  @override
  String get return1st => 'Verificación completada. Regresando al primer piso.';

  @override
  String get bypass => 'Omitir';

  @override
  String get stop => 'Detener';

  @override
  String get changeNumber => 'Cambiar piso';

  @override
  String get changeBasementNumber => 'Cambiar piso del sótano';

  @override
  String get rooftop => 'El piso superior, ';

  @override
  String get vip => 'Piso VIP, ';

  @override
  String get spa => 'Piso de spa, ';

  @override
  String get parking => 'Piso de estacionamiento, ';

  @override
  String get platform => 'Piso de plataforma, ';

  @override
  String get paradise => 'Piso paraíso, ';

  @override
  String get dog => 'Piso mascotas, ';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get unlockTitle => '¡Mira el video para\ndesbloquear el nuevo botón!';

  @override
  String get unlockDesc =>
      '\nMira hasta el final\npara usar el nuevo botón.\n¡Pulsa OK!';

  @override
  String get rewardAdUnavailable =>
      '\nAhora no se puede reproducir el vídeo.\nRevisa tu consentimiento de anuncios\no inténtalo de nuevo en un momento.';

  @override
  String get unlockByScore => 'Consigue más de 100 puntos en el reto de 30 s';

  @override
  String get challenge => 'Reto de 30s';

  @override
  String get best => 'MEJOR';

  @override
  String get yourScore => 'PUNTUACIÓN';

  @override
  String get newRecord => '¡NUEVO RÉCORD!';

  @override
  String get termsAndPrivacyPolicy => 'Términos y política de privacidad';

  @override
  String get terms => 'Términos';

  @override
  String get officialPage => 'Página Oficial';

  @override
  String get officialShop => 'Tienda Oficial';

  @override
  String get ranking => 'Clasificación';

  @override
  String get premiumTitle => 'Pack Premium';

  @override
  String get premiumNoAds => 'Sin anuncios';

  @override
  String get premiumUnlockAll =>
      'Sin conseguir 100+ en el reto\nni ver vídeos publicitarios,\ntodos los diseños y funciones son tuyos';

  @override
  String get premiumOneTime => 'Una compra única';

  @override
  String premiumPrice(Object PRICE) {
    return 'Comprar por $PRICE';
  }

  @override
  String get premiumBuy => 'Comprar';

  @override
  String get premiumRestore => 'Restaurar compra';

  @override
  String get premiumThanks => '¡Gracias! Todo está desbloqueado.';

  @override
  String get premiumFailed => 'No se pudo completar la compra.';

  @override
  String get premiumRestoreFailed =>
      'No se encontró ninguna compra para restaurar.';

  @override
  String get premiumUnavailable =>
      'Las compras no están disponibles.\nInténtalo de nuevo más tarde.';
}
