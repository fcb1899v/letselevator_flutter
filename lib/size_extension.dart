// ===== SizeExt: responsive layout sizes (part of extension.dart) =====
part of 'extension.dart';

extension SizeExt on BuildContext {
  double width() => MediaQuery.of(this).size.width;
  double height() => MediaQuery.of(this).size.height;
  double paddingTop() => MediaQuery.of(this).padding.top;

  // --- Progress Indicator Sizing ---
  // Responsive sizing utilities for circular progress indicators
  double circleSize() => ((height() > width()) ? width(): height()) * 0.1;
  double circleStrokeWidth() => ((height() > width()) ? width(): height()) * 0.012;

  /// The purchase tile is the fifth, alone on its own row and centred. It is
  /// dropped once premium is owned or while no store price is known
  List<List<String>> menuButtons(
    bool isHome, bool isShimada, bool isGamesSignIn, bool hasPurchase,
  ) => [
    [isHome.modeChangeButton(isShimada), isHome.modeChallengeButton(isGamesSignIn)],
    [settingsButton, aboutShimadaButton],
    if (hasPurchase) [purchaseButton],
  ];

  // --- Responsive Design ---
  // Core responsive sizing utilities for adaptive layouts across different devices
  double responsible() => (height() < 1000) ? height(): 1000;
  double widthResponsible() => (width() < 600) ? width(): 600;

  // Premium purchase page, laid out against a 430 dp reference width
  double premiumContentWidth() => widthResponsible() * 0.888;
  double premiumSignHeight() => widthResponsible() * 0.242;
  double premiumSignFontSize() => widthResponsible() * 0.163;
  double premiumNameFontSize() => widthResponsible() * 0.065;
  double premiumPlateFontSize() => widthResponsible() * 0.051;
  double premiumBodyFontSize() => widthResponsible() * 0.044;
  double premiumNoteFontSize() => widthResponsible() * 0.033;
  double premiumBuyFontSize() => widthResponsible() * 0.051;
  double premiumRestoreFontSize() => widthResponsible() * 0.037;
  double premiumIconSize() => widthResponsible() * 0.172;
  double premiumIconMargin() => widthResponsible() * 0.019;
  double premiumCloseSize() => widthResponsible() * 0.065;
  double premiumBuyHeight() => widthResponsible() * 0.167;
  double premiumPlatePadding() => widthResponsible() * 0.030;
  double premiumPlateRadius() => widthResponsible() * 0.019;
  double premiumBuyRadius() => widthResponsible() * 0.033;
  double premiumBorderWidth() => widthResponsible() * 0.005;
  double premiumBuyBorderWidth() => widthResponsible() * 0.012;
  double premiumGapInner() => widthResponsible() * 0.033;
  double premiumGapBlock() => widthResponsible() * 0.084;

  // --- Display Layout ---
  // Elevator display panel sizing and positioning for floor indicators and arrows
  double displayHeight() => responsible() * 0.25;
  double displayWidth() => widthResponsible();
  double displayMargin() => responsible() * 0.05;
  double displayNumberHeight() => responsible() * 0.15;
  double displayNumberWidth() => responsible() * 0.26;
  double displayNumberFontSize() => responsible() * 0.09;
  double displayNumberMargin(int buttonStyle) => responsible() * (buttonStyle == 0 ? 0.06: 0.00);
  double displayNumberHeaderMargin() => responsible() * 0.02;
  double displayNumberHeaderFontSize() => responsible() * 0.14;
  double displayArrowHeight() => responsible() * 0.08;
  double displayArrowWidth() => responsible() * 0.08;
  double shimadaLogoHeight() => responsible() * 0.1;
  double shimadaLogoTopMargin() => responsible() * 0.05;

  // --- Button Layout ---
  // Floor and operation button sizing with responsive margins and typography
  double floorButtonSize() => responsible() * 0.075;
  double operationButtonSize() =>  responsible() * 0.075;
  double operationButtonMargin() =>  responsible() * 0.01;
  double buttonNumberFontSize() => responsible() * 0.025;
  double buttonMargin() => responsible() * 0.03;
  double floorButtonMargin() => widthResponsible() * 0.02;
  double floorButtonNumberFontSize(int i) => widthResponsible() * 0.03;
  // Fraction of the button, so the nudge holds at any button size
  double floorButtonNumberOffsetOf(String shape) =>
      floorButtonNumberOffset[shape.buttonShapeIndex()];

