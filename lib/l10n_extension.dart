// ===== L10nContextExt: localization helpers (part of extension.dart) =====
part of 'extension.dart';

extension L10nContextExt on BuildContext {
  // --- Localization & Fonts ---
  // Language detection and font selection based on current locale
  String lang() => Localizations.localeOf(this).languageCode;
  String font() =>
      (lang() == "ja") ? "notoJP":
      (lang() == "zh") ? "notoSC":
      (lang() == "ko") ? "bmDohyeon":
      "roboto";

  // --- Localized Strings --- Common app strings
  // String thisApp() => AppLocalizations.of(this)!.thisApp;
  String rooftop() => AppLocalizations.of(this)!.rooftop;
  String ground() => AppLocalizations.of(this)!.ground;
  String openDoor() => AppLocalizations.of(this)!.openDoor;
  String closeDoor() => AppLocalizations.of(this)!.closeDoor;
  String emergency() => AppLocalizations.of(this)!.emergency;
  String pushNumber() => AppLocalizations.of(this)!.pushNumber;
  String return1st() => AppLocalizations.of(this)!.return1st;
  String upFloor() => AppLocalizations.of(this)!.upFloor;
  String downFloor() => AppLocalizations.of(this)!.downFloor;
  String notStop() => AppLocalizations.of(this)!.notStop;
  String basement(int counter) => (counter < 0) ? AppLocalizations.of(this)!.basement: "";
  String floor(String number) => AppLocalizations.of(this)!.floor(number);
  String platform() => AppLocalizations.of(this)!.platform;
  String dog() => AppLocalizations.of(this)!.dog;
  String spa() => AppLocalizations.of(this)!.spa;
  String vip() => AppLocalizations.of(this)!.vip;
  String parking() => AppLocalizations.of(this)!.parking;
  String paradise() => AppLocalizations.of(this)!.paradise;
  String soundPlace(int counter, bool isShimada) =>
      (!isShimada) ? "":
      (counter == 3) ? platform():
      (counter == 7) ? dog():
      (counter == 14) ? spa():
      (counter == 154) ? vip():
      (counter == -2) ? parking():
      (counter == max) ? paradise():
      "";
  String soundFloor(int counter, bool isTop) =>
      isTop ? rooftop():
      (counter == 0) ? ground():
      (lang() == "en") ? floor("${counter.enRankNumber()}${basement(counter)}"):
      // es / fr put the ordinal before the noun.
      // A basement carries its own noun (Sotano / Sous-sol), so the floor noun is added above ground only.
      // The ordinal tables read a positive number only, so a basement passes its absolute value.
      (lang() == "es") ? (counter < 0) ? "${counter.abs().esRankNumber()}${basement(counter)}": floor(counter.esRankNumber()):
      (lang() == "fr") ? (counter < 0) ? "${counter.abs().frRankNumber()}${basement(counter)}": floor(counter.frRankNumber()):
      floor("${basement(counter)}${counter.abs()}");
  String openingSound(int counter, bool isShimada, bool isTop) =>
      "${soundFloor(counter, isTop)}${soundPlace(counter, isShimada)}${openDoor()}";

  // --- 1000 Button Mode and Settings ---
  // Text localization for 1000-button challenge mode and settings interface
  String newRecord() => AppLocalizations.of(this)!.newRecord;
  String best() => AppLocalizations.of(this)!.best;
  String start() => AppLocalizations.of(this)!.start;
  String challenge() => AppLocalizations.of(this)!.challenge;
  String yourScore() => AppLocalizations.of(this)!.yourScore;

  String settings() => AppLocalizations.of(this)!.settings;
  String ok() => AppLocalizations.of(this)!.ok;
  String cancel() => AppLocalizations.of(this)!.cancel;
  String stop() => AppLocalizations.of(this)!.stop;
  String bypass() => AppLocalizations.of(this)!.bypass;
  String changeNumber() => AppLocalizations.of(this)!.changeNumber;
  String changeBasementNumber() => AppLocalizations.of(this)!.changeBasementNumber;
  String changeNumberTitle(bool isBasement) => isBasement ? changeBasementNumber(): changeNumber();
  String unlock() => AppLocalizations.of(this)!.unlock;
  String unlockTitle() => AppLocalizations.of(this)!.unlockTitle;
  String unlockDesc() => AppLocalizations.of(this)!.unlockDesc;
  String rewardAdUnavailable() => AppLocalizations.of(this)!.rewardAdUnavailable;
  String unlockByScore() => AppLocalizations.of(this)!.unlockByScore;

  // --- Premium Purchase ---
  // The one-off unlock that removes ads and opens every button and background
  String premiumTitle() => AppLocalizations.of(this)!.premiumTitle;
  String premiumNoAds() => AppLocalizations.of(this)!.premiumNoAds;
  String premiumUnlockAll() => AppLocalizations.of(this)!.premiumUnlockAll;
  String premiumOneTime() => AppLocalizations.of(this)!.premiumOneTime;
  // The label carries the price when there is one.
  // An empty price would read as "Unlock for " with nothing after it, so it falls back to the bare verb.
  String premiumBuy(String price) => (price.isEmpty) ?
      AppLocalizations.of(this)!.premiumBuy:
      AppLocalizations.of(this)!.premiumPrice(price);
  String premiumRestore() => AppLocalizations.of(this)!.premiumRestore;
  String premiumThanks() => AppLocalizations.of(this)!.premiumThanks;
  String premiumFailed() => AppLocalizations.of(this)!.premiumFailed;
  String premiumRestoreFailed() => AppLocalizations.of(this)!.premiumRestoreFailed;
  // Shown when the offer cannot be made at all (no offering, unapproved product, no network).
  // Distinct from premiumFailed(): nobody has tried to buy anything yet.
  String premiumUnavailable() => AppLocalizations.of(this)!.premiumUnavailable;

  // --- Menu and Navigation ---
  // Menu system localization
  String menu() => AppLocalizations.of(this)!.menu;
  String back() => AppLocalizations.of(this)!.back;
  String ranking() => AppLocalizations.of(this)!.ranking;
  String terms() => AppLocalizations.of(this)!.terms;
  String officialPage() =>  AppLocalizations.of(this)!.officialPage;
  String officialShop() => AppLocalizations.of(this)!.officialShop;

  // --- External Links ---
  // Dynamic link generation for external resources with language-specific routing
  String shimaxLink() =>
    (lang() == "ja") ? shimadaJa:
    (lang() == "zh") ? shimadaZh:
    (lang() == "ko") ? shimadaKo: shimadaEn;
  String landingPageLink() => (lang() == "ja") ? landingPageJa: landingPageEn;
  String privacyPolicyLink() => (lang() == "ja") ? privacyPolicyJa: privacyPolicyEn;
  String youtubeLink() => (lang() == "ja") ? youtubeJa: youtubeEn;

  // --- Menu Links and Titles ---
  List<String> linkLogos() => [
    youtubeLogo,
    landingPageLogo,
    privacyPolicyLogo,
    if (lang() == "ja") shopPageLogo,
  ];
  List<String> linkLinks() => [
    youtubeLink(),
    landingPageLink(),
    privacyPolicyLink(),
    if (lang() == "ja") shopLink,
  ];
  List<String> linkTitles() => [
    "Youtube",
    officialPage(),
    terms(),
    if (lang() == "ja") officialShop(),
  ];
}
