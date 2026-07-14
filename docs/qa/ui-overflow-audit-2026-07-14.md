# FlowFit UI Overflow Audit - 2026-07-14

Static multi-agent audit of lib/ (38 agents: partitioned finders + adversarial verifiers). Every finding below was independently re-verified against the real widget tree by a skeptic agent told to refute it. 29 confirmed (3 refuted during verification), plus 7 low-severity notes.

Common causes: (1) buddy-name Text in Rows without Flexible/ellipsis, (2) non-scrollable onboarding Columns that overflow at 1.3x font scale or on short viewports, (3) Wear OS screens overflowing 192-227dp round faces, (4) workout stat text growing past fixed widths. Note: Android is portrait-locked in the manifest, but iOS Info.plist allows landscape, so all landscape triggers are iOS-only; the 1.3x-font-scale triggers apply to Android too.

## Confirmed findings

### 1. [HIGH] lib/screens/onboarding/buddy_ready_screen.dart:359

- Trigger: 360dp-wide phone with a buddy name longer than ~7 characters (kid names the whale 'Splashy McWhale'), or default name 'Bubbles' at 1.3x accessibility font scale
- Why: The stat-gain Text sits directly in a Row with no Expanded/Flexible wrapper, no maxLines, and no TextOverflow.ellipsis. buddyName is user-entered (up to 20 chars, enforced in buddy_naming_screen.dart). The Row's width is bounded (screen minus 24dp outer padding, 16dp container padding, 2dp border each side), and the icon + 12dp spacer consume another 40dp, leaving ~236dp on a 360dp phone. A bold titleMedium string like 'WWWWWWWWWWWWWWWWWWWW gained +5.9 Compassion' (44 chars) needs ~350dp+, producing a RenderFlex horizontal overflow with yellow/black stripes. Even the default name 'Bubbles' is borderline at 1.0x and overflows at 1.3x font scale.
- Suggested fix: Wrap the Text in Flexible with maxLines: 1 (or 2) and overflow: TextOverflow.ellipsis, or wrap the Row content in a FittedBox(fit: BoxFit.scaleDown).

### 2. [HIGH] lib/screens/onboarding/notification_permission_screen.dart:144

- Trigger: 360dp-wide phone with a long buddy name (15-20 chars), or a medium-length name combined with 1.3x font scale
- Why: The notification-preview header Text is a bare Row child with no Expanded/Flexible and no overflow handling. buddyName is user-generated (up to 20 chars). Available width on a 360dp phone is ~232dp (360 - 48 outer padding - 32 card padding - 4 border - 32 avatar - 12 spacer); 'From ' + 20-char name + ' • now' at w600 bodyMedium needs ~250dp at 1.0x and far more at 1.3x, causing a RenderFlex horizontal overflow inside the preview card.
- Suggested fix: Wrap the Text in Expanded (or Flexible) and add overflow: TextOverflow.ellipsis, maxLines: 1.

### 3. [HIGH] lib/screens/onboarding/buddy_color_selection_screen.dart:180

- Trigger: Small phone (360x640dp) at 1.0x is already borderline; any 1.3x font scale, landscape orientation, or a 320dp-wide device overflows/clips
- Why: The screen body is a non-scrollable Column whose fixed children already total ~620dp at 1.0x scale (header ~100 + 48 + 32 + fixed 280dp egg circle + 32 + ~64dp button + 64dp vertical padding). Only the buddy-preview is Expanded, and it can only shrink to 0; once the fixed content exceeds the viewport the Column throws 'RenderFlex overflowed by N pixels on the bottom'. Additionally the egg circle math places top eggs at y = -8 (140 - 100 - 48), so egg tops are clipped by the Stack even when the Column fits, and at 320dp width the left/right eggs (need 280dp) get clipped horizontally.
- Suggested fix: Wrap the Column in a SingleChildScrollView (replacing Expanded with fixed spacing or ConstrainedBox+IntrinsicHeight), and either increase the egg SizedBox height to 296 or reduce the radius so eggs fit within the 280dp Stack.

### 4. [MEDIUM] lib/screens/onboarding/buddy_completion_screen.dart:181