  // --- Advertisement Layout ---
  // AdMob banner sizing for different screen heights
  double admobHeight() => (height() < 600) ? 50: (height() < 1000) ? 50 + (height() - 600) / 8: 100;
  double admobWidth() => width() - 100;

  // --- Menu Layout ---
  // Main menu screen layout with app bar, buttons, and external links
  double menuAppBarHeight() => height() * 0.07;
  double menuAppBarFontSize() => height() * 0.032;
  double menuButtonSize() => widthResponsible() * 0.33;
  double menuButtonMargin() => responsible() * 0.035;
  double menuLinksLogoSize() => widthResponsible() * 0.16;
  double menuLinksTitleSize() => widthResponsible() * 0.025;
  double menuLinksTitleMargin() => widthResponsible() * 0.02;
  double menuLinksMargin() => widthResponsible() * 0.04;

  // --- Settings Layout ---
  // Divider: Visual separators between settings sections
  double settingsDividerHeight() => height() * 0.015;
  double settingsDividerThickness() => height() * 0.001;
  // AppBar: Top navigation bar with back button and title
  double settingsAppBarHeight() => height() * 0.07;
  double settingsAppBarFontSize() => height() * 0.032;
  double settingsAppBarBackButtonSize() => height() * 0.05;
  double settingsAppBarBackButtonMargin() => height() * 0.01;
  // Lock: Premium feature indicators and unlock buttons
  double settingsLockSize() => height() * 0.10;
  double settingsLockFontSize() => height() * 0.01;
  double settingsLockIconSize() => height() * 0.035;
  double settingsLockMargin() => height() * 0.01;
  double settingsAllLockIconSize() => height() * 0.1;
  double settingsLockTextFontSize() => height() * 0.017;
  double settingsLockTextMargin() => height() * 0.012;
  double settingsAllLockIconMargin() => height() * 0.01;
  double settingsAllLockFontSize() => height() * 0.022;
  double settingsLockFreeButtonWidth() => height() * lockPillWidthFactor;
  double settingsLockFreeButtonHeight() => height() * 0.03;
  /// Invisible margin around the Unlock pill, so a near miss still takes the
  /// free path instead of the padlock behind it (the purchase page, when priced)
  double settingsLockFreeTapPadding() => height() * lockPillPaddingFactor;
  double settingsLockFreeBorderRadius() => height() * 0.015;
  double settingsLockFreeFontSize() => height() * 0.018;
  // Tooltip: Help text overlays for setting explanations

  // --- Settings Controls ---
  // Select button: Navigation buttons for different setting categories
  double settingsSelectButtonSize() => height() * 0.06;
  double settingsSelectButtonIconSize() => height() * 0.03;
  double settingsSelectButtonMarginTop() => height() * 0.015;
  double settingsSelectButtonMarginBottom() => height() * 0.007;
  // Change button number: Floor count configuration controls
  double settingsButtonSize() => height() * floorButtonFactor;
  double settingsNumberButtonWidth() => height() * 0.07;
  double settingsNumberButtonHeight() => height() * 0.142;
  double settingsNumberButtonFontSize() => height() * 0.03;
  double settingsNumberButtonMargin() => height() * 0.015;
  /// The floor cell the lock plate covers. Derived from the plate, so a narrow
  /// screen shrinks both together instead of leaving the cell sticking out
  double settingsNumberButtonHideWidth() => floorCellWidth(width(), height());
  /// Holds the Unlock pill and its tap padding, capped by the width so four fit
  /// on a row. Past h/w 2.367 the cap wins and the pill drops below 0.08h
  double settingsFloorLockWidth() => floorLockPlateWidth(width(), height());
  /// Tall enough for the floor button, the Stop label and the switch, once the
  /// switch is sized rather than scaled (see settingsFloorStopToggleWidget)
  double settingsNumberButtonHideHeight() => floorCellHeight(height());
  double settingsNumberButtonHideMargin() => height() * 0.01;
  // Change floor stop: Toggle switches for floor stop configuration
  double settingsFloorStopFontSize() => height() * floorStopLabelFactor;
  double settingsFloorStopMargin() => height() * floorStopMarginFactor;
  double settingsFloorStopToggleScale() => height() * floorStopSwitchScaleFactor;
  // Change button style: Visual style selection for elevator buttons
  double settingsButtonStyleSize() => height() * 0.07;
  double settingsButtonStyleMargin() => height() * 0.03;
  double settingsButtonStyleLockWidth() => width() * 0.90;
  double settingsButtonStyleLockHeight() => height() * 0.19;
  double settingsButtonStyleLockMargin() => height() * 0.095;
  // Change button shape: Geometric shape selection for button appearance
  double settingsButtonShapeSize() => height() * 0.07;
  double settingsButtonShapeFontSize() => height() * 0.022;
  double settingsButtonShapeMargin() => height() * 0.005;
  // Change background image: Background image selection and preview
  double settingsBackgroundSize() => height() * 0.17;
  double settingsBackgroundMargin() => height() * 0.035;
  double settingsBackgroundSelectBorderWidth() =>  height() * 0.007;
  // Settings Alert Dialog: Modal dialogs for configuration changes
  double settingsAlertTitleFontSize() => widthResponsible() * 0.05;
  double settingsAlertDescFontSize() => widthResponsible() * 0.04;
  double settingsAlertCloseIconSize() =>  widthResponsible() * 0.1;
  double settingsAlertCloseIconSpace() =>  widthResponsible() * 0.05;
  double settingsAlertSelectFontSize() => widthResponsible() * 0.05;
  double settingsAlertFloorNumberPickerHeight() => widthResponsible() * 0.4;
  double settingsAlertFloorNumberHeight() => widthResponsible() * 0.16;
  double settingsAlertFloorNumberFontSize() => widthResponsible() * 0.1;
  double settingsAlertIconSize() => widthResponsible() * 0.06;
  double settingsAlertIconMargin() => widthResponsible() * 0.01;
  double settingsAlertLockFontSize() => widthResponsible() * 0.07;
  double settingsAlertLockIconSize() => widthResponsible() * 0.05;
  double settingsAlertLockSpaceSize() => widthResponsible() * 0.02;
  double settingsAlertLockBorderWidth() => widthResponsible() * 0.002;
  double settingsAlertLockBorderRadius() => widthResponsible() * 0.04;

