// ===== MenuPage: main menu interface =====
// State, initialization, menu navigation, saved settings, external links, UI layout

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'analytics_manager.dart';
import 'common_widget.dart';
import 'games_manager.dart';
import 'audio_manager.dart';
import 'buttons.dart';
import 'extension.dart';
import 'constant.dart';
import 'main.dart';
import 'homepage.dart';
import 'plan_provider.dart';
import 'premium_page.dart';
import 'purchase_manager.dart';
import 'settings.dart';

class MenuPage extends HookConsumerWidget {
  final bool isHome;
  const MenuPage({super.key, required this.isHome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // --- State Management ---
    // Riverpod providers for app-wide state
    final isShimada = ref.watch(isShimadaProvider);
    final isGamesSignIn = ref.watch(gamesSignInProvider);
    final isPremium = ref.watch(planProvider).isPremium;

    // --- Local State Variables ---
    // Loading state and app lifecycle management
    final isLoadingData = useState(false);
    final storePrice = useState("");
    final lifecycle = useAppLifecycleState();

    // --- Manager Instances ---
    // Audio manager for sound effects
    final audioManager = useMemoized(() => AudioManager());

    // --- Widget Instances ---
    // Common widgets and menu-specific widget instances
    final common = CommonWidget(context: context);
    final menu = MenuWidget(context: context);

    // --- Initialization Functions ---
    // Initialize games sign-in and best score data
    initState() async {
      isLoadingData.value = true;
      try {
        ref.read(gamesSignInProvider.notifier).update(await gamesSignIn(isGamesSignIn));
        ref.read(bestScoreProvider.notifier).update(await getBestScore(isGamesSignIn));
        isLoadingData.value = false;
      } catch (e) {
        "Error: $e".debugPrint();
        isLoadingData.value = false;
      }
    }

    // --- Lifecycle Management ---
    // Initialize app on first build
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await initState();
        // The menu is a deliberate tap long after the first frame, so starting
        // the store SDK here costs the launch nothing
        final price = await PurchaseManager.fetchPrice();
        if (!context.mounted) return;
        if (price != null) {
          storePrice.value = price;
          ref.read(planProvider.notifier).setPrice(price);
        }
      });
      return null;
    }, []);

    // Handle app lifecycle changes (pause/inactive states)
    useEffect(() {
      if (lifecycle == AppLifecycleState.inactive || lifecycle == AppLifecycleState.paused) {
        if (context.mounted) audioManager.stopAudio();
      }
      return null;
    }, [lifecycle]);

    // --- Data Persistence ---
    // Retrieve saved floor numbers, stops, and button style settings
    getSavedData(bool isShimada) async {
      final prefs = await SharedPreferences.getInstance();
      final savedFloorNumbers = normalizedFloorNumbers(
        "numbersKey".getSharedPrefListInt(prefs, initialFloorNumbers));
      final savedFloorStops = normalizedFloorStops(
        "stopsKey".getSharedPrefListBool(prefs, initialFloorStops));
      final savedButtonStyle = "buttonStyleKey".getSharedPrefInt(prefs, initialButtonStyle);
      ref.read(floorNumbersProvider.notifier).update(isShimada ? shimadaFloorNumbers : savedFloorNumbers);
      ref.read(floorStopsProvider.notifier).update(isShimada ? initialFloorStops : savedFloorStops);
      ref.read(buttonStyleProvider.notifier).update(isShimada ? 0 : savedButtonStyle);
    }

    // --- Premium Purchase --- the fifth menu button

    /// Run the purchase or restore flow and report the result to the user
    Future<void> runPurchase({required bool isRestore}) async {
      isLoadingData.value = true;
      try {
        final purchased = await PurchaseManager.buyPremium(
          isRestore: isRestore,
          source: "menu",
        );
        if (!context.mounted) return;
        if (purchased) {
          await ref.read(planProvider.notifier).setCurrentPlan(true);
          if (!context.mounted) return;
          common.commonSnackBar(context.premiumThanks());
        } else if (isRestore) {
          common.commonSnackBar(context.premiumRestoreFailed());
        }
      } catch (e) {
        "Purchase error: $e".debugPrint();
        // Nothing to sell is not a failed purchase. The reviewer sees this one
        // while the product is still attached to the submission
        if (context.mounted) {
          common.commonSnackBar((e is StoreUnavailableException)
            ? context.premiumUnavailable()
            : context.premiumFailed());
        }
      } finally {
        isLoadingData.value = false;
      }
    }

    /// Open the purchase page. The price is fetched again, since an offering or
    /// the network can drop meanwhile; an empty answer is said aloud
    Future<void> openUpgrade() async {
      isLoadingData.value = true;
      final price = await PurchaseManager.fetchPrice();
      if (!context.mounted) return;
      isLoadingData.value = false;
      storePrice.value = price ?? "";
      ref.read(planProvider.notifier).setPrice(price ?? "");
      await AnalyticsManager.upgradeOffered("menu");
      if (!context.mounted) return;
      context.pushPage(PremiumPage(
        price: price ?? "",
        onBuy: () async {
          context.popPage();
          await runPurchase(isRestore: false);
        },
        onRestore: () async {
          context.popPage();
          await runPurchase(isRestore: true);
        },
      ));
    }

    // --- Menu Navigation Logic ---
    // Process menu button clicks with sound effects and navigation
    pressedMenuLink(int i) async {
      audioManager.playEffectSound(asset: selectSound, volume: 0.8);
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      if (i == 0) {
        // Toggle Shimada mode and return to home
        await getSavedData(!isShimada);
        ref.read(isShimadaProvider.notifier).update(!isShimada);
        if (context.mounted) context.pushFadeReplacement(HomePage());
      } else if (i == 1) {
        // Navigate to buttons page or show leaderboard
        await getSavedData(false);
        ref.read(isShimadaProvider.notifier).update(true);
        (!isHome && isGamesSignIn) ? await gamesShowLeaderboard(isGamesSignIn):
        (context.mounted) ? context.pushFadeReplacement(ButtonsPage()): null;
      } else if (i == 2) {
        // Navigate to settings page
        await getSavedData(false);
        ref.read(isShimadaProvider.notifier).update(true);
        if (context.mounted) context.pushFadeReplacement(SettingsPage());
      } else if (i == 3) {
        // Return to home and launch external link
        await getSavedData(false);
        ref.read(isShimadaProvider.notifier).update(false);
        if (context.mounted) context.pushFadeReplacement(HomePage());
        if (context.mounted) launchUrl(Uri.parse(context.shimaxLink()));
      } else if (i == 4) {
        // The purchase page keeps the menu underneath, so the menu stays open
        await openUpgrade();
        return;
      }
      ref.read(isMenuProvider.notifier).update(false);
    }

    // --- UI Layout ---
    // Main menu interface layout with responsive design
    return Scaffold(
      backgroundColor: blackColor,
      appBar: menu.menuAppBar(),
      // bottom is left out: the ad space this page reserves has to line up with
      // the banner HomePage draws outside its own SafeArea
      body: SafeArea(
        bottom: false,
        child: Stack(alignment: Alignment.topCenter,
          children: [
            // Background image with responsive sizing
            common.commonBackground(
              width: context.width(),
              image: backgroundStyleList[0].backGroundImage(),
            ),
            // Main content container with menu buttons and links
            Column(children: [
              // --- Menu Buttons Grid ---
              // The fifth tile (purchase) made the grid taller than a 667 screen
              // leaves. Scaled down to fit the space instead of overflowing it;
              // on a screen with room to spare it stays at full size
              // The width is pinned to the screen so spaceEvenly spreads the
              // tiles exactly as before; only the height decides the scale
              Expanded(child: FittedBox(fit: BoxFit.scaleDown,
                child: SizedBox(width: context.width(),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ...context.menuButtons(isHome, isShimada, isGamesSignIn, isPremium).asMap().entries.map((row) => Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.value.asMap().entries.map((col) => Row(children: [
                    GestureDetector(
                      onTap: () =>  pressedMenuLink(2 * row.key + col.key),
                      child: SizedBox(
                        width: context.menuButtonSize(),
                        height: context.menuButtonSize(),
                        child: Image.asset(col.value),
                      ),
                    ),
                  ])).toList(),
                ),
                if (row.key < (isPremium ? 1 : 2)) SizedBox(height: context.menuButtonMargin()),
              ])),
              ]),
              ))),
              // --- Bottom Navigation Links ---
              // External links and social media navigation
              menu.menuBottomLinks(),
              // Space for what HomePage draws over this page: the banner's fixed
              // ceiling, or, once premium removes it, the round menu button plus
              // the inset that button is lifted by. admobHeight() is not it: the
              // banner is always inlineBannerMaxHeight tall
              Container(
                color: blackColor,
                height: isPremium
                  ? context.operationButtonSize()
                      + MediaQuery.viewPaddingOf(context).bottom
                  : inlineBannerMaxHeight.toDouble(),
              ),
            ]),
            // --- Overlay Elements ---
            // Loading indicator during data initialization
            if (isLoadingData.value) common.commonCircularProgressIndicator(),
          ]
        ),
      ),
    );
  }
}