- Trigger: Landscape on any phone (~360dp height), or a small/short phone at 1.3x font scale with a long buddy name wrapping the headline to two lines
- Why: Non-scrollable Column with large fixed-size children: 64px emoji, 160dp buddy widget, displaySmall headline, two-line titleLarge subtitle, plus a button — roughly 530dp of fixed content at 1.0x, ~590dp at 1.3x. The two Spacers collapse to zero and then the Column emits a RenderFlex bottom overflow. A long user-chosen buddyName also pushes the displaySmall headline onto 2 lines, worsening it.
- Suggested fix: Wrap the Column in a SingleChildScrollView with ConstrainedBox(minHeight: constraints.maxHeight) via LayoutBuilder (replacing Spacers with padding/mainAxisAlignment), or lock the app to portrait on iOS as well and still add scrolling for large font scales.

### 5. [MEDIUM] lib/screens/onboarding/buddy_welcome_screen.dart:30

- Trigger: Landscape orientation on any phone, or a 640dp-tall small phone at 1.3x accessibility font scale
- Why: Non-scrollable Column containing a fixed 200dp buddy widget, a two-line displaySmall heading (~90dp, ~117dp at 1.3x), a two-line titleMedium tagline, and a ~64dp button plus 48dp padding — ~530dp fixed at 1.0x, ~590dp+ at 1.3x. Spacers shrink to zero and the Column overflows on short viewports; there is no SingleChildScrollView fallback.
- Suggested fix: Wrap the Column in a LayoutBuilder + SingleChildScrollView with ConstrainedBox(minHeight: constraints.maxHeight) so Spacers still work on tall screens but content scrolls on short/landscape viewports.

### 6. [MEDIUM] lib/screens/onboarding/onboarding_screen.dart:124

- Trigger: Any phone rotated to landscape (~360dp viewport height), or a very short phone at 1.3x font scale
- Why: Each PageView page is a non-scrollable Column with a fixed 140dp icon container, 48dp spacer, headline, and multi-line description, all inside 80dp of vertical padding. The PageView's height is what remains after the Skip button, page indicator, 56dp CTA and 64dp of spacers — in landscape that leaves ~180-250dp while the page content needs ~330dp+ (more at 1.3x), so every page throws a RenderFlex bottom overflow.
- Suggested fix: Wrap the per-page Column in a SingleChildScrollView (or LayoutBuilder + ConstrainedBox/FittedBox), e.g. return Padding(... child: SingleChildScrollView(child: Column(...))) — or lock the app to portrait on iOS too via SystemChrome.setPreferredOrientations and cap font-scale-driven growth.

### 7. [MEDIUM] lib/screens/onboarding/age_gate_screen.dart:35

- Trigger: Landscape on any phone, or a small 640dp-tall phone at 1.3x font scale where the two-line card subtitles and 3-line privacy note push past the viewport
- Why: Non-scrollable Column: 40dp top spacer + headline + subtitle + 48dp + two ~112dp gradient cards (taller at 1.3x since card text scales) + privacy note (~70dp, grows when its wrapped text spans 3 lines at 1.3x) totals ~500dp at 1.0x and ~570dp+ at 1.3x. The single Spacer collapses to zero and the Column overflows the bottom on short viewports; no scroll view wraps the content.
- Suggested fix: Wrap the Column's content in a SingleChildScrollView (e.g. LayoutBuilder + ConstrainedBox(minHeight) with the Spacer replaced by a SizedBox or MainAxisAlignment.spaceBetween) so short/landscape viewports scroll instead of overflowing.

### 8. [HIGH] lib/screens/profile/kids_profile_screen.dart:443

- Trigger: 360dp-wide phone with a nickname of ~20+ characters (e.g. 'Christopher Alexander'), worse at 1.3x accessibility font scale where even ~12-character nicknames overflow
- Why: _buildInfoTile puts two rigid Text widgets in a Row with no Expanded/Flexible wrapper and no overflow/maxLines. It is called at line 331 with _buildInfoTile(context, 'Nickname', profile.nickname!) — a user-generated string with no length guarantee. Any nickname longer than the remaining width (~280dp inside the padded card) makes the Row emit 'RenderFlex overflowed on the right'.
- Suggested fix: Wrap the value Text (and optionally the label) in Flexible with overflow: TextOverflow.ellipsis, e.g. Flexible(child: Text(value, overflow: TextOverflow.ellipsis, ...)).