  // --- 1000 Button Challenge Layout ---
  // Logo and branding elements
  double logo1000ButtonsWidth() => widthResponsible() * 0.5;
  double logo1000ButtonsPadding() => widthResponsible() * 0.01;
  // Start button for challenge mode
  double challengeStartButtonWidth() => widthResponsible() * 0.2;
  double challengeStartButtonHeight() => widthResponsible() * 0.125;
  double challengeButtonFontSize() => widthResponsible() * 0.022;
  double challengeStartFontSize() => widthResponsible() * 0.04;
  // Countdown timer display
  double countdownFontSize() => widthResponsible() * 0.075;
  double countdownPaddingTop() => widthResponsible() * 0.007;
  double countdownPaddingLeft() => widthResponsible() *  0.01;
  double countdownPaddingBottom() => widthResponsible() * 0.006;
  // Score and progress display
  double countDisplayWidth() => widthResponsible() * 0.28;
  double countDisplayHeight() => widthResponsible() * 0.12;
  double countDisplayPaddingLeft() => widthResponsible() * 0.012;
  double countDisplayPaddingBottom() => widthResponsible() * 0.01;
  // Pre-countdown animation elements
  double beforeCountdownCircleSize() => widthResponsible() * 0.4;
  double beforeCountdownNumberSize() => widthResponsible() * 0.2;
  // Score display typography
  double yourScoreFontSize() => widthResponsible() * 0.24;
  double bestScoreFontSize() => widthResponsible() * 0.12;
  double scoreTitleFontSize() => widthResponsible() * 0.09;
  double bestFontSize() => widthResponsible() * 0.09;
  // Navigation and control buttons
  double backButtonFontSize() => widthResponsible() * 0.045;
  double backButtonWidth() => widthResponsible() * 0.3;
  double backButtonHeight() => widthResponsible() * 0.1;
  double backButtonBorderRadius() => widthResponsible() * 0.02;
  // Button grid layout for challenge mode
  double defaultButtonLength() => 0.07 * height() - 2;
  double buttonWidth(int p, i, j) => p.buttonWidthFactor(i, j) * defaultButtonLength();
  double buttonHeight() => defaultButtonLength();
  double largeButtonWidth(double ratio) => ratio * defaultButtonLength();
  double largeButtonHeight(double ratio) => ratio * defaultButtonLength();
  double buttonsPadding() => (height() < 1100) ? 0.014 * height() - 3: 12.4 + 0.038 * (height() - 1100);
  // Visual styling for challenge interface
  double startBorderWidth() => (width() < 800) ? width() / 400: 2.0;
  double startCornerRadius() => (width() < 800) ? width() / 40: 20.0;
  double dividerHeight() => height() * 0.72;
  double dividerMargin() => widthResponsible() * 0.03;
}
