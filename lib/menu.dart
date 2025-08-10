// =============================
// MenuPage: Main Menu Interface
//
// This file contains the main menu interface with:
// 1. State Management: Riverpod providers and local state
// 2. Initialization: Data loading and lifecycle management
// 3. Menu Navigation: Button interactions and page transitions
// 4. Data Persistence: Shared preferences for settings
// 5. External Links: URL launching for external resources
// 6. UI Layout: Menu buttons and bottom navigation
// =============================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'common_widget.dart';
import 'games_manager.dart';
import 'audio_manager.dart';
import 'buttons.dart';
import 'extension.dart';
import 'constant.dart';
import 'main.dart';
import 'homepage.dart';
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

    // --- Local State Variables ---
    // Loading state and app lifecycle management
    final isLoadingData = useState(false);
    final lifecycle = useAppLifecycleState();

    // --- Manager Instances ---
    // Audio manager for sound effects
    final audioManager = useMemoized(() => AudioManager());

    // --- Widget Instances ---
    // Common widgets and menu-specific widget instances
    final common = CommonWidget(context: context);
    final menu = MenuWidget(context: context);

    // --- Initialization Functions ---
    // App initialization and data loading
    // Initialize games sign-in and best score data
    initState() async {
      isLoadingData.value = true;
      try {
        ref.read(gamesSignInProvider.notifier).state = await gamesSignIn(isGamesSignIn);
        ref.read(bestScoreProvider.notifier).state = await getBestScore(isGamesSignIn);
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
    // Load and apply saved settings from shared preferences
    // Retrieve saved floor numbers, stops, and button style settings
    getSavedData(bool isShimada) async {
      final prefs = await SharedPreferences.getInstance();
      final savedFloorNumbers = "numbersKey".getSharedPrefListInt(prefs, initialFloorNumbers);
      final savedFloorStops = "stopsKey".getSharedPrefListBool(prefs, initialFloorStops);
      final savedButtonStyle = "buttonStyleKey".getSharedPrefInt(prefs, initialButtonStyle);
      ref.read(floorNumbersProvider.notifier).update((state) => isShimada ? initialFloorNumbers: savedFloorNumbers);
      ref.read(floorStopsProvider.notifier).update((state) => isShimada ? initialFloorStops: savedFloorStops);
      ref.read(buttonStyleProvider.notifier).update((state) => isShimada ? 0: savedButtonStyle);
    }

    // --- Menu Navigation Logic ---
    // Handle menu button interactions with page transitions
    // Process menu button clicks with sound effects and navigation
    pressedMenuLink(int i) async {
      audioManager.playEffectSound(asset: selectSound, volume: 0.8);
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      if (i == 0) {
        // Toggle Shimada mode and return to home
        await getSavedData(!isShimada);
        ref.read(isShimadaProvider.notifier).update((state) => !state);
        if (context.mounted) context.pushFadeReplacement(HomePage());
      } else if (i == 1) {
        // Navigate to buttons page or show leaderboard
        await getSavedData(false);
        ref.read(isShimadaProvider.notifier).update((state) => true);
        (!isHome && isGamesSignIn) ? await gamesShowLeaderboard(isGamesSignIn):
        (context.mounted) ? context.pushFadeReplacement(ButtonsPage()): null;
      } else if (i == 2) {
        // Navigate to settings page
        await getSavedData(false);
        ref.read(isShimadaProvider.notifier).update((state) => true);
        if (context.mounted) context.pushFadeReplacement(SettingsPage());
      } else if (i == 3) {
        // Return to home and launch external link
        await getSavedData(false);
        ref.read(isShimadaProvider.notifier).update((state) => false);
        if (context.mounted) context.pushFadeReplacement(HomePage());
        if (context.mounted) launchUrl(Uri.parse(context.shimaxLink()));
      }
      ref.read(isMenuProvider.notifier).state = false;
    }

    // --- UI Layout ---
    // Main menu interface layout with responsive design
    return Scaffold(
      backgroundColor: blackColor,
      appBar: menu.menuAppBar(),
      body: SafeArea(
        child: Stack(alignment: Alignment.topCenter,
          children: [
            // Background image with responsive sizing
            common.commonBackground(
              width: context.width(),
              image: backgroundStyleList[0].backGroundImage(),
            ),
            // Main content container with menu buttons and links
            Column(children: [
              const Spacer(flex: 1),
              // --- Menu Buttons Grid ---
              // Dynamic menu button grid with gesture handling
              ...context.menuButtons(isHome, isShimada, isGamesSignIn).asMap().entries.map((row) => Column(children: [
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
                if (row.key == 0) SizedBox(height: context.menuButtonMargin()),
              ])),
              const Spacer(flex: 1),
              // --- Bottom Navigation Links ---
              // External links and social media navigation
              menu.menuBottomLinks(),
              // Ad space reservation
              Container(
                color: blackColor,
                height: context.admobHeight(),
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

// =============================
// MenuWidget: Menu Interface Components
//
// This class provides menu interface components including:
// 1. AppBar: Menu header with title and navigation
// 2. Bottom Links: External navigation links with icons
// =============================

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
  BottomNavigationBar menuBottomLinks() => BottomNavigationBar(
    items: List<BottomNavigationBarItem>.generate(context.linkLogos().length, (i) =>
      BottomNavigationBarItem(
        icon: Container(
          margin: EdgeInsets.only(
              top: context.menuLinksMargin(),
              bottom: context.menuLinksTitleMargin()
          ),
          width: context.menuLinksLogoSize(),
          child: Image.asset(context.linkLogos()[i]),
        ),
        label: context.linkTitles()[i],
      ),
    ),
    currentIndex: 0,
    type: BottomNavigationBarType.fixed,
    onTap: (i) => launchUrl(Uri.parse(context.linkLinks()[i])),
    elevation: 0,
    selectedItemColor: lampColor,
    unselectedItemColor: lampColor,
    selectedFontSize: context.menuLinksTitleSize(),
    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
    unselectedFontSize: context.menuLinksTitleSize(),
    backgroundColor: blackColor,
  );
}