### 9. [HIGH] lib/screens/health/health_screen.dart:348

- Trigger: 360dp-wide phone at default font scale (worse at 1.3x, where the calories line '1595/2000 kcal' and button label grow another ~30%)
- Why: Neither side of the spaceBetween Row is wrapped in Expanded/Flexible and no text has ellipsis. Icon container (~44dp) + 12dp gap + 'Food Intake' at titleLarge (~120dp) plus the 'Add Food' ElevatedButton.icon (~130dp incl. 40dp padding) totals ~305dp, but the card's content width on a 360dp phone is only ~280dp (20dp screen padding + 20dp card padding per side). RenderFlex overflow on the right.
- Suggested fix: Wrap the left inner Row in Expanded (with Flexible/ellipsis on the title/kcal Texts) so the button keeps its size and the text column absorbs the shortfall.

### 10. [HIGH] lib/screens/workout/running/active_running_screen.dart:814

- Trigger: 360dp-wide phone once caloriesBurned reaches 4 digits or steps reach 5 digits during a long run; guaranteed at 1.3x font scale even with 3-digit values
- Why: _buildSmallMetric renders value+unit in a min Row with no FittedBox/Flexible/ellipsis, inside a card that is one third of the panel width minus 24dp internal padding (~74dp content width on a 360dp phone). A 4-digit calorie value ('1234' at 20px bold ~48dp) plus 'kcal' (~28dp) already exceeds it, and steps can reach 5 digits ('12345' ~60dp). The sibling _buildLargeMetric wraps its value Row in FittedBox but this one does not.
- Suggested fix: Wrap the value Row at lib/screens/workout/running/active_running_screen.dart:814 in FittedBox(fit: BoxFit.scaleDown), matching _buildLargeMetric at line 707.

### 11. [HIGH] lib/screens/progress/progress_screen.dart:128

- Trigger: 360dp-wide phone at default font scale (borderline, few px) and clearly at 1.3x font scale or any locale with a longer 'Weekly Activity'/'Month' translation
- Why: 'Weekly Activity' at titleLarge bold (~155dp) plus the Week/Month toggle (two buttons each with 40dp horizontal padding + label, ~170dp total) needs ~325dp but only 320dp is available (360dp minus 20dp padding per side). No Expanded/Flexible on either child, so the Row overflows; at 1.3x font scale the deficit grows to ~70dp.
- Suggested fix: Wrap the title Column in Expanded (with TextOverflow.ellipsis on the title) or wrap the whole Row content in a FittedBox/Wrap; also consider reducing the toggle buttons' 20dp horizontal padding.

### 12. [HIGH] lib/screens/workout/running/active_running_screen.dart:349

- Trigger: Small phone (~640dp usable height, e.g. 360x640) once the AI classifier returns a result so _buildAIMetricsBreakdown is shown; on taller phones it reproduces at 1.3x font scale or in landscape
- Why: This content-overlay Column sits directly in a Stack inside SafeArea with no scroll view; only the Spacer is flexible. Fixed content = header (~76dp) + activity badge (~64dp) + AI metrics breakdown (~180dp: title + 3 probability bars) + 16dp + bottom metrics panel (~370dp: large metric row + small metric row + button row + paddings) ≈ 700dp. Once the Spacer collapses to 0 the Column overflows the bottom.
- Suggested fix: Wrap the badge+breakdown+panel section in a SingleChildScrollView, or make the AI breakdown/badge section Flexible with a scroll view, so the bottom panel stays on screen on small phones and large font scales.

### 13. [MEDIUM] lib/screens/phone/phone_heart_rate_screen.dart:235

- Trigger: Enable the bug-report Test Mode toggle while heart-rate data is arriving on a 360x640 phone (or any phone at 1.3x font scale)
- Why: _buildDataList is a plain Column, not a scroll view. In test mode the Expanded ListView is omitted, so all children are fixed-height: the test-mode card (~430-460dp with 5 _buildTestRow lines, 3 accelerometer sample lines and margins) + the 64px-font BPM card (~200dp) + freshness text + divider ≈ 700dp of unscrollable content under a 56dp AppBar. RenderFlex overflow at the bottom on anything shorter.
- Suggested fix: Wrap the non-Expanded content in a SingleChildScrollView when _isTestMode (or make the whole test-mode branch a ListView) so the fixed-height cards can scroll.