// ===== MenuWidget: menu interface components =====
// AppBar with title, and bottom links to external resources

class MenuWidget {

  final BuildContext context;

  MenuWidget({
    required this.context,
  });

  // --- AppBar Component ---
  // Menu header with responsive title and styling
  AppBar menuAppBar() => AppBar(
    toolbarHeight: context.menuAppBarHeight(),
    backgroundColor: blackColor,
    centerTitle: true,
    shadowColor: darkBlackColor,
    iconTheme: IconThemeData(color: whiteColor),
    title: Text(context.menu(),
      style: TextStyle(
        color: whiteColor,
        fontSize: context.menuAppBarFontSize(),
        fontFamily: context.font(),
      ),
    ),
  );

  // --- Bottom Navigation Component ---
  // External links navigation with social media icons
  /// A plain Row, not a BottomNavigationBar: the bar added its own padding under
  /// the labels, which left a gap above the ad banner. There is always something
  /// reserved below this row, so it never takes the system inset itself
  Widget menuBottomLinks() => Container(
    color: blackColor,
    // The top keeps what the bar gave it: menuLinksMargin, plus the half font
    // size the bar added itself. The underside matches it; what the bar added
    // beyond that is gone, which is the gap this replacement was for
    padding: EdgeInsets.symmetric(
      vertical: context.menuLinksMargin() + context.menuLinksTitleSize() / 2,
    ),
    // The bar clamped text scaling and ellipsized; without both, a large system
    // font setting overflows the row
    child: MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.0,
      child: Row(
        // Expanded, as the bar's tiles were: the whole share is tappable
        children: List.generate(context.linkLogos().length, (i) => Expanded(
          child: Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => launchUrl(Uri.parse(context.linkLinks()[i])),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: context.menuLinksLogoSize(),
                    child: Image.asset(context.linkLogos()[i]),
                  ),
                  SizedBox(height: context.menuLinksTitleMargin()),
                  Text(
                    context.linkTitles()[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: lampColor,
                      fontSize: context.menuLinksTitleSize(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
      ),
    ),
  );
}