### 14. [MEDIUM] lib/screens/home/home_screen.dart:203

- Trigger: 360dp-wide phone with 1.3x accessibility font scale on the Home tab
- Why: Grid cells get a fixed height from childAspectRatio (~140dp for a ~154dp-wide cell on a 360dp phone). Each cell's Column (16dp padding x2 + emoji Text fontSize 32 inside a 14dp-padded container + 12dp gap + titleMedium label) is ~132dp at 1.0 scale. Both the 32px emoji and the label scale with textScaleFactor, pushing content to ~145-165dp at 1.3x while the cell height stays 140dp — RenderFlex overflow inside every grid tile (and 'Heart Check'/'Drink Water' can wrap to 2 lines, adding ~28dp more).
- Suggested fix: Wrap the tile Column's label in a FittedBox (or give the Column a FittedBox/Flexible with maxLines: 1 + ellipsis), or replace childAspectRatio with a fixed mainAxisExtent computed from text scale (SliverGridDelegateWithFixedCrossAxisCount.mainAxisExtent).

### 15. [MEDIUM] lib/screens/track/track_screen.dart:14

- Trigger: Phone rotated to landscape (usable height ~330-360dp) or a small phone at 1.3x font scale
- Why: The screen body is a non-scrollable Column; only the SVG is in an Expanded. Fixed content = 48dp padding + 32px title + 18px subtitle + spacings + three activity buttons (~86dp each) ≈ 455dp minimum, more at larger font scale (~500dp at 1.3x since titles/subtitles in the buttons grow). When the viewport is shorter than that the Expanded bottoms out at 0 and the Column overflows.
- Suggested fix: Wrap the Column's fixed content in a LayoutBuilder + SingleChildScrollView/ConstrainedBox (or make the whole body scrollable and give the SVG a bounded height instead of Expanded).

### 16. [MEDIUM] lib/screens/health/health_screen.dart:495

- Trigger: 360dp-wide phone with 1.3x accessibility font scale on the Health tab
- Why: Hydration card header: left Row (44dp icon container + 12dp + 'Hydration' at titleLarge ~110dp) and the right '1.5 / 2.0 L' titleMedium text (~90dp) fit a 272dp card width (360 - 40 screen padding - 48 card padding) with only ~16dp slack. At 1.3x font scale the two sides need ~315dp, and neither is Flexible nor has ellipsis, so the Row overflows. The Sleep card header at line 628 ('Total sleep: Xh Ym' + 'Edit' button) has the same pattern.
- Suggested fix: Wrap the left inner Row (and the Sleep card's inner Row/Column) in Flexible with TextOverflow.ellipsis on the labels, or wrap the trailing value Text in Flexible — e.g. Expanded(child: Row(...)) + Text with overflow: TextOverflow.ellipsis.

### 17. [HIGH] lib/screens/wear/sensor_permission_rationale_screen.dart:128

- Trigger: Any standard round Wear OS face (~192-227dp tall); overflows immediately on screen open, worse after a permission/settings error sets _errorMessage
- Why: The entire rationale screen is a fixed Column inside Center with no SingleChildScrollView. Content sums to roughly 350-450dp: 48dp icon, title, a ~150-char explanation paragraph that wraps to ~7-8 lines at 14sp in the ~160dp-wide area (192dp face minus 32dp horizontal padding), 'This data is used to:' plus 3 bullet lines, two 48dp buttons with 24/12dp spacers, and an optional error Container (which includes '${e.toString()}' of unbounded length) that grows it further.
- Suggested fix: Wrap the Column's content in a scrollable (e.g. replace Center with a ListView/SingleChildScrollView, or use wear-friendly rotary-scrollable list) inside the SafeArea.

### 18. [HIGH] lib/screens/wear/workout_screen.dart:39

- Trigger: Opening the workout screen in interactive mode on a 192-227dp round Wear OS face (e.g., Galaxy Watch 4/5 40mm)
- Why: Interactive mode stacks a 36sp duration text (~42dp) + 20dp gap + stat row (icon 24 + 18sp value + 10sp label, ~67dp) + 24dp gap + a fixed 120x120dp circular button = ~273dp of fixed content in a non-scrollable Column. After the 20dp Container padding, a 192-227dp round face leaves only ~152-187dp, so the Column overflows vertically by ~85-120dp in normal (non-ambient) mode.
- Suggested fix: Wrap the interactive-mode Column in a SingleChildScrollView (like WearDashboard does) or shrink/scale the layout (smaller button, FittedBox) to fit ~192dp round faces.

### 19. [HIGH] lib/screens/wear/relax_screen.dart:90

- Trigger: Opening the relax screen in interactive mode on a small round Wear OS face (~192dp)
- Why: Interactive mode content is ~228dp tall (24sp title ~28dp + 32 gap + fixed 100dp button + 24 gap + 14sp label ~20dp + 8 gap + 12sp timer ~16dp) inside a non-scrollable Column whose available height after the isRound 20dp padding is only ~152dp on a 192dp round face. RenderFlex overflows vertically by ~70dp every time the screen is shown awake.
- Suggested fix: Wrap the Column in a SingleChildScrollView (or shrink the button to ~72dp and cut the 32/24 gaps to ~12/10) so interactive content fits 192dp round faces.

### 20. [MEDIUM] lib/screens/wellness/wellness_tracker_page.dart:251

- Trigger: Monitoring init throws (e.g., sensor/platform exception with a long message) on a small phone, in landscape (~360dp tall body), or at 1.3x font scale
- Why: The error state is a fixed Column with no scroll view: 104dp icon circle, title, the unbounded '_errorMessage' (contains a raw exception string that can wrap to many lines), a troubleshooting card (~150dp), and a button row — ~460dp+ of content plus 64dp vertical padding. Column height is bounded by the body, so long exception text, landscape, or large font scale produces a vertical RenderFlex overflow.
- Suggested fix: Wrap the error-state Column in a SingleChildScrollView (e.g. Center > SingleChildScrollView > Padding > Column), matching the pattern already used for the normal state at line 371.

### 21. [MEDIUM] lib/screens/wellness/wellness_tracker_page.dart:327

- Trigger: Error state shown on a 360dp-wide phone with 1.3x accessibility font scale
- Why: Two buttons with fixed 24dp horizontal padding each and a 12dp gap sit in a plain Row with no Flexible/Wrap. Available width is only ~296dp (360dp minus the EdgeInsets.all(32)). At 1.3x text scale 'Retry Connection' (~200dp incl. padding) + 'Go Back' (~115dp) + 12dp gap ≈ 330dp, exceeding 296dp and overflowing the Row horizontally.
- Suggested fix: Replace the Row with Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, ...) or wrap each button in Flexible so labels can shrink at large font scales.

### 22. [MEDIUM] lib/screens/auth/welcome_screen.dart:80

- Trigger: Landscape orientation on a typical phone, or a small (~640dp tall) phone at 1.3x font scale
- Why: The screen Column has no scroll view. The Expanded hero and Spacer can shrink to zero, but the remaining fixed content — headlineLarge title, 2-4 line body paragraph, 56dp button, login-link Wrap, footer row, and ~160dp of fixed SizedBox spacing — totals ~420-480dp at 1.3x font scale, which exceeds the ~360dp viewport height in landscape and tight portrait heights on small phones, causing a vertical RenderFlex overflow.
- Suggested fix: Wrap the Column in LayoutBuilder + SingleChildScrollView + ConstrainedBox(minHeight: constraints.maxHeight) + IntrinsicHeight so it scrolls when the viewport is shorter than the fixed content.

### 23. [HIGH] lib/widgets/mood_transformation_card.dart:53

- Trigger: 360dp-wide phone with system font scale >= ~1.15 (guaranteed at the 1.3x accessibility setting) on any workout summary screen with mood data
- Why: The title Row places an unbounded-width Text ('Mood Transformation', titleLarge/22sp bold) plus an 8px gap and a 24sp emoji with no Expanded/Flexible/FittedBox and no ellipsis. The card is used in walking/running/resistance summary screens inside SingleChildScrollView(padding: 20) and adds its own 24px padding per side, leaving ~272px of content width on a 360dp phone. At 1.0x the row measures ~260px (barely fits); any font scaling pushes it past the constraint and Row throws 'RenderFlex overflowed on the right'.
- Suggested fix: Wrap the title Text in Flexible(child: Text(..., maxLines: 1, overflow: TextOverflow.ellipsis)) or wrap the whole title Row in a FittedBox(fit: BoxFit.scaleDown).

### 24. [MEDIUM] lib/widgets/wellness/wellness_map_widget.dart:591

- Trigger: Stress state shows the route panel on a phone at 1.3x font scale; 'Medium Walk' card with a 100% green-space badge exceeds the fixed 200px card width
- Why: _buildRouteCard is a fixed 200px-wide card (minus 24px padding and 4px border = ~172px content). The spaceBetween Row puts the route-name Text and the green-space badge side by side with no Flexible/ellipsis on either. With the real data ('Medium Walk' at 14sp w600 plus a '100% 🌳' padded badge) the intrinsic widths sum to ~170-185px at 1.3x scale, exceeding 172px and producing a RenderFlex right-overflow inside every route card. Any longer route name added later overflows even at 1.0x.
- Suggested fix: Wrap the route-name Text in Expanded with overflow: TextOverflow.ellipsis (and optionally maxLines: 1) inside the Row at line 591 of lib/widgets/wellness/wellness_map_widget.dart.

### 25. [HIGH] lib/features/activity_classifier/presentation/tracker_page.dart:550

- Trigger: 360dp-wide phone at 1.1x-1.3x system font scale (or any phone narrower than ~345dp at 1.0x) with the default Simulation heart-rate source selected
- Why: Row contains two unbounded-width Texts plus a Switch with no Expanded/Flexible/ellipsis anywhere. The parent SingleChildScrollView only scrolls vertically, so horizontal space is capped at screen width minus 32px page padding. At 1.0 scale the content (~200px text + 12px + ~110px column) is already within ~15px of the 328px budget on a 360dp phone; any font scale above ~1.05 pushes it past, producing 'RenderFlex overflowed on the right'. This is the default branch shown on first open (BpmSource.simulation is the initial source).
- Suggested fix: Wrap the first Text in Flexible with overflow: TextOverflow.ellipsis (or replace the Row with a Wrap) so the label yields width to the switch column.

### 26. [HIGH] lib/features/activity_classifier/presentation/tracker_page.dart:956

- Trigger: 360dp-wide phone while the watch listener is starting ('Starting listener...') at 1.0x scale, or 'Listener inactive'/'Not connected' states at 1.2-1.3x font scale
- Why: The always-visible watch banner Row has no Flexible/Expanded/ellipsis on either Text. Effective width on a 360dp phone is 296px (screen - 32px page padding - 32px container padding). With label 'Starting listener...' (~170px at 18px bold) plus icon(18) + gaps(24) + 'Galaxy Watch: ' (~110px) the row is ~320px and overflows even at 1.0 font scale; 'Listener inactive' and 3-digit BPM values overflow at 1.3x. The banner renders unconditionally at the top of the page (line 478).
- Suggested fix: Wrap the label Text in Flexible with overflow: TextOverflow.ellipsis (or wrap the Row content in a FittedBox with fit: BoxFit.scaleDown).

### 27. [HIGH] lib/features/wellness/presentation/widgets/mission_bottom_sheet.dart:312

- Trigger: Any 360dp phone: drag the missions sheet down to its minimum (12% of screen height); or open in landscape at 1.3x font scale where even 28% is too short
- Why: The sheet's Column (line 329) stacks a fixed, non-scrollable header (drag handle + 'Missions' titleLarge + count subtitle + filter/Add buttons; on <420dp-wide phones the LayoutBuilder branch at line 379 stacks title above the button row, making the header ~130px tall) before the Expanded list. When the user drags the sheet to minChildSize 0.12 (~85-100px on a typical phone), the fixed header alone exceeds the sheet height, and Expanded cannot shrink below zero, so the Column throws 'RenderFlex overflowed by N pixels on the bottom' on every frame while collapsed. Worse at 1.3x font scale (initialChildSize 0.28 can also overflow in landscape).
- Suggested fix: Wrap the header (drag handle + title + actions) and list in a CustomScrollView/ListView driven by the sheet's controller (header as SliverToBoxAdapter), or raise minChildSize and clip via ClipRect with a Flexible header.

### 28. [MEDIUM] lib/features/yolo_camera/presentation/screens/yolo_debug_screen.dart:106

- Trigger: Any common phone (640x360dp) rotated to landscape; also portrait on very short screens combined with 1.3x font scale
- Why: The body Column combines two fixed-height blocks with one Expanded camera view and no scroll wrapper. _buildControlPanel is ~215px at 1.0 scale (two bold 16px headers, a status card, and a SegmentedButton with 16px padding all around) and grows to ~260px at 1.3x; _buildResultsPanel is a hard 120px. In landscape on a common 640x360dp phone the body height is ~280dp (360 - 56 AppBar - insets), which is less than the ~335-380px of fixed children, so even with the Expanded collapsed to 0 the Column overflows the bottom.
- Suggested fix: Wrap the control panel + results panel in a scrollable (e.g. make the whole body a CustomScrollView, or wrap _buildControlPanel in SingleChildScrollView with the camera given a minimum height via LayoutBuilder), or replace the fixed 120px results panel with a Flexible child in landscape.

### 29. [MEDIUM] lib/features/yolo_camera/presentation/screens/yolo_debug_screen.dart:321

- Trigger: Phone at 1.3x font scale with at least one YOLO detection displayed in the debug results strip
- Why: The results panel has a hard-coded 120px height (88px inner after 16px padding). The header row and the per-chip Column (bold label at ~14px + 12px confidence text + 12px vertical padding) are sized for 1.0 font scale, where they fit with ~10px slack. At 1.3x scale the header grows to ~28px and each chip's two text lines plus padding need ~58px while the Expanded region provides only ~52px, so each detection chip's inner Column overflows its bottom. Long model labels are unclipped horizontally too, but the vertical overflow triggers first.
- Suggested fix: Wrap the results panel content in a FittedBox/scaled layout or replace height:120 with a height derived from MediaQuery.textScalerOf(context) (e.g. scale the 120 by the text scale factor), and set mainAxisAlignment/ellipsis on the chip texts.

## Low-severity notes

- lib/screens/onboarding/buddy_hatch_screen.dart:73 - Non-scrollable Column (default mainAxisSize.max inside Center) with a fixed 180dp buddy widget, 48dp spacer, headline (~36dp, ~47dp at 1.3x), 16dp spacer, and a 48px emoji — ~390dp of fixed content. In landscape the Safe
- lib/screens/profile/buddy_customization_screen.dart:421 - Fixed 80x88 tile (74x82 usable after the 3px border) holds a Column whose children scale with text size: the emoji (fontSize 32 -> ~49px line at 1.3x) plus the label. Labels like 'Sunglasses' at 13px effective width ~78p
- lib/screens/profile/goals/nutrition_goals_screen.dart:194 - The label Text has no Flexible wrapper and shares the Row with a fixed ~60dp Switch. Available width is ~288dp on a 360dp phone (20 screen padding + 16 container padding per side). The label is safe at 1.0-1.3x but at la
- lib/screens/font_demo_screen.dart:15 - A non-scrollable Column stacks ~10 text blocks including displayLarge (~66dp), several styled samples, and two long paragraphs that wrap to 3-5 lines each — ~450dp at 1.0x and ~580dp at 1.3x, under an AppBar. Exceeds bod
- lib/screens/splash_screen.dart:140 - Fixed content (120dp logo + displayMedium 'FlowFit' + startup-error text wrapping to 2-3 lines + 'Try Again' button + 48dp bottom padding + spacers ≈ 380-400dp at 1.3x scale) exceeds the ~360dp landscape viewport once th
- lib/widgets/wellness/wellness_debug_panel.dart:36 - The expanded panel is a non-scrollable Column roughly 450-500dp tall (header, state readout, mock buttons, two labelled Sliders, scenario Wrap) anchored with only `bottom: 80` inside the wellness page Stack. The Position
- lib/widgets/wellness/wellness_state_card.dart:145 - Inside _buildMetric the icon+label Row has no Flexible/ellipsis on the label Text. Each metric tile is an Expanded half of the card row: on a 320dp phone the tile content width is ~92px (screen padding 16, card padding 2
