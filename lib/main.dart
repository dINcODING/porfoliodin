import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const PortfolioApp());
}

Future<void> _openUri(BuildContext context, Uri uri) async {
  final opened = await launchUrl(uri);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Unable to open this link.')));
  }
}

const ink = Color(0xFF151515);
const blue = Color(0xFF246BFD);
const paper = Color(0xFFF3F3F1);
const basePitch = -8 * math.pi / 180;
// Flutter's Y-axis transform direction is opposite CSS's screen-space
// convention; -12° produces the requested visible right-hand plane.
const baseYaw = -12 * math.pi / 180;

Color _monoInk(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFEAEAEA)
    : ink;

Color _monoMuted(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF99999C)
    : const Color(0xFF666663);

Color _monoFaint(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF555558)
    : const Color(0xFFAAAAA7);

Color _monoBorder(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF222226)
    : const Color(0xFFDDDDD9);

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nuruddin — Software Engineer',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(seedColor: blue, surface: paper),
        fontFamily: 'Helvetica Neue',
        textTheme: const TextTheme(bodyMedium: TextStyle(color: ink)),
      ),
      home: const CubePortfolio(),
    );
  }
}

enum CubeFace { home, projects, caseStudy, skills, about, contact }

extension FaceData on CubeFace {
  String get label => switch (this) {
    CubeFace.home => 'HOME',
    CubeFace.projects => 'PROJECTS',
    CubeFace.caseStudy => 'EXPERIENCE',
    CubeFace.skills => 'SKILLS',
    CubeFace.about => 'ABOUT',
    CubeFace.contact => 'CONTACT',
  };
  (double, double) get angle => switch (this) {
    CubeFace.home => (0, 0),
    CubeFace.projects => (0, -math.pi / 2),
    CubeFace.caseStudy => (0, math.pi),
    CubeFace.skills => (0, math.pi / 2),
    CubeFace.about => (-math.pi / 2, 0),
    CubeFace.contact => (math.pi / 2, 0),
  };
}

class CubePortfolio extends StatefulWidget {
  const CubePortfolio({super.key});
  @override
  State<CubePortfolio> createState() => _CubePortfolioState();
}

class _CubePortfolioState extends State<CubePortfolio>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _navController;
  late final AnimationController _completionController;
  late final AnimationController _revealController;
  final ScrollController _pageScroll = ScrollController(
    keepScrollOffset: false,
  );
  CubeFace _active = CubeFace.home;
  CubeFace _outgoing = CubeFace.home;
  double _scrollProgress = 0;
  double _pageOffset = 0;
  final Set<CubeFace> _visitedFaces = {CubeFace.home};
  bool _discoveryComplete = false;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..addListener(() => setState(() {}));
    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addListener(() => setState(() {}));
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..addListener(() => setState(() {}));
    _pageScroll.addListener(_updateScrollProgress);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final face = _faceForPath(Uri.base.path);
      if (face != CubeFace.home) _navigate(face, updateUrl: false);
    });
  }

  @override
  void dispose() {
    _navController.dispose();
    _completionController.dispose();
    _revealController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _pageScroll
      ..removeListener(_updateScrollProgress)
      ..dispose();
    super.dispose();
  }

  void _navigate(CubeFace face, {bool updateUrl = true}) {
    if (face == _active || _navController.isAnimating) return;
    setState(() {
      _outgoing = _active;
      _active = face;
      _scrollProgress = 0;
      _pageOffset = 0;
      _visitedFaces.add(face);
    });
    final path = switch (face) {
      CubeFace.home => '/',
      CubeFace.projects => '/project',
      CubeFace.caseStudy => '/experience',
      CubeFace.skills => '/skills',
      CubeFace.about => '/about',
      CubeFace.contact => '/contact',
    };
    if (updateUrl) {
      SystemNavigator.routeInformationUpdated(uri: Uri(path: path));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageScroll.hasClients) _pageScroll.jumpTo(0);
    });
    _navController.forward(from: 0).then((_) => _completeDiscoveryIfReady());
  }

  Future<void> _completeDiscoveryIfReady() async {
    if (!mounted ||
        _discoveryComplete ||
        _visitedFaces.length != CubeFace.values.length) {
      return;
    }
    setState(() => _discoveryComplete = true);
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _completionController.forward(from: 0);
      await _revealController.animateTo(.76, curve: Curves.easeInCubic);
      if (mounted) setState(() => _darkMode = true);
      await _revealController.animateTo(1, curve: Curves.easeOut);
    } else {
      _completionController.value = 1;
      _revealController.value = 1;
      if (mounted) setState(() => _darkMode = true);
    }
  }

  void _toggleTheme() => setState(() => _darkMode = !_darkMode);

  CubeFace _faceForPath(String path) => switch (path) {
    '/project' => CubeFace.projects,
    '/work' || '/experience' => CubeFace.caseStudy,
    '/skills' => CubeFace.skills,
    '/about' => CubeFace.about,
    '/contact' => CubeFace.contact,
    _ => CubeFace.home,
  };

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    _navigate(_faceForPath(routeInformation.uri.path), updateUrl: false);
    return true;
  }

  void _updateScrollProgress() {
    if (!_pageScroll.hasClients) return;
    final max = _pageScroll.position.maxScrollExtent;
    setState(() {
      _pageOffset = _pageScroll.position.pixels;
      _scrollProgress = max <= 0 ? 0 : (_pageOffset / max).clamp(0, 1);
    });
  }

  void _seekPage(double progress) {
    if (!_pageScroll.hasClients || _navController.isAnimating) return;
    final position = _pageScroll.position;
    final target = position.maxScrollExtent * progress.clamp(0.0, 1.0);
    _pageScroll.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final background = _darkMode ? Colors.black : Colors.white;
    final surface = _darkMode ? Colors.black : Colors.white;
    final foreground = _darkMode ? const Color(0xFFEAEAEA) : ink;
    final generatedScheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: _darkMode ? Brightness.dark : Brightness.light,
    );
    final scheme = generatedScheme.copyWith(
      surface: surface,
      onSurface: foreground,
      onSurfaceVariant: _darkMode
          ? const Color(0xFF99999C)
          : const Color(0xFF666663),
      outline: _darkMode ? const Color(0xFF77777B) : const Color(0xFF888884),
      outlineVariant: _darkMode
          ? const Color(0xFF222226)
          : const Color(0xFFDDDDD9),
      surfaceContainerLowest: _darkMode ? Colors.black : Colors.white,
      surfaceContainerLow: _darkMode
          ? const Color(0xFF050507)
          : const Color(0xFFFAFAF8),
      surfaceContainer: _darkMode
          ? const Color(0xFF0D0D10)
          : const Color(0xFFF2F2EF),
      surfaceContainerHigh: _darkMode
          ? const Color(0xFF151518)
          : const Color(0xFFEAEAE7),
      surfaceContainerHighest: _darkMode
          ? const Color(0xFF222226)
          : const Color(0xFFDDDDD9),
    );
    return Theme(
      data:
          (_darkMode
                  ? ThemeData.dark(useMaterial3: true)
                  : ThemeData.light(useMaterial3: true))
              .copyWith(
                colorScheme: scheme,
                scaffoldBackgroundColor: background,
                textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: foreground,
                  displayColor: foreground,
                ),
              ),
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, c) {
            final mobile = c.maxWidth < 900;
            final progress = MediaQuery.disableAnimationsOf(context)
                ? 1.0
                : Curves.easeInOutCubicEmphasized.transform(
                    _navController.value,
                  );
            return Stack(
              children: [
                ColoredBox(
                  color: background,
                  child: Column(
                    children: [
                      if (mobile)
                        SizedBox(
                          height: 58,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _monoInk(context),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(
                                    'N',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'NURUDDIN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                if (_discoveryComplete) ...[
                                  _ThemeToggle(
                                    dark: _darkMode,
                                    onChanged: _toggleTheme,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  '0${_active.index + 1}  ${_active.label}',
                                  style: _meta.copyWith(
                                    color: _monoMuted(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            mobile ? 16 : 32,
                            mobile ? 12 : 36,
                            mobile ? 16 : 32,
                            mobile ? 12 : 34,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      if (_darkMode) ...const [
                                        BoxShadow(
                                          color: Color(0x30FFFFFF),
                                          blurRadius: 5,
                                          spreadRadius: .4,
                                        ),
                                        BoxShadow(
                                          color: Color(0x20FFFFFF),
                                          blurRadius: 24,
                                          spreadRadius: 2,
                                        ),
                                        BoxShadow(
                                          color: Color(0x12FFFFFF),
                                          blurRadius: 64,
                                          spreadRadius: 8,
                                        ),
                                      ] else
                                        const BoxShadow(
                                          color: Color(0x10000000),
                                          blurRadius: 28,
                                          offset: Offset(0, 10),
                                        ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Row(
                                    children: [
                                      if (!mobile &&
                                          _active != CubeFace.projects)
                                        SizedBox(
                                          width: 108,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              28,
                                              24,
                                              12,
                                              38,
                                            ),
                                            child: _ProgressRail(
                                              active: _active,
                                              dark: _darkMode,
                                              progress: _scrollProgress,
                                              onChanged: _seekPage,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: ClipRect(
                                          child: LayoutBuilder(
                                            builder: (_, viewport) => _Cube(
                                              width: viewport.maxWidth,
                                              height: viewport.maxHeight,
                                              depth: 0,
                                              pitch: 0,
                                              yaw: 0,
                                              page: progress,
                                              transitionScale:
                                                  MediaQuery.disableAnimationsOf(
                                                    context,
                                                  )
                                                  ? 0
                                                  : 1,
                                              active: _active,
                                              dark: _darkMode,
                                              settled:
                                                  !_navController.isAnimating,
                                              fromFace: _outgoing,
                                              toFace: _active,
                                              scrollController: _pageScroll,
                                              scrollOffset: _pageOffset,
                                              onGo: _navigate,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!mobile) ...[
                                const SizedBox(width: 34),
                                SizedBox(
                                  width: 190,
                                  child: _RightRail(
                                    active: _active,
                                    visited: _visitedFaces,
                                    completion: _completionController.value,
                                    dark: _darkMode,
                                    showThemeToggle: _discoveryComplete,
                                    onToggleTheme: _toggleTheme,
                                    onGo: _navigate,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (mobile)
                        _MobileNavigation(
                          active: _active,
                          dark: _darkMode,
                          onGo: _navigate,
                        ),
                    ],
                  ),
                ),
                if (_revealController.value > 0 && _revealController.value < 1)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ThemeRevealPainter(
                          progress: _revealController.value,
                          mobile: mobile,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({
    required this.active,
    required this.dark,
    required this.onGo,
  });
  final CubeFace active;
  final bool dark;
  final ValueChanged<CubeFace> onGo;

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.home_outlined,
      Icons.grid_view_rounded,
      Icons.work_outline_rounded,
      Icons.code_rounded,
      Icons.person_outline_rounded,
      Icons.mail_outline_rounded,
    ];
    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: BoxDecoration(
          color: dark ? Colors.black : Colors.white,
          border: dark
              ? Border.all(color: const Color(0x38FFFFFF), width: .8)
              : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (dark) ...const [
              BoxShadow(
                color: Color(0x30FFFFFF),
                blurRadius: 5,
                spreadRadius: .3,
              ),
              BoxShadow(
                color: Color(0x20FFFFFF),
                blurRadius: 22,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Color(0x10FFFFFF),
                blurRadius: 46,
                spreadRadius: 5,
              ),
            ] else
              const BoxShadow(
                color: Color(0x14000000),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
          ],
        ),
        child: Row(
          children: List.generate(CubeFace.values.length, (index) {
            final face = CubeFace.values[index];
            final selected = face == active;
            final label = switch (face) {
              CubeFace.home => 'Home',
              CubeFace.projects => 'Projects',
              CubeFace.caseStudy => 'Experience',
              CubeFace.skills => 'Skills',
              CubeFace.about => 'About',
              CubeFace.contact => 'Contact',
            };
            return Expanded(
              child: Tooltip(
                message: label,
                child: Semantics(
                  label: label,
                  selected: selected,
                  button: true,
                  child: InkWell(
                    onTap: () => onGo(face),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        color: selected
                            ? (dark ? Colors.white : ink)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[index],
                            size: 18,
                            color: selected
                                ? (dark ? ink : Colors.white)
                                : (dark ? Colors.white : ink),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            label,
                            maxLines: 1,
                            style: TextStyle(
                              color: selected
                                  ? (dark ? ink : Colors.white)
                                  : (dark ? Colors.white : ink),
                              fontSize: 8,
                              height: 1,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ProgressRail extends StatelessWidget {
  const _ProgressRail({
    required this.active,
    required this.dark,
    required this.progress,
    required this.onChanged,
  });
  final CubeFace active;
  final bool dark;
  final double progress;
  final ValueChanged<double> onChanged;

  void _updateFromPosition(double y, double height) {
    const inset = 8.0;
    const thumbHeight = 54.0;
    final travel = math.max(1.0, height - inset * 2 - thumbHeight);
    onChanged(((y - inset - thumbHeight / 2) / travel).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '0${active.index + 1}',
        style: TextStyle(
          fontSize: 22,
          color: dark ? const Color(0xFFBFC0BD) : const Color(0xFF555A60),
        ),
      ),
      const SizedBox(height: 28),
      Expanded(
        child: LayoutBuilder(
          builder: (_, c) {
            const inset = 8.0;
            const thumbHeight = 54.0;
            final travel = math.max(1.0, c.maxHeight - inset * 2 - thumbHeight);
            return Semantics(
              label: 'Page scroll position',
              value: '${(progress * 100).round()}%',
              slider: true,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => _updateFromPosition(
                    details.localPosition.dy,
                    c.maxHeight,
                  ),
                  onVerticalDragStart: (details) => _updateFromPosition(
                    details.localPosition.dy,
                    c.maxHeight,
                  ),
                  onVerticalDragUpdate: (details) => _updateFromPosition(
                    details.localPosition.dy,
                    c.maxHeight,
                  ),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        top: inset,
                        bottom: inset,
                        child: Container(
                          width: 2,
                          color: dark ? Colors.white70 : ink,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: dark ? Colors.white : ink,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: dark ? Colors.white : ink,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: inset + travel * progress,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: Container(
                            width: 16,
                            height: thumbHeight,
                            decoration: BoxDecoration(
                              color: dark ? Colors.white : ink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _RightRail extends StatelessWidget {
  const _RightRail({
    required this.active,
    required this.visited,
    required this.completion,
    required this.dark,
    required this.showThemeToggle,
    required this.onToggleTheme,
    required this.onGo,
  });
  final CubeFace active;
  final Set<CubeFace> visited;
  final double completion;
  final bool dark, showThemeToggle;
  final VoidCallback onToggleTheme;
  final ValueChanged<CubeFace> onGo;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Center(
        child: _WireCube(
          active: active,
          visited: visited,
          completion: completion,
          dark: dark,
        ),
      ),
      if (showThemeToggle) ...[
        const SizedBox(height: 12),
        Center(
          child: _ThemeToggle(dark: dark, onChanged: onToggleTheme),
        ),
      ],
      const SizedBox(height: 22),
      ...CubeFace.values.map((face) {
        final selected = face == active;
        final label = switch (face) {
          CubeFace.home => 'Home',
          CubeFace.projects => 'Projects',
          CubeFace.caseStudy => 'Experience',
          CubeFace.skills => 'Skills',
          CubeFace.about => 'About',
          CubeFace.contact => 'Contact',
        };
        return Semantics(
          selected: selected,
          button: true,
          child: InkWell(
            onTap: () => onGo(face),
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: 8,
                    height: selected ? 38 : 0,
                    decoration: BoxDecoration(
                      color: selected
                          ? (dark
                                ? const Color(0xFF2F2F31)
                                : const Color(0xFFD0D0CE))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: dark
                            ? (selected
                                  ? Colors.white
                                  : const Color(0xFFBFC0BD))
                            : (selected ? ink : const Color(0xFF333333)),
                      ),
                    ),
                  ),
                  if (face == CubeFace.projects)
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: dark ? Colors.white : ink,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '6',
                        style: TextStyle(
                          color: dark ? Colors.black : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    ],
  );
}

class _WireCube extends StatelessWidget {
  const _WireCube({
    required this.active,
    required this.visited,
    required this.completion,
    required this.dark,
  });
  final CubeFace active;
  final Set<CubeFace> visited;
  final double completion;
  final bool dark;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Page position: ${active.label}',
    image: true,
    child: TweenAnimationBuilder<double>(
      tween: Tween(
        end:
            active.index.toDouble() +
            Curves.easeInOutCubic.transform(completion) * 8,
      ),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final x = value < 4 ? -24.0 : -24 + (value - 3) * 60;
        final y = 35 - math.min(value, 3) * 60;
        return SizedBox(
          width: 104,
          height: 104,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: dark && completion >= 1
                  ? const [
                      BoxShadow(
                        color: Color(0x28FFFFFF),
                        blurRadius: 28,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Color(0x12FFFFFF),
                        blurRadius: 58,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: CustomPaint(
              painter: _WireCubePainter(
                angleX: x * math.pi / 180,
                angleY: y * math.pi / 180,
                filledFaces: visited.length,
                completion: completion,
                dark: dark,
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _WireCubePainter extends CustomPainter {
  const _WireCubePainter({
    required this.angleX,
    required this.angleY,
    required this.filledFaces,
    required this.completion,
    required this.dark,
  });
  final double angleX, angleY;
  final int filledFaces;
  final double completion;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final completed = completion >= 1 || filledFaces == 6;
    final p = Paint()
      ..color = completed || dark ? Colors.white : ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeJoin = StrokeJoin.round;
    final cx = math.cos(angleX), sx = math.sin(angleX);
    final cy = math.cos(angleY), sy = math.sin(angleY);
    final points = <Offset>[];
    for (var i = 0; i < 8; i++) {
      final x = (i & 1) == 0 ? -1.0 : 1.0;
      final y = (i & 2) == 0 ? -1.0 : 1.0;
      final z = (i & 4) == 0 ? -1.0 : 1.0;
      final ry = y * cx - z * sx;
      final rz = y * sx + z * cx;
      final rx = x * cy + rz * sy;
      final depth = -x * sy + rz * cy;
      final perspective = 3.8 / (3.8 - depth);
      final scale = size.shortestSide * .27 * perspective;
      points.add(
        Offset(size.width / 2 + rx * scale, size.height / 2 + ry * scale),
      );
    }
    const edges = [
      (0, 1),
      (0, 2),
      (0, 4),
      (1, 3),
      (1, 5),
      (2, 3),
      (2, 6),
      (3, 7),
      (4, 5),
      (4, 6),
      (5, 7),
      (6, 7),
    ];
    const faces = [
      [0, 1, 3, 2],
      [4, 6, 7, 5],
      [0, 4, 5, 1],
      [2, 3, 7, 6],
      [0, 2, 6, 4],
      [1, 5, 7, 3],
    ];
    final fillCount = completion > 0 ? 6 : filledFaces.clamp(0, 6);
    for (var i = 0; i < fillCount; i++) {
      final path = Path()
        ..moveTo(points[faces[i][0]].dx, points[faces[i][0]].dy);
      for (var j = 1; j < 4; j++) {
        path.lineTo(points[faces[i][j]].dx, points[faces[i][j]].dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = ink.withValues(alpha: completion > 0 ? 1 : .14 + i * .035),
      );
    }
    for (final edge in edges) {
      canvas.drawLine(points[edge.$1], points[edge.$2], p);
    }
  }

  @override
  bool shouldRepaint(covariant _WireCubePainter oldDelegate) =>
      oldDelegate.angleX != angleX ||
      oldDelegate.angleY != angleY ||
      oldDelegate.filledFaces != filledFaces ||
      oldDelegate.completion != completion ||
      oldDelegate.dark != dark;
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.dark, required this.onChanged});
  final bool dark;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: dark ? 'Use light theme' : 'Use dark theme',
    onPressed: onChanged,
    icon: Icon(dark ? LucideIcons.sun : LucideIcons.moon, size: 18),
  );
}

class _ThemeRevealPainter extends CustomPainter {
  const _ThemeRevealPainter({required this.progress, required this.mobile});
  final double progress;
  final bool mobile;

  @override
  void paint(Canvas canvas, Size size) {
    // Desktop originates at the navigation cube. On mobile, where the cube is
    // not displayed, the equivalent origin is the top-right navigation area.
    final origin = mobile
        ? Offset(size.width - 42, 38)
        : Offset(size.width - 32 - 95, size.height / 2 - 185);
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    final maxRadius = corners
        .map((point) => (point - origin).distance)
        .reduce(math.max);
    final covering = (progress / .76).clamp(0.0, 1.0);
    final fade = progress <= .76
        ? 1.0
        : (1 - (progress - .76) / .24).clamp(0.0, 1.0);
    canvas.drawCircle(
      origin,
      maxRadius * Curves.easeInCubic.transform(covering),
      Paint()..color = Colors.black.withValues(alpha: fade),
    );
  }

  @override
  bool shouldRepaint(covariant _ThemeRevealPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.mobile != mobile;
}

class _Cube extends StatelessWidget {
  const _Cube({
    required this.width,
    required this.height,
    required this.depth,
    required this.pitch,
    required this.yaw,
    required this.page,
    required this.transitionScale,
    required this.active,
    required this.dark,
    required this.settled,
    required this.fromFace,
    required this.toFace,
    required this.scrollController,
    required this.scrollOffset,
    required this.onGo,
  });
  final double width, height, depth, pitch, yaw, page, transitionScale;
  final CubeFace active;
  final bool dark;
  final CubeFace fromFace, toFace;
  final ScrollController scrollController;
  final double scrollOffset;
  final bool settled;
  final ValueChanged<CubeFace> onGo;
  @override
  Widget build(BuildContext context) {
    final fromIndex = fromFace.index;
    final toIndex = toFace.index;
    final progress = page.clamp(0.0, 1.0);
    final vertical = fromIndex >= 3 || toIndex >= 4;
    final currentOpacity = progress <= .35
        ? 1.0
        : (1 - ((progress - .35) / .25)).clamp(.10, 1.0);
    final nextOpacity = progress <= .55
        ? (progress < .30 ? 0.0 : ((progress - .30) / .30 * .25))
        : (.25 + ((progress - .60) / .40) * .75).clamp(.25, 1.0);
    final verticalDirection = toIndex >= fromIndex ? -1.0 : 1.0;
    final halfDepth = vertical ? height / 2 : width / 2;
    final rotation = progress * math.pi / 2 * transitionScale;
    final compensation = 1 + math.sin(progress * math.pi) * .04;
    final parent = Matrix4.identity()
      ..setEntry(3, 2, 1 / 1600)
      ..translateByDouble(0, 0, -halfDepth, 1)
      ..scaleByDouble(compensation, compensation, compensation, 1);
    if (vertical) {
      parent.rotateX(verticalDirection * rotation);
    } else {
      parent.rotateY(-rotation);
    }
    final currentLocal = Matrix4.identity()
      ..translateByDouble(0, 0, halfDepth, 1);
    final nextLocal = Matrix4.identity();
    if (transitionScale == 0) {
      nextLocal.translateByDouble(0, 0, halfDepth, 1);
    } else if (vertical) {
      nextLocal
        ..translateByDouble(0, verticalDirection * halfDepth, 0, 1)
        ..rotateX(-verticalDirection * math.pi / 2 * transitionScale);
    } else {
      nextLocal
        ..translateByDouble(halfDepth, 0, 0, 1)
        ..rotateY(math.pi / 2 * transitionScale);
    }
    final currentPanel = _transitionPanel(
      face: fromFace,
      contentOpacity: currentOpacity,
      transform: parent.clone()..multiply(currentLocal),
    );
    final nextPanel = toIndex == fromIndex
        ? null
        : _transitionPanel(
            face: toFace,
            contentOpacity: nextOpacity,
            transform: parent.clone()..multiply(nextLocal),
          );
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: progress < .5
            ? [?nextPanel, currentPanel]
            : [currentPanel, ?nextPanel],
      ),
    );
  }

  Widget _transitionPanel({
    required CubeFace face,
    required double contentOpacity,
    required Matrix4 transform,
  }) {
    final isActive = face == active;
    final scroller = SingleChildScrollView(
      controller: isActive ? scrollController : null,
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          SizedBox(width: width, height: height, child: _content(face)),
          if (face != CubeFace.projects && face != CubeFace.skills)
            _PageContinuation(face: face, onGo: onGo),
        ],
      ),
    );
    return Transform(
      alignment: Alignment.center,
      transform: transform,
      child: IgnorePointer(
        ignoring: face != active || !settled,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: dark ? Colors.black : Colors.white),
          clipBehavior: Clip.antiAlias,
          child: Opacity(
            opacity: contentOpacity,
            child: isActive
                ? Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    thickness: 6,
                    radius: const Radius.circular(8),
                    child: scroller,
                  )
                : scroller,
          ),
        ),
      ),
    );
  }

  Widget _content(CubeFace face) => switch (face) {
    CubeFace.home => _HomeFace(
      onProjects: () => onGo(CubeFace.projects),
      onContact: () => onGo(CubeFace.contact),
    ),
    CubeFace.projects => _ProjectsFace(onContact: () => onGo(CubeFace.contact)),
    CubeFace.caseStudy => _CaseFace(
      onView: () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            height,
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
          );
        }
      },
    ),
    CubeFace.skills => _SkillsFace(
      animate: active == face && settled,
      scrollOffset: scrollOffset,
      viewportHeight: height,
      onProjects: () => onGo(CubeFace.projects),
      onContact: () => onGo(CubeFace.contact),
    ),
    CubeFace.about => const _AboutFace(),
    CubeFace.contact => const _ContactFace(),
  };
}

class _PageContinuation extends StatelessWidget {
  const _PageContinuation({required this.face, required this.onGo});
  final CubeFace face;
  final ValueChanged<CubeFace> onGo;

  List<(String, String, IconData)> get sections => switch (face) {
    CubeFace.home => const [
      (
        'A short introduction',
        'I turn practical ideas into dependable mobile and web products, from the first interaction sketch through production delivery.',
        Icons.waving_hand_outlined,
      ),
      (
        'Featured technologies',
        'Flutter and Dart for product interfaces, Firebase for dependable services, and native Android when the platform needs it.',
        Icons.layers_outlined,
      ),
      (
        'What I do',
        'Product engineering, interaction design, offline-first architecture, API integration, testing, and thoughtful release planning.',
        Icons.handyman_outlined,
      ),
      (
        'Featured projects',
        'Prayer learning, Quran publishing, financial operations, and digital reading experiences built around real user needs.',
        Icons.grid_view_rounded,
      ),
      (
        'Design philosophy',
        'Clarity before decoration. Every screen should explain itself, respond quickly, and respect the person using it.',
        Icons.auto_awesome_outlined,
      ),
      (
        'Selected tools',
        'Figma, VS Code, Android Studio, Git, Firebase Console, Postman, and a focused collection of testing tools.',
        Icons.build_outlined,
      ),
      (
        'How I collaborate',
        'Small releases, visible decisions, honest trade-offs, and regular feedback keep projects moving in the right direction.',
        Icons.groups_outlined,
      ),
      (
        'Let’s make something useful',
        'Have a product idea or an existing experience that needs care? I am open to thoughtful collaborations.',
        Icons.arrow_outward_rounded,
      ),
    ],
    CubeFace.projects => const [
      (
        'Project overview',
        'A collection of focused products spanning Islamic education, content management, accounting, and digital reading.',
        Icons.dashboard_outlined,
      ),
      (
        'Featured projects',
        'Mari Mendirikan Solat leads the collection, supported by TT Quran CMS, Accounting System, and Mushaf Restu.',
        Icons.star_outline_rounded,
      ),
      (
        'Product screenshots',
        'Each interface is designed around its real environment: small screens, intermittent networks, and repeated daily use.',
        Icons.devices_outlined,
      ),
      (
        'The problem',
        'Complex information and important routines often arrive through interfaces that feel passive, crowded, or difficult to trust.',
        Icons.help_outline_rounded,
      ),
      (
        'The solution',
        'Short activity loops, clear hierarchy, immediate feedback, and resilient offline behaviour make each product easier to use.',
        Icons.lightbulb_outline_rounded,
      ),
      (
        'Architecture',
        'Feature-based Flutter modules, explicit data boundaries, local persistence, and Firebase-backed synchronization.',
        Icons.account_tree_outlined,
      ),
      (
        'Technology stack',
        'Flutter, Dart, Firebase, REST APIs, SQLite, local notifications, analytics, and platform integrations.',
        Icons.data_object_rounded,
      ),
      (
        'Challenges',
        'Balancing rich content with fast startup, predictable offline states, accessibility, and maintainable delivery workflows.',
        Icons.route_outlined,
      ),
      (
        'Results',
        'Products that remain understandable, responsive, and useful across a wide range of devices and connection quality.',
        Icons.insights_outlined,
      ),
      (
        'Next project',
        'The next case study explores how structured Quran content moves safely from an editorial system into reader applications.',
        Icons.arrow_forward_rounded,
      ),
    ],
    CubeFace.caseStudy => const [
      (
        'Professional introduction',
        'Independent product work combines engineering execution with product thinking and careful interaction design.',
        Icons.badge_outlined,
      ),
      (
        'Experience timeline',
        '2021—2025: Android, digital products, and IT procurement. 2023—Now: software development and independent products.',
        Icons.timeline_rounded,
      ),
      (
        'Responsibilities',
        'Define product behaviour, shape architecture, build interfaces, connect services, test edge cases, and prepare releases.',
        Icons.checklist_rounded,
      ),
      (
        'Major achievements',
        'Delivered complete product flows, resilient content systems, offline features, and reusable foundations for future work.',
        Icons.emoji_events_outlined,
      ),
      (
        'Technologies used',
        'Flutter, Kotlin, Firebase, REST APIs, SQLite, Git, Figma, and modern Android tooling.',
        Icons.memory_outlined,
      ),
      (
        'Case highlights',
        'Learning interactions, editorial workflows, financial dashboards, and calm long-form reading experiences.',
        Icons.view_carousel_outlined,
      ),
      (
        'Lessons learned',
        'Good software comes from observing constraints early, reducing ambiguity, and making important states visible.',
        Icons.school_outlined,
      ),
      (
        'Working principles',
        'Own the outcome, communicate clearly, test the difficult paths, and leave the codebase easier to extend.',
        Icons.verified_outlined,
      ),
    ],
    CubeFace.skills => const [
      (
        'Frontend',
        'Responsive layouts, component systems, animation, accessibility, state management, and performance-conscious rendering.',
        Icons.web_outlined,
      ),
      (
        'Backend and data',
        'Firebase services, REST integration, structured storage, synchronization, validation, and reliable error handling.',
        Icons.storage_outlined,
      ),
      (
        'Mobile',
        'Flutter, Dart, Android, Kotlin, platform channels, notifications, permissions, and store-ready release workflows.',
        Icons.phone_android_outlined,
      ),
      (
        'Architecture',
        'Feature boundaries, repository patterns, offline-first data flows, dependency direction, and testable application state.',
        Icons.architecture_outlined,
      ),
      (
        'UI design',
        'Interaction design, prototyping, typography, hierarchy, responsive systems, and interfaces built for comprehension.',
        Icons.design_services_outlined,
      ),
      (
        'Tools',
        'Git, Figma, VS Code, Android Studio, Postman, Firebase Console, issue tracking, and automated analysis.',
        Icons.construction_outlined,
      ),
      (
        'Development workflow',
        'Explore, define, prototype, implement, test, measure, document, and release in small dependable increments.',
        Icons.sync_alt_rounded,
      ),
      (
        'Currently learning',
        'Deeper platform performance, advanced testing strategy, scalable backend design, and more inclusive product research.',
        Icons.menu_book_outlined,
      ),
    ],
    CubeFace.about => const [
      (
        'Introduction',
        'I am a software engineer who enjoys carrying an idea across product thinking, interface design, and implementation.',
        Icons.person_outline_rounded,
      ),
      (
        'Personal philosophy',
        'Useful products feel calm because difficult decisions were made carefully before they reached the user.',
        Icons.favorite_border_rounded,
      ),
      (
        'Development process',
        'Start with the real constraint, prototype the interaction, define the data flow, then build the smallest complete path.',
        Icons.hub_outlined,
      ),
      (
        'Product approach',
        'I look for the moment where confusion begins and redesign the experience around a clearer decision or response.',
        Icons.psychology_outlined,
      ),
      (
        'Education',
        'Continuous self-directed learning through real products, technical documentation, experiments, and deliberate review.',
        Icons.school_outlined,
      ),
      (
        'Experience',
        'Mobile development, web tooling, independent digital products, operational systems, and technology procurement.',
        Icons.work_outline_rounded,
      ),
      (
        'Goals',
        'Build products with lasting practical value and grow into increasingly thoughtful technical and product leadership.',
        Icons.flag_outlined,
      ),
      (
        'Interesting facts',
        'I enjoy systems with visible craft: typography, maps, physical products, thoughtful tools, and well-made interfaces.',
        Icons.interests_outlined,
      ),
    ],
    CubeFace.contact => const [
      (
        'Start a conversation',
        'Share the problem, the people it affects, and what a successful outcome should feel like.',
        Icons.chat_bubble_outline_rounded,
      ),
      (
        'Contact methods',
        'Email works best for project details. GitHub and LinkedIn are useful for code, background, and professional context.',
        Icons.alternate_email_rounded,
      ),
      (
        'Availability',
        'Available for selected product builds, focused feature work, interface improvements, and technical collaboration.',
        Icons.event_available_outlined,
      ),
      (
        'Preferred projects',
        'Mobile products, useful internal tools, learning experiences, content platforms, and offline-capable applications.',
        Icons.rocket_launch_outlined,
      ),
      (
        'Frequently asked',
        'Clear scope is helpful, but early ideas are welcome. We can shape priorities and a sensible first release together.',
        Icons.question_answer_outlined,
      ),
      (
        'Project information',
        'Useful first details include the audience, current pain point, target platform, timing, and existing materials.',
        Icons.description_outlined,
      ),
      (
        'Social links',
        'Explore implementation work on GitHub, professional updates on LinkedIn, or request a current résumé by email.',
        Icons.share_outlined,
      ),
      (
        'Final message',
        'If the idea is useful and the problem is real, I would be glad to hear about it.',
        Icons.mark_email_read_outlined,
      ),
    ],
  };

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: LayoutBuilder(
      builder: (_, outer) {
        final mobile = outer.maxWidth < 520;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            mobile ? 24 : 56,
            mobile ? 40 : 64,
            mobile ? 24 : 56,
            mobile ? 48 : 72,
          ),
          child: LayoutBuilder(
            builder: (_, constraints) {
              final compact = constraints.maxWidth < 760;
              final cardWidth = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 18) / 2;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MORE TO EXPLORE',
                    style: _meta.copyWith(color: const Color(0xFF37A5A2)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _continuationTitle(face),
                    style: TextStyle(
                      fontSize: compact ? 38 : 52,
                      height: 1.02,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: sections
                        .map(
                          (section) => SizedBox(
                            width: cardWidth,
                            child: _ContentBlock(
                              title: section.$1,
                              description: section.$2,
                              icon: section.$3,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 42),
                  const Divider(),
                  const SizedBox(height: 26),
                  InkWell(
                    onTap: () => onGo(CubeFace.contact),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_outward_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ready to discuss a thoughtful product?',
                              style: TextStyle(
                                fontSize: compact ? 17 : 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    ),
  );

  String _continuationTitle(CubeFace face) => switch (face) {
    CubeFace.home => 'Building useful products, end to end.',
    CubeFace.projects => 'Selected work and how it was built.',
    CubeFace.caseStudy => 'Experience shaped by real delivery.',
    CubeFace.skills => 'Capabilities connected by a clear process.',
    CubeFace.about => 'The thinking behind the work.',
    CubeFace.contact => 'A simple way to begin.',
  };
}

class _ContentBlock extends StatelessWidget {
  const _ContentBlock({
    required this.title,
    required this.description,
    required this.icon,
  });
  final String title, description;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 23, color: colors.onSurface),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceFrame extends StatelessWidget {
  const _FaceFrame({
    required this.number,
    required this.title,
    required this.child,
  });
  final String number, title;
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Padding(
      padding: EdgeInsets.all(
        constraints.maxWidth < 520 || constraints.maxHeight < 520 ? 24 : 56,
      ),
      child: child,
    ),
  );
}

const _meta = TextStyle(
  fontSize: 11,
  letterSpacing: 1.8,
  fontWeight: FontWeight.w800,
  color: Color(0xFF555A60),
);

class _HomeFace extends StatelessWidget {
  const _HomeFace({required this.onProjects, required this.onContact});
  final VoidCallback onProjects;
  final VoidCallback onContact;
  @override
  Widget build(BuildContext context) => _FaceFrame(
    number: '01',
    title: 'HOME',
    child: LayoutBuilder(
      builder: (_, c) {
        final compact = c.maxWidth < 650;
        final text = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FULLSTACK DEVELOPER',
              style: _meta.copyWith(
                color: const Color(0xFF37A5A2),
                fontSize: compact ? 13 : 16,
              ),
            ),
            SizedBox(height: compact ? 10 : 14),
            Text(
              'Nuruddin\nMahmud',
              style: TextStyle(
                fontSize: compact ? 46 : 88,
                height: .92,
                letterSpacing: compact ? -2.8 : -5,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: compact ? 8 : 12),
            Text(
              'Flutter   •   Android   •   Web   •   iOS',
              style: TextStyle(
                fontSize: compact ? 13 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: compact ? 6 : 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Text(
                'I build a useful software with careful engineering and human-centered interactions',
                style: TextStyle(
                  fontSize: compact ? 15 : 18,
                  height: compact ? 1.35 : 1.5,
                  color: const Color(0xFF666663),
                ),
              ),
            ),
            SizedBox(height: compact ? 8 : 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionButton(
                  label: 'View Projects',
                  dark: true,
                  onPressed: onProjects,
                ),
                _ActionButton(
                  label: 'Contact Me',
                  icon: Icons.mail_outline_rounded,
                  onPressed: onContact,
                ),
              ],
            ),
          ],
        );
        return compact
            ? Column(
                children: [
                  Expanded(child: text),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _Portrait(size: 82),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(flex: 6, child: text),
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: _Portrait(size: 420),
                      ),
                    ),
                  ),
                ],
              );
      },
    ),
  );
}

class _Portrait extends StatelessWidget {
  const _Portrait({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Image.asset(
      'assets/images/logoportfolio.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Nuruddin Mahmud logo',
    ),
  );
}

class _ProjectsFace extends StatefulWidget {
  const _ProjectsFace({required this.onContact});
  final VoidCallback onContact;
  @override
  State<_ProjectsFace> createState() => _ProjectsFaceState();
}

class _ProjectsFaceState extends State<_ProjectsFace> {
  int selected = 0;
  bool _showIntro = true;
  bool _scrolling = false;
  double _scrollDelta = 0;
  final ScrollController _projectsScroll = ScrollController();
  double _projectViewport = 1;
  final FocusNode _projectsFocus = FocusNode();
  Timer? _settleTimer;
  bool _magneticSettling = false;

  @override
  void initState() {
    super.initState();
    _projectsScroll.addListener(_trackProjectScroll);
  }

  @override
  void dispose() {
    _projectsScroll
      ..removeListener(_trackProjectScroll)
      ..dispose();
    _projectsFocus.dispose();
    _settleTimer?.cancel();
    super.dispose();
  }

  void _trackProjectScroll() {
    if (!_projectsScroll.hasClients) return;
    final page = (_projectsScroll.offset / _projectViewport).round();
    final intro = page == 0;
    final projectIndex = (page - 1).clamp(0, projects.length - 1);
    if (intro != _showIntro || (!intro && projectIndex != selected)) {
      setState(() {
        _showIntro = intro;
        if (!intro) selected = projectIndex;
      });
    }
  }

  void _scrollToProject(int index) {
    _scrollToPage(index + 1);
  }

  void _scrollToPage(int page) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _projectsScroll.animateTo(
      _projectViewport * page.clamp(0, projects.length + 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
    );
  }

  void _scheduleMagneticSettle() {
    if (_magneticSettling || !_projectsScroll.hasClients) return;
    _settleTimer?.cancel();
    _settleTimer = Timer(
      const Duration(milliseconds: 170),
      _settleToDominantSection,
    );
  }

  Future<void> _settleToDominantSection() async {
    if (!_projectsScroll.hasClients || _projectViewport <= 0) return;
    final rawPage = _projectsScroll.offset / _projectViewport;
    final targetPage = rawPage.round().clamp(0, projects.length + 1);
    final visibleShare = 1 - (rawPage - targetPage).abs();
    if (visibleShare < .60) return;
    final target = targetPage * _projectViewport;
    if ((_projectsScroll.offset - target).abs() < 1) return;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _magneticSettling = true;
    try {
      await _projectsScroll.animateTo(
        target,
        duration: reduced ? Duration.zero : const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _magneticSettling = false;
    }
  }

  void _cancelMagneticSettle() {
    _settleTimer?.cancel();
    if (_magneticSettling && _projectsScroll.hasClients) {
      _projectsScroll.jumpTo(_projectsScroll.offset);
      _magneticSettling = false;
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final page = (_projectsScroll.offset / _projectViewport).round();
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.pageDown) {
      _scrollToPage(page + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.pageUp) {
      _scrollToPage(page - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _scrollToPage(0);
      return KeyEventResult.handled;
    }
    final digit = int.tryParse(event.character ?? '');
    if (digit != null && digit >= 1 && digit <= projects.length) {
      _scrollToProject(digit - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _showProjectGallery(_ProjectData project) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xDD000000),
      builder: (_) => _ProjectGallery(project: project),
    );
  }

  void _showMobileProjectPicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 0, 22, 12),
                child: Text(
                  'Choose a project',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  itemCount: projects.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 2),
                  itemBuilder: (_, index) {
                    final project = projects[index];
                    final active = index == selected;
                    return ListTile(
                      minTileHeight: 70,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: CircleAvatar(
                        backgroundColor: active
                            ? project.accent
                            : Theme.of(context).colorScheme.surfaceContainer,
                        foregroundColor: active
                            ? Colors.white
                            : _monoInk(context),
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        project.name,
                        style: TextStyle(
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        project.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: active
                          ? Icon(LucideIcons.check, color: project.accent)
                          : const Icon(LucideIcons.chevronRight),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _scrollToProject(index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const projects = [
    _ProjectData(
      'Solatiy',
      'ISLAMIC EDUCATION APP',
      'A gamified Islamic learning app that helps users master salah through interactive lessons, guided practice, and rewarding daily progress.',
      [
        (
          'Structured Learning',
          'Master every prayer from Takbir to Salam.',
          LucideIcons.bookOpen,
        ),
        (
          'Gamified Experience',
          'Stay motivated with puzzles, rewards, and achievements.',
          LucideIcons.gamepad2,
        ),
        (
          'Audio Guidance',
          'Practice recitations with synchronized audio.',
          LucideIcons.volume2,
        ),
      ],
      [
        'Flutter',
        'Dart',
        'Firebase',
        'Firestore',
        'Firebase Storage',
        'Riverpod',
        'GoRouter',
        'Material 3',
      ],
      true,
    ),
    _ProjectData(
      'Tadabbur Tazakkur Quran',
      'QURAN LEARNING PLATFORM',
      'A comprehensive Quran platform combining digital Mushaf reading, word-by-word learning, tafsir, reflection, and a powerful content management system.',
      [
        (
          'Digital Mushaf',
          'Read the Quran in a clean, distraction-free interface.',
          LucideIcons.bookMarked,
        ),
        (
          'Word-by-Word Learning',
          'Study every verse with translations and explanations.',
          LucideIcons.searchCheck,
        ),
        (
          'Content Management',
          'Manage Quran content through a dedicated CMS.',
          LucideIcons.database,
        ),
      ],
      [
        'Flutter',
        'Flutter Web',
        'Dart',
        'Firebase',
        'Firestore',
        'FlutterFire',
        'REST API',
        'Material 3',
      ],
      true,
    ),
    _ProjectData(
      'HRMS',
      'HUMAN RESOURCE MANAGEMENT SYSTEM',
      'A web-based HR platform for managing employees, attendance, leave requests, payroll, and workforce administration.',
      [
        (
          'Employee Management',
          'Centralize employee information and records.',
          LucideIcons.users,
        ),
        (
          'Attendance Tracking',
          'Monitor attendance and working hours.',
          LucideIcons.clock3,
        ),
        (
          'Leave Management',
          'Simplify leave requests and approvals.',
          LucideIcons.fileCheck2,
        ),
      ],
      ['PHP 8', 'Laravel', 'Filament', 'Tailwind CSS', 'SQLite', 'REST API'],
      true,
    ),
    _ProjectData(
      'AZ Integrated',
      'RENOVATION COMPANY WEBSITE',
      'A premium renovation company website showcasing services, completed projects, and customer enquiry solutions.',
      [
        (
          'Project Portfolio',
          'Showcase completed renovation projects.',
          LucideIcons.house,
        ),
        (
          'Renovation Services',
          'Present renovation expertise professionally.',
          LucideIcons.hammer,
        ),
        (
          'Lead Generation',
          'Convert visitors into potential customers.',
          LucideIcons.send,
        ),
      ],
      [
        'Flutter',
        'Flutter Web',
        'Dart',
        'Responsive Design',
        'Progressive Web App (PWA)',
        'Git',
      ],
      false,
    ),
    _ProjectData(
      'nasyrulquran.com',
      'CORPORATE WEBSITE',
      'A responsive corporate website showcasing Islamic publications, educational programs, digital products, and company services.',
      [
        (
          'Corporate Branding',
          "Strengthen the company's online presence.",
          LucideIcons.building2,
        ),
        (
          'Content Showcase',
          'Present publications and educational initiatives.',
          LucideIcons.newspaper,
        ),
        (
          'Responsive Experience',
          'Optimize the website for desktop, tablet, and mobile devices.',
          LucideIcons.monitorSmartphone,
        ),
      ],
      ['Nicepage', 'HTML', 'CSS', 'JavaScript', 'PHP', 'Hostinger'],
      false,
    ),
    _ProjectData(
      'Super Segar',
      'CAR DETAILING WEBSITE',
      'A premium business website promoting professional car detailing, deep cleaning, and interior restoration services.',
      [
        (
          'Service Showcase',
          'Present detailing services with clarity.',
          LucideIcons.carFront,
        ),
        (
          'Transformation Gallery',
          'Showcase real before-and-after cleaning results.',
          LucideIcons.sparkles,
        ),
        (
          'Online Booking',
          'Enable quick enquiries and appointment booking.',
          LucideIcons.calendarPlus,
        ),
      ],
      [
        'Flutter',
        'Flutter Web',
        'Dart',
        'Material 3',
        'url_launcher',
        'Flutter Test',
      ],
      false,
    ),
  ];
  void _scrollProjects(double delta) {
    if (_scrolling) return;
    _scrollDelta += delta;
    if (_scrollDelta.abs() < 42) return;
    final direction = _scrollDelta > 0 ? 1 : -1;
    _scrollDelta = 0;
    final currentPage = _showIntro ? 0 : selected + 1;
    final nextPage = (currentPage + direction).clamp(0, projects.length);
    if (nextPage == currentPage) return;
    setState(() {
      _showIntro = nextPage == 0;
      if (!_showIntro) selected = nextPage - 1;
      _scrolling = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted) _scrolling = false;
    });
  }

  void _selectProject(int value) {
    if (!_showIntro && value == selected) return;
    setState(() {
      _showIntro = false;
      selected = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        _projectViewport = constraints.maxHeight;
        final compact = constraints.maxWidth < 680;
        return Focus(
          autofocus: true,
          focusNode: _projectsFocus,
          onKeyEvent: _handleKey,
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification &&
                      notification.dragDetails != null) {
                    _cancelMagneticSettle();
                  } else if (notification is ScrollEndNotification) {
                    _scheduleMagneticSettle();
                  }
                  return false;
                },
                child: Listener(
                  onPointerDown: (_) => _cancelMagneticSettle(),
                  onPointerSignal: (_) {
                    _settleTimer?.cancel();
                  },
                  child: Scrollbar(
                    controller: _projectsScroll,
                    thumbVisibility: false,
                    child: ListView.builder(
                      controller: _projectsScroll,
                      physics: const ClampingScrollPhysics(),
                      addRepaintBoundaries: false,
                      itemCount: projects.length + 2,
                      itemExtent: constraints.maxHeight,
                      itemBuilder: (_, page) {
                        if (page == 0) {
                          return _ProjectsIntro(
                            onContinue: () => _scrollToProject(0),
                          );
                        }
                        if (page == projects.length + 1) {
                          return _ProjectsContact(onContact: widget.onContact);
                        }
                        return _ContinuousProjectSection(
                          index: page - 1,
                          project: projects[page - 1],
                          compact: compact,
                          onPrevious: () => _scrollToPage(page - 1),
                          onNext: () => _scrollToPage(page + 1),
                          onPreview: () =>
                              _showProjectGallery(projects[page - 1]),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (!compact)
                Positioned(
                  left: 56,
                  top: 56,
                  bottom: 56,
                  width: 64,
                  child: AnimatedOpacity(
                    opacity: _showIntro ? 0 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: IgnorePointer(
                      ignoring: _showIntro,
                      child: _ProjectSelector(
                        selected: selected,
                        count: projects.length,
                        names: projects.map((project) => project.name).toList(),
                        activeColor: projects[selected].accent,
                        onSelected: _scrollToProject,
                      ),
                    ),
                  ),
                ),
              if (!compact && !_showIntro)
                Positioned(
                  left: 132,
                  top: 34,
                  child: Text(
                    '${(selected + 1).toString().padLeft(2, '0')} / 06 — ${projects[selected].name}',
                    style: _meta.copyWith(color: _monoMuted(context)),
                  ),
                ),
              if (compact && !_showIntro)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: _MobileProjectHeader(
                    selected: selected,
                    project: projects[selected],
                  ),
                ),
              if (compact && !_showIntro)
                Positioned(
                  right: 16,
                  bottom: 112,
                  child: RepaintBoundary(
                    child: _FloatingProjectNavigation(
                      selected: selected,
                      accent: projects[selected].accent,
                      onTap: _showMobileProjectPicker,
                      onPrevious: selected == 0
                          ? null
                          : () => _scrollToProject(selected - 1),
                      onNext: selected == projects.length - 1
                          ? null
                          : () => _scrollToProject(selected + 1),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Kept temporarily as a layout fallback while the continuous version settles.
  // ignore: unused_element
  Widget _legacyBuild(BuildContext context) => Listener(
    behavior: HitTestBehavior.opaque,
    onPointerSignal: (event) {
      if (event is PointerScrollEvent) _scrollProjects(event.scrollDelta.dy);
    },
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 120) _scrollProjects(-velocity);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0, .015),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_showIntro ? -1 : selected),
          child: _showIntro
              ? _ProjectsIntro(onContinue: () => _scrollProjects(100))
              : _FaceFrame(
                  number: '02',
                  title: 'PROJECTS',
                  child: LayoutBuilder(
                    builder: (_, c) {
                      final compact = c.maxWidth < 680;
                      final project = projects[selected];
                      final copy = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '0${selected + 1}',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Color(0xFFCACAC8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            project.name,
                            style: TextStyle(
                              fontSize: compact ? 29 : 31,
                              height: 1.05,
                              letterSpacing: -.8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            project.category,
                            style: _meta.copyWith(
                              color: const Color(0xFF299FA4),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            project.description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.45,
                              color: Color(0xFF666663),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: project.tools
                                .map((tool) => _Badge(tool))
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          _ProjectActions(project: project),
                        ],
                      );
                      final projectBody = Expanded(
                        child: compact
                            ? Column(
                                children: [
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.topLeft,
                                      child: SizedBox(
                                        width: c.maxWidth,
                                        child: copy,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 135,
                                    child: _ProjectVisual(
                                      project: project,
                                      compact: true,
                                      onTap: () {},
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  SizedBox(width: 310, child: copy),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _ProjectShowcase(
                                      project: project,
                                      onPreview: () {},
                                    ),
                                  ),
                                ],
                              ),
                      );
                      if (!compact) {
                        return Row(
                          children: [
                            SizedBox(
                              width: 64,
                              child: _ProjectSelector(
                                selected: selected,
                                count: projects.length,
                                names: projects
                                    .map((project) => project.name)
                                    .toList(),
                                onSelected: _selectProject,
                              ),
                            ),
                            const SizedBox(width: 34),
                            Expanded(child: Column(children: [projectBody])),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          projectBody,
                          Row(
                            children: List.generate(
                              projects.length,
                              (i) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () => _selectProject(i),
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i == selected ? ink : Colors.white,
                                      border: Border.all(color: ink),
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: i == selected
                                            ? Colors.white
                                            : ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ),
    ),
  );
}

class _ProjectData {
  const _ProjectData(
    this.name,
    this.category,
    this.description,
    this.highlights,
    this.tools,
    this.phone,
  );
  final String name, category, description;
  final List<(String, String, IconData)> highlights;
  final List<String> tools;
  final bool phone;
  Uri? get liveUrl => name == 'Super Segar'
      ? Uri.parse('https://dincoding.github.io/super-segar/')
      : null;
  Uri? get sourceUrl => name == 'Super Segar'
      ? Uri.parse('https://github.com/dINcODING/super-segar')
      : null;
  Color get accent => switch (name) {
    'Solatiy' => const Color(0xFF486455),
    'Tadabbur Tazakkur Quran' => const Color(0xFF8A683E),
    'HRMS' => const Color(0xFF486D91),
    'AZ Integrated' => const Color(0xFF9A624C),
    'nasyrulquran.com' => const Color(0xFF477B72),
    _ => const Color(0xFF7C566A),
  };
  String? get screenshot => switch (name) {
    'Solatiy' => 'assets/images/solatiy-home.png',
    'Tadabbur Tazakkur Quran' => 'assets/images/tadabbur-mushaf.png',
    'HRMS' => 'assets/images/hrms-employee.png',
    'AZ Integrated' => 'assets/images/az-integrated-home.png',
    'nasyrulquran.com' => 'assets/images/nasyrulquran-home.png',
    'Super Segar' => 'assets/images/super-segar-home.png',
    _ => null,
  };
  String? get secondaryScreenshot => switch (name) {
    'Solatiy' => 'assets/images/solatiy-puzzle.png',
    'Tadabbur Tazakkur Quran' => 'assets/images/tadabbur-reflection.png',
    'HRMS' => 'assets/images/hrms-admin.png',
    'AZ Integrated' => 'assets/images/az-integrated-mobile.png',
    'nasyrulquran.com' => 'assets/images/nasyrulquran-mobile.png',
    'Super Segar' => 'assets/images/super-segar-mobile.png',
    _ => null,
  };
}

class _ProjectActions extends StatelessWidget {
  const _ProjectActions({required this.project});
  final _ProjectData project;

  @override
  Widget build(BuildContext context) {
    final liveUrl = project.liveUrl;
    final sourceUrl = project.sourceUrl;
    if (liveUrl == null || sourceUrl == null) {
      return Text(
        'CASE STUDY COMING SOON',
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: _monoFaint(context),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => _openUri(context, liveUrl),
          icon: const Icon(LucideIcons.externalLink, size: 15),
          label: const Text('View Live Project'),
          style: FilledButton.styleFrom(backgroundColor: project.accent),
        ),
        OutlinedButton.icon(
          onPressed: () => _openUri(context, sourceUrl),
          icon: const Icon(LucideIcons.code2, size: 15),
          label: const Text('View Source Code'),
        ),
      ],
    );
  }
}

class _ContinuousProjectSection extends StatelessWidget {
  const _ContinuousProjectSection({
    required this.index,
    required this.project,
    required this.compact,
    required this.onPrevious,
    required this.onNext,
    required this.onPreview,
  });
  final int index;
  final _ProjectData project;
  final bool compact;
  final VoidCallback onPrevious, onNext, onPreview;

  @override
  Widget build(BuildContext context) {
    final copy = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text(
            '0${index + 1}',
            style: TextStyle(
              fontSize: 20,
              color: _monoFaint(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          project.name,
          style: TextStyle(
            fontSize: compact ? 29 : 31,
            height: 1.05,
            letterSpacing: -.8,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          project.category,
          style: _meta.copyWith(color: project.accent, fontSize: 12),
        ),
        const SizedBox(height: 10),
        _PlatformAvailability(project: project),
        const SizedBox(height: 28),
        Text(
          project.description,
          maxLines: compact ? 2 : null,
          overflow: compact ? TextOverflow.ellipsis : null,
          style: TextStyle(
            fontSize: 16,
            height: 1.45,
            color: _monoMuted(context),
          ),
        ),
        SizedBox(height: compact ? 14 : 18),
        if (!compact) ...[
          Text(
            'DESIGN  •  DEVELOPMENT  •  DELIVERY',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: _monoMuted(context),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (!compact) _ToolSummary(tools: project.tools),
        if (!compact) ...[
          const SizedBox(height: 12),
          _ProjectActions(project: project),
        ],
      ],
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 28 : 154,
        compact ? 70 : 56,
        compact ? 28 : 56,
        compact ? 92 : 56,
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 31,
                    height: 1.05,
                    letterSpacing: -.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  project.category,
                  style: _meta.copyWith(color: project.accent, fontSize: 11),
                ),
                const SizedBox(height: 8),
                _PlatformAvailability(project: project),
                const SizedBox(height: 22),
                Text(
                  project.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: _monoMuted(context),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _ProjectVisual(
                    project: project,
                    compact: true,
                    onTap: onPreview,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  // Keep the project actions clear of the independent floating
                  // navigation in the lower-right thumb zone.
                  padding: const EdgeInsets.only(right: 58),
                  child: Row(
                    children: [
                      _MobileTools(
                        tools: project.tools,
                        accent: project.accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          color: project.accent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              final liveUrl = project.liveUrl;
                              if (liveUrl != null) {
                                _openUri(context, liveUrl);
                              } else {
                                onPreview();
                              }
                            },
                            child: const SizedBox(
                              height: 48,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Visit Project',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 7),
                                  Icon(
                                    LucideIcons.arrowUpRight,
                                    size: 17,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                SizedBox(width: 310, child: copy),
                const SizedBox(width: 24),
                Expanded(
                  child: _ProjectShowcase(
                    project: project,
                    onPreview: onPreview,
                  ),
                ),
              ],
            ),
    );
  }
}

class _MobileProjectHeader extends StatelessWidget {
  const _MobileProjectHeader({required this.selected, required this.project});
  final int selected;
  final _ProjectData project;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface.withValues(alpha: .94),
    elevation: 1,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 9),
          child: Row(
            children: [
              Text(
                '${(selected + 1).toString().padLeft(2, '0')} / 06',
                style: _meta.copyWith(color: project.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: MediaQuery.sizeOf(context).width * ((selected + 1) / 6),
            height: 2,
            color: project.accent,
          ),
        ),
      ],
    ),
  );
}

class _MobileHighlightCard extends StatefulWidget {
  const _MobileHighlightCard({required this.data, required this.accent});
  final (String, String, IconData) data;
  final Color accent;
  @override
  State<_MobileHighlightCard> createState() => _MobileHighlightCardState();
}

class _FloatingProjectNavigation extends StatelessWidget {
  const _FloatingProjectNavigation({
    required this.selected,
    required this.accent,
    required this.onTap,
    this.onPrevious,
    this.onNext,
  });
  final int selected;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onPrevious, onNext;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Choose project, current project ${selected + 1} of 6',
    child: Material(
      color: accent,
      elevation: 3,
      shadowColor: const Color(0x33000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFDDDDD9)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Previous project',
            onPressed: onPrevious,
            color: Colors.white,
            disabledColor: Colors.white38,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: const Icon(LucideIcons.chevronUp, size: 18),
          ),
          Container(width: 24, height: 1, color: Colors.white30),
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                '${selected + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Container(width: 24, height: 1, color: Colors.white30),
          IconButton(
            tooltip: 'Next project',
            onPressed: onNext,
            color: Colors.white,
            disabledColor: Colors.white38,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: const Icon(LucideIcons.chevronDown, size: 18),
          ),
        ],
      ),
    ),
  );
}

class _MobileHighlightCardState extends State<_MobileHighlightCard> {
  bool details = false;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => setState(() => details = !details),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: widget.accent.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.data.$3, size: 20, color: widget.accent),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              details ? widget.data.$2 : widget.data.$1,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: details ? 12 : 14,
                height: 1.2,
                fontWeight: details ? FontWeight.w500 : FontWeight.w700,
                color: details ? _monoMuted(context) : _monoInk(context),
              ),
            ),
          ),
          Icon(
            details ? LucideIcons.rotateCcw : LucideIcons.chevronRight,
            size: 16,
            color: _monoFaint(context),
          ),
        ],
      ),
    ),
  );
}

class _MobileTools extends StatelessWidget {
  const _MobileTools({required this.tools, required this.accent});
  final List<String> tools;
  final Color accent;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Show all ${tools.length} tools',
    child: InkWell(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.wrench, size: 18, color: accent),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tools & technologies',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tools.map((tool) => _Badge(tool)).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.wrench, size: 15, color: accent),
            ),
            const SizedBox(width: 8),
            Text(
              '${tools.length} tools',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 5),
            Icon(LucideIcons.chevronUp, size: 14, color: _monoFaint(context)),
          ],
        ),
      ),
    ),
  );
}

class _PlatformAvailability extends StatelessWidget {
  const _PlatformAvailability({required this.project});
  final _ProjectData project;

  @override
  Widget build(BuildContext context) {
    final platforms = project.phone
        ? const [
            (LucideIcons.smartphone, 'Android'),
            (LucideIcons.apple, 'iOS'),
          ]
        : const [
            (LucideIcons.monitor, 'Desktop'),
            (LucideIcons.tablet, 'Tablet'),
            (LucideIcons.smartphone, 'Mobile'),
          ];
    return Wrap(
      spacing: 14,
      runSpacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          project.phone ? 'AVAILABLE ON' : 'RESPONSIVE ON',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: _monoFaint(context),
          ),
        ),
        ...platforms.map(
          (platform) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(platform.$1, size: 14, color: project.accent),
              const SizedBox(width: 5),
              Text(
                platform.$2,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectsIntro extends StatelessWidget {
  const _ProjectsIntro({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final compact = constraints.maxWidth < 680;
      return Padding(
        padding: EdgeInsets.all(compact ? 28 : 56),
        child: Align(
          alignment: compact
              ? Alignment.centerLeft
              : const Alignment(-.82, -.1),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FULLSTACK DEVELOPER',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: .5,
                    color: Color(0xFF299FA4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Projects',
                  style: TextStyle(
                    fontSize: compact ? 52 : 66,
                    height: .95,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2.2,
                  ),
                ),
                const SizedBox(height: 42),
                Text(
                  'Six complete products.\nEvery one designed, engineered,\nand delivered independently.',
                  style: TextStyle(
                    fontSize: compact ? 22 : 27,
                    height: 1.5,
                    color: _monoMuted(context),
                  ),
                ),
                const SizedBox(height: 44),
                Semantics(
                  button: true,
                  label: 'Scroll to explore projects',
                  child: InkWell(
                    onTap: onContinue,
                    borderRadius: BorderRadius.circular(30),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Scroll to explore',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(LucideIcons.arrowDown, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ProjectsContact extends StatelessWidget {
  const _ProjectsContact({required this.onContact});
  final VoidCallback onContact;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('06 / 06', style: _meta.copyWith(color: _monoMuted(context))),
          const SizedBox(height: 22),
          Text(
            'Have a project in mind?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 42,
              height: 1.05,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.4,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Let’s turn a useful idea into a thoughtful product.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: _monoMuted(context)),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onContact,
            icon: const Icon(LucideIcons.arrowUpRight),
            label: const Text('Let’s talk'),
          ),
        ],
      ),
    ),
  );
}

class _ProjectGallery extends StatefulWidget {
  const _ProjectGallery({required this.project});
  final _ProjectData project;
  @override
  State<_ProjectGallery> createState() => _ProjectGalleryState();
}

class _ProjectGalleryState extends State<_ProjectGallery> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final images = [
      widget.project.screenshot,
      widget.project.secondaryScreenshot,
    ].whereType<String>().toList();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180, maxHeight: 820),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.project.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${index + 1} / ${images.length}',
                    style: _meta.copyWith(color: _monoMuted(context)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: .8,
                  maxScale: 4,
                  child: Image.asset(
                    images[index],
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              if (images.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => setState(
                        () =>
                            index = (index - 1 + images.length) % images.length,
                      ),
                      icon: const Icon(LucideIcons.arrowLeft),
                    ),
                    const SizedBox(width: 22),
                    IconButton(
                      onPressed: () =>
                          setState(() => index = (index + 1) % images.length),
                      icon: const Icon(LucideIcons.arrowRight),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectSelector extends StatelessWidget {
  const _ProjectSelector({
    required this.selected,
    required this.count,
    required this.onSelected,
    required this.names,
    this.activeColor = ink,
  });
  final int selected, count;
  final ValueChanged<int> onSelected;
  final List<String> names;
  final Color activeColor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) => Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 2,
          bottom: 2,
          child: Container(width: 2, color: _monoInk(context)),
        ),
        Positioned(
          top: 0,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: _monoInk(context),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: _monoInk(context),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(count, (index) {
            final active = index == selected;
            return Tooltip(
              message: names[index],
              preferBelow: false,
              child: Semantics(
                button: true,
                selected: active,
                label: 'Project ${index + 1}',
                child: InkWell(
                  onTap: () => onSelected(index),
                  customBorder: const CircleBorder(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active
                          ? activeColor
                          : Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: _monoInk(context), width: 1.2),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: active ? Colors.white : _monoInk(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    ),
  );
}

class _ProjectHighlight extends StatelessWidget {
  const _ProjectHighlight({required this.data});
  final (String, String, IconData) data;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _monoBorder(context)),
          ),
          child: Icon(data.$3, size: 23),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.$1,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.$2,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: _monoMuted(context),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProjectShowcase extends StatelessWidget {
  const _ProjectShowcase({required this.project, required this.onPreview});
  final _ProjectData project;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final heading = Text(
      'H I G H L I G H T S',
      style: _meta.copyWith(color: _monoFaint(context)),
    );
    if (project.phone) {
      return Row(
        children: [
          Expanded(
            flex: 5,
            child: _ProjectVisual(project: project, onTap: onPreview),
          ),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                const SizedBox(height: 24),
                ...project.highlights.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: _ProjectHighlight(data: item),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 6,
          child: _ProjectVisual(project: project, onTap: onPreview),
        ),
        heading,
        const SizedBox(height: 16),
        Row(
          children: project.highlights
              .map((item) => Expanded(child: _ProjectHighlight(data: item)))
              .toList(),
        ),
      ],
    );
  }
}

class _ProjectVisual extends StatelessWidget {
  const _ProjectVisual({
    required this.project,
    this.compact = false,
    this.onTap,
  });
  final _ProjectData project;
  final bool compact;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Expand ${project.name} screenshots',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Center(
        child: project.phone
            ? compact
                  ? SizedBox(
                      width: 300,
                      height: 330,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 22,
                            top: 38,
                            child: _LargePhone(
                              width: 142,
                              accent: project.accent,
                              screenshot: project.screenshot,
                              label: '${project.name} Android app preview',
                            ),
                          ),
                          Positioned(
                            right: 20,
                            top: 30,
                            child: _LargePhone(
                              width: 142,
                              accent: project.accent,
                              screenshot: project.secondaryScreenshot,
                              label: '${project.name} iOS app preview',
                              rotation: .055,
                            ),
                          ),
                          const Positioned(
                            left: 62,
                            top: 0,
                            child: _DeviceLabel(label: 'Android'),
                          ),
                          const Positioned(
                            right: 66,
                            top: 0,
                            child: _DeviceLabel(label: 'iOS'),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: 330,
                      height: 390,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 28,
                            top: 30,
                            child: _DevicePreview(
                              platform: 'Android',
                              child: _LargePhone(
                                width: 155,
                                accent: project.accent,
                                screenshot: project.screenshot,
                                label: '${project.name} Android app preview',
                              ),
                            ),
                          ),
                          Positioned(
                            right: 24,
                            top: 0,
                            child: _DevicePreview(
                              platform: 'iOS',
                              child: _LargePhone(
                                width: 155,
                                accent: project.accent,
                                screenshot: project.secondaryScreenshot,
                                label: '${project.name} iOS app preview',
                                rotation: .055,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
            : project.secondaryScreenshot != null
            ? compact
                  ? _CompactResponsiveWebPreview(project: project)
                  : SizedBox(
                      width: 560,
                      height: 330,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 4,
                            top: 22,
                            child: _DevicePreview(
                              platform: 'Desktop',
                              child: _LaptopPreview(project: project),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 0,
                            child: _DevicePreview(
                              platform: 'Mobile',
                              child: _LargePhone(
                                width: 105,
                                accent: project.accent,
                                screenshot: project.secondaryScreenshot,
                                label: '${project.name} mobile website preview',
                                rotation: .035,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: compact ? 320 : 470,
                    height: compact ? 172 : 245,
                    padding: EdgeInsets.all(compact ? 8 : 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A19),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(compact ? 7 : 12),
                      ),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.white),
                      clipBehavior: Clip.antiAlias,
                      child: project.screenshot == null
                          ? Center(
                              child: Icon(
                                Icons.language_rounded,
                                size: compact ? 28 : 55,
                                color: project.accent,
                              ),
                            )
                          : Image.asset(
                              project.screenshot!,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              filterQuality: FilterQuality.high,
                              semanticLabel: '${project.name} website preview',
                            ),
                    ),
                  ),
                  Container(
                    width: compact ? 350 : 520,
                    height: compact ? 10 : 15,
                    decoration: const BoxDecoration(
                      color: Color(0xFFBFC1C2),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(18),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

class _CompactResponsiveWebPreview extends StatelessWidget {
  const _CompactResponsiveWebPreview({required this.project});
  final _ProjectData project;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 350,
    height: 250,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 0,
          top: 38,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 292,
                height: 158,
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A19),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.asset(
                    project.screenshot!,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.high,
                    semanticLabel: '${project.name} desktop website preview',
                  ),
                ),
              ),
              Container(
                width: 318,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFFBFC1C2),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          top: 30,
          child: _LargePhone(
            width: 88,
            accent: project.accent,
            screenshot: project.secondaryScreenshot,
            label: '${project.name} mobile website preview',
            rotation: .035,
          ),
        ),
        Positioned(left: 88, bottom: 10, child: _DeviceLabel(label: 'Desktop')),
        Positioned(right: 12, top: 0, child: _DeviceLabel(label: 'Mobile')),
      ],
    ),
  );
}

class _DeviceLabel extends StatelessWidget {
  const _DeviceLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LaptopPreview extends StatelessWidget {
  const _LaptopPreview({required this.project});
  final _ProjectData project;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 420,
        height: 220,
        padding: const EdgeInsets.all(13),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A19),
          borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(color: Colors.white),
          child: Image.asset(
            project.screenshot!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
            semanticLabel: '${project.name} desktop website preview',
          ),
        ),
      ),
      Container(
        width: 466,
        height: 14,
        decoration: const BoxDecoration(
          color: Color(0xFFBFC1C2),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
      ),
    ],
  );
}

class _DevicePreview extends StatelessWidget {
  const _DevicePreview({required this.platform, required this.child});
  final String platform;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      child,
      const SizedBox(height: 8),
      Builder(
        builder: (context) {
          final colors = Theme.of(context).colorScheme;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              platform,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
    ],
  );
}

class _ProjectCard extends StatefulWidget {
  const _ProjectCard({
    required this.title,
    required this.category,
    required this.color,
    required this.icon,
  });
  final String title, category;
  final Color color;
  final IconData icon;
  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hover = true),
    onExit: (_) => setState(() => hover = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      transform: Matrix4.translationValues(0, hover ? -4 : 0, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: hover
            ? const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(child: _MiniPhone(icon: widget.icon)),
          ),
          Text(widget.category, style: _meta.copyWith(fontSize: 7)),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.arrow_outward_rounded, size: 13),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MiniPhone extends StatelessWidget {
  const _MiniPhone({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -.06,
    child: Container(
      width: 44,
      height: 67,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 8,
            offset: Offset(2, 5),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 19, color: blue),
      ),
    ),
  );
}

class _CaseFace extends StatelessWidget {
  const _CaseFace({required this.onView});
  final VoidCallback onView;
  @override
  Widget build(BuildContext context) => _FaceFrame(
    number: '03',
    title: 'FEATURED CASE STUDY',
    child: LayoutBuilder(
      builder: (_, c) {
        final compact = c.maxWidth < 650;
        final mockup = Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -5, end: 5),
            duration: const Duration(seconds: 3),
            curve: Curves.easeInOut,
            builder: (_, y, child) =>
                Transform.translate(offset: Offset(0, y), child: child),
            onEnd: () {},
            child: _LargePhone(width: compact ? 92 : 190),
          ),
        );
        final details = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MARI\nMENDIRIKAN\nSOLAT',
              style: TextStyle(
                fontSize: compact ? 27 : 35,
                height: .93,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.6,
              ),
            ),
            const SizedBox(height: 18),
            const Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                _Badge('Flutter'),
                _Badge('Firebase'),
                _Badge('Offline'),
              ],
            ),
            const SizedBox(height: 22),
            _ActionButton(
              label: 'View Case Study',
              dark: true,
              onPressed: onView,
            ),
          ],
        );
        if (compact) {
          return Column(
            children: [
              Expanded(flex: 5, child: mockup),
              Expanded(flex: 5, child: details),
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 6, child: mockup),
            Expanded(flex: 5, child: details),
          ],
        );
      },
    ),
  );
}

class _LargePhone extends StatelessWidget {
  const _LargePhone({
    required this.width,
    this.accent = const Color(0xFF486455),
    this.screenshot,
    this.label,
    this.rotation = -.075,
  });
  final double width;
  final Color accent;
  final String? screenshot, label;
  final double rotation;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: rotation,
    child: Container(
      width: width,
      height: width * 1.9,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A19),
        borderRadius: BorderRadius.circular(width * .14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 26,
            offset: Offset(10, 18),
          ),
        ],
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EBDD),
          borderRadius: BorderRadius.circular(width * .105),
        ),
        child: screenshot != null
            ? Image.asset(
                screenshot!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
                semanticLabel: label,
              )
            : Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: width * .27,
                    height: 6,
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Icon(
                        Icons.mosque_rounded,
                        size: width * .27,
                        color: accent,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Container(height: 5, color: const Color(0xFFB8AF96)),
                        const SizedBox(height: 5),
                        Container(
                          height: 5,
                          width: width * .55,
                          color: const Color(0xFFC9C1AA),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

class _ToolSummary extends StatefulWidget {
  const _ToolSummary({required this.tools});
  final List<String> tools;

  @override
  State<_ToolSummary> createState() => _ToolSummaryState();
}

class _ToolSummaryState extends State<_ToolSummary> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final visible = expanded ? widget.tools : widget.tools.take(4).toList();
    final remaining = widget.tools.length - 4;
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ...visible.map((tool) => _Badge(tool)),
          if (remaining > 0)
            Semantics(
              button: true,
              expanded: expanded,
              label: expanded ? 'Collapse tools' : 'Show $remaining more tools',
              child: InkWell(
                onTap: () => setState(() => expanded = !expanded),
                borderRadius: BorderRadius.circular(99),
                child: _Badge(
                  expanded ? 'Show less  ↑' : '+$remaining tools  ↓',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: _monoBorder(context)),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.dark = false,
    this.icon,
  });
  final String label;
  final bool dark;
  final IconData? icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final inverseBackground = _monoInk(context);
    final inverseForeground = Theme.of(context).colorScheme.surface;
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_outward_rounded, size: 14),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: dark
            ? inverseBackground
            : Theme.of(context).colorScheme.surface,
        foregroundColor: dark ? inverseForeground : _monoInk(context),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: dark
              ? BorderSide.none
              : BorderSide(color: _monoBorder(context)),
        ),
      ),
    );
  }
}

class _SkillsFace extends StatelessWidget {
  const _SkillsFace({
    required this.animate,
    required this.scrollOffset,
    required this.viewportHeight,
    required this.onProjects,
    required this.onContact,
  });
  final bool animate;
  final double scrollOffset;
  final double viewportHeight;
  final VoidCallback onProjects, onContact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: viewportHeight,
      child: LayoutBuilder(
        builder: (_, c) {
          final compact = c.maxWidth < 720;
          final copy = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skills',
                style: TextStyle(
                  fontSize: compact ? 36 : 58,
                  height: .94,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2.6,
                ),
              ),
              SizedBox(height: compact ? 12 : 24),
              Text(
                'FULL STACK ENGINEERING',
                style: TextStyle(
                  color: Color(0xFF299FA4),
                  fontSize: compact ? 12 : 15,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: compact ? 10 : 20),
              Text(
                'I design, build and ship complete digital products from user-centered interfaces to reliable backend systems.',
                style: TextStyle(
                  fontSize: compact ? 12 : 16,
                  height: 1.45,
                  color: _monoMuted(context),
                ),
              ),
              SizedBox(height: compact ? 10 : 20),
              Text(
                'EXPERTISE',
                style: _meta.copyWith(color: _monoMuted(context)),
              ),
              SizedBox(height: compact ? 6 : 9),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge('Mobile'),
                  _Badge('Web'),
                  _Badge('Backend'),
                  _Badge('Database'),
                  _Badge('Tools'),
                ],
              ),
              SizedBox(height: compact ? 10 : 18),
              Text(
                'TECHNOLOGIES',
                style: _meta.copyWith(color: _monoMuted(context)),
              ),
              SizedBox(height: compact ? 6 : 10),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TechMark('F', 'Flutter'),
                  _TechMark('D', 'Dart'),
                  _TechMark('JS', 'JavaScript'),
                  _TechMark('◆', 'Firebase'),
                  _TechMark('L', 'Laravel'),
                  _TechMark('GH', 'GitHub'),
                ],
              ),
              SizedBox(height: compact ? 10 : 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ActionButton(
                    label: 'View Projects',
                    dark: true,
                    onPressed: onProjects,
                  ),
                  _ActionButton(
                    label: 'Contact Me',
                    icon: LucideIcons.mail,
                    onPressed: onContact,
                  ),
                ],
              ),
            ],
          );
          if (compact) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 82),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  copy,
                  const SizedBox(height: 12),
                  Expanded(
                    child: _ArchitectureStack(
                      animate: animate,
                      compact: true,
                      progress: 1,
                    ),
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(76, 42, 48, 42),
            child: Row(
              children: [
                SizedBox(width: 340, child: copy),
                const SizedBox(width: 28),
                Expanded(
                  child: _ArchitectureStack(animate: animate, progress: 1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TechMark extends StatelessWidget {
  const _TechMark(this.mark, this.label);
  final String mark, label;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: _monoBorder(context)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        mark,
        style: TextStyle(
          color: _technologyColor(label),
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );

  Color _technologyColor(String value) => switch (value) {
    'Flutter' => const Color(0xFF42A5F5),
    'Dart' => const Color(0xFF1687C9),
    'Kotlin' => const Color(0xFFEF6C35),
    'Android' => const Color(0xFF48B75D),
    'HTML5' => const Color(0xFFE45126),
    'CSS3' => const Color(0xFF2465F1),
    'JavaScript' => const Color(0xFFE5C000),
    'Tailwind' => const Color(0xFF20B7C9),
    'Firebase' || 'Firestore' => const Color(0xFFFFA000),
    'Laravel' => const Color(0xFFF04438),
    'Git' => const Color(0xFFF05032),
    _ => ink,
  };
}

class _ArchitectureStack extends StatefulWidget {
  const _ArchitectureStack({
    required this.animate,
    required this.progress,
    this.compact = false,
  });
  final bool animate, compact;
  final double progress;
  @override
  State<_ArchitectureStack> createState() => _ArchitectureStackState();
}

class _ArchitectureStackState extends State<_ArchitectureStack> {
  double expansion = 1;
  int? focused;
  int? pinned;

  static const layers = <(String, String, Color, IconData, List<String>)>[
    (
      'PRODUCT / UI',
      'User interface & experience',
      Color(0xFFE5F7F3),
      LucideIcons.monitorSmartphone,
      ['Flutter', 'Flutter Web', 'HTML5', 'CSS3', 'JavaScript', 'Tailwind'],
    ),
    (
      'MOBILE & FRONTEND',
      'Cross-platform applications',
      Color(0xFFE2F2FF),
      LucideIcons.smartphone,
      [
        'Dart',
        'Kotlin',
        'Android SDK',
        'State',
        'Navigation',
        'Animation',
        'Forms',
      ],
    ),
    (
      'API & INTEGRATION',
      'Applications & services',
      Color(0xFFECE9FF),
      LucideIcons.braces,
      ['REST API', 'Firebase Auth', 'JSON', 'Postman'],
    ),
    (
      'BACKEND',
      'Logic & business rules',
      Color(0xFFE8F7E8),
      LucideIcons.cloudCog,
      ['Firebase', 'Cloud Functions', 'Laravel', 'PHP', 'Filament', 'Livewire'],
    ),
    (
      'DATABASE',
      'Secure data management',
      Color(0xFFFFF0DB),
      LucideIcons.database,
      [
        'Cloud Firestore',
        'Firebase Storage',
        'MySQL',
        'SQLite',
        'Shared Preferences',
      ],
    ),
    (
      'DEVELOPMENT TOOLS',
      'Tools that power development',
      Color(0xFFF1F2F3),
      LucideIcons.wrench,
      ['Git', 'GitHub', 'VS Code', 'Android Studio', 'Figma'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (_, c) {
        final visible = widget.animate || reduced;
        return AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: reduced ? Duration.zero : const Duration(milliseconds: 350),
          child: widget.compact
              ? _buildMobileExplorer()
              : _buildDesktopExplorer(c),
        );
      },
    );
  }

  Widget _buildDesktopExplorer(BoxConstraints constraints) {
    final selected = focused ?? pinned ?? 0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 680),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 235,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < layers.length; index++) ...[
                    _CapabilityButton(
                      index: index,
                      data: layers[index],
                      selected: selected == index,
                      onHover: (hovered) =>
                          setState(() => focused = hovered ? index : null),
                      onPressed: () => setState(() => pinned = index),
                    ),
                    if (index != layers.length - 1) const SizedBox(height: 9),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: SizedBox.expand(
                child: _CapabilityDetailPanel(
                  index: selected,
                  data: layers[selected],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileExplorer() => ListView.separated(
    padding: const EdgeInsets.only(bottom: 12),
    itemCount: layers.length,
    separatorBuilder: (_, _) => const SizedBox(height: 10),
    itemBuilder: (_, index) {
      final expanded = pinned == index;
      return _MobileCapabilityCard(
        index: index,
        data: layers[index],
        expanded: expanded,
        onPressed: () => setState(() => pinned = expanded ? null : index),
      );
    },
  );

  // ignore: unused_element
  Widget _buildLayer(int index, double scale, double entrance) {
    final selected = focused ?? pinned;
    final active = selected == null || selected == index;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final rawReveal = ((widget.progress - (.10 + index * .14)) / .15).clamp(
      0.0,
      1.0,
    );
    final stagger =
        entrance * (reduced ? 1.0 : Curves.easeOutCubic.transform(rawReveal));
    final top = (130 + index * 78 * expansion) * scale;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      left: (145 + index * 3) * scale,
      top: top + (1 - stagger) * 90 * scale,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: active ? stagger : stagger * .28,
        child: MouseRegion(
          onEnter: (_) => setState(() => focused = index),
          onExit: (_) => setState(() => focused = null),
          child: GestureDetector(
            onTap: () => setState(() {
              pinned = pinned == index ? null : index;
              focused = null;
            }),
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, .001)
                ..rotateX(-.11)
                ..rotateZ(.035),
              alignment: Alignment.center,
              child: _ArchitectureLayerCard(
                index: index,
                scale: scale,
                data: layers[index],
                focused: selected == index,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildLabel(int index, double scale, double entrance) {
    final data = layers[index];
    final y = (147 + index * 78 * expansion) * scale;
    final reveal = MediaQuery.disableAnimationsOf(context)
        ? 1.0
        : ((widget.progress - (.10 + index * .14)) / .15).clamp(0.0, 1.0);
    final selected = focused ?? pinned;
    final active = selected == null || selected == index;
    return Positioned(
      left: 518 * scale,
      top: y,
      child: Opacity(
        opacity: (active ? entrance : entrance * .25) * reveal,
        child: Row(
          children: [
            Container(
              width: 32 * scale,
              height: 1,
              color: data.$3.withValues(alpha: .8),
            ),
            Container(
              width: 134 * scale,
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 8 * scale,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: _monoBorder(context)),
                borderRadius: BorderRadius.circular(15 * scale),
                boxShadow: const [
                  BoxShadow(color: Color(0x12000000), blurRadius: 12),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.$1,
                    style: TextStyle(
                      fontSize: 11 * scale,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    data.$5.join(', '),
                    style: TextStyle(
                      fontSize: 8.6 * scale,
                      height: 1.25,
                      color: _monoMuted(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSideLabel(int index, double scale, double entrance) {
    final data = layers[index];
    final reveal = MediaQuery.disableAnimationsOf(context)
        ? 1.0
        : ((widget.progress - (.10 + index * .14)) / .15).clamp(0.0, 1.0);
    const accents = [
      Color(0xFF119C99),
      Color(0xFF168ED8),
      Color(0xFF6356D9),
      Color(0xFF49A85B),
      Color(0xFFE08B18),
      Color(0xFF657084),
    ];
    return Positioned(
      left: 0,
      top: (144 + index * 78 * expansion) * scale,
      child: Opacity(
        opacity: entrance * reveal,
        child: SizedBox(
          width: 125 * scale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.$1,
                style: TextStyle(
                  color: accents[index],
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5 * scale),
              Text(
                data.$2,
                style: TextStyle(
                  color: _monoMuted(context),
                  fontSize: 8.5 * scale,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _openReadableView() => showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
              child: Row(
                children: [
                  const Icon(LucideIcons.text, size: 26),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skills — readable view',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Large text and simplified technology groups',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close readable view',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(LucideIcons.x, size: 28),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _monoBorder(dialogContext)),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: layers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, index) =>
                    _ReadableSkillCard(number: index + 1, data: layers[index]),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CapabilityButton extends StatelessWidget {
  const _CapabilityButton({
    required this.index,
    required this.data,
    required this.selected,
    required this.onHover,
    required this.onPressed,
  });
  final int index;
  final (String, String, Color, IconData, List<String>) data;
  final bool selected;
  final ValueChanged<bool> onHover;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${data.$1}. ${data.$2}',
    child: MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? data.$3 : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _monoInk(context) : _monoBorder(context),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            child: Row(
              children: [
                Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: TextStyle(
                    color: selected ? ink : _monoMuted(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 13),
                Icon(
                  data.$4,
                  size: 22,
                  color: selected ? ink : _monoInk(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data.$1,
                    maxLines: 2,
                    style: TextStyle(
                      color: selected ? ink : _monoInk(context),
                      fontSize: 15,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 19,
                  color: selected ? ink : _monoMuted(context),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _CapabilityDetailPanel extends StatelessWidget {
  const _CapabilityDetailPanel({required this.index, required this.data});
  final int index;
  final (String, String, Color, IconData, List<String>) data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: data.$3,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: _monoBorder(context)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 32,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .88),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(data.$4, size: 30, color: ink),
            ),
            const Spacer(),
            Text(
              '${index + 1}'.padLeft(2, '0'),
              style: const TextStyle(
                color: Color(0xFF555552),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          data.$1,
          style: const TextStyle(
            color: ink,
            fontSize: 30,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          data.$2,
          style: const TextStyle(
            color: Color(0xFF555552),
            fontSize: 18,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'TECHNOLOGIES',
          style: TextStyle(
            color: ink.withValues(alpha: .65),
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final technology in data.$5)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x18000000)),
                ),
                child: Text(
                  technology,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const Spacer(),
        if (index == 0)
          Container(
            height: 210,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x18000000)),
            ),
            child: Image.asset(
              'assets/images/solatiy-home.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          )
        else
          _CapabilityEvidence(index: index),
      ],
    ),
  );
}

class _CapabilityEvidence extends StatelessWidget {
  const _CapabilityEvidence({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    const evidence = [
      '',
      'Delivered responsive mobile experiences for Android and iOS.',
      'Connected client applications to authentication and content services.',
      'Built business logic for HR, learning and service platforms.',
      'Designed reliable storage for users, content and application progress.',
      'Used production tooling from development through delivery.',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.circleCheck, color: ink, size: 24),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              evidence[index],
              style: const TextStyle(color: ink, fontSize: 17, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileCapabilityCard extends StatelessWidget {
  const _MobileCapabilityCard({
    required this.index,
    required this.data,
    required this.expanded,
    required this.onPressed,
  });
  final int index;
  final (String, String, Color, IconData, List<String>) data;
  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    decoration: BoxDecoration(
      color: expanded ? data.$3 : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: expanded ? _monoInk(context) : _monoBorder(context),
      ),
    ),
    child: Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Icon(
                  data.$4,
                  size: 24,
                  color: expanded ? ink : _monoInk(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data.$1,
                    style: TextStyle(
                      color: expanded ? ink : _monoInk(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.$2,
                  style: const TextStyle(
                    color: Color(0xFF555552),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final technology in data.$5)
                      Chip(
                        label: Text(
                          technology,
                          style: const TextStyle(color: ink, fontSize: 14),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: .9),
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

// ignore: unused_element
class _ReadableViewButton extends StatelessWidget {
  const _ReadableViewButton({required this.scale, required this.onPressed});
  final double scale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(LucideIcons.text, size: 16 * scale),
    label: Text(
      'Readable view',
      style: TextStyle(
        fontSize: math.max(11, 11 * scale),
        fontWeight: FontWeight.w800,
      ),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: _monoInk(context),
      backgroundColor: Theme.of(context).colorScheme.surface,
      minimumSize: Size(math.max(120, 132 * scale), math.max(48, 42 * scale)),
      side: BorderSide(color: _monoBorder(context)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12 * scale),
      ),
    ),
  );
}

class _ReadableSkillCard extends StatelessWidget {
  const _ReadableSkillCard({required this.number, required this.data});
  final int number;
  final (String, String, Color, IconData, List<String>) data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: data.$3,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _monoBorder(context)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .85),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(data.$4, size: 28, color: ink),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${number.toString().padLeft(2, '0')}  ${data.$1}',
                style: const TextStyle(
                  color: ink,
                  fontSize: 20,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                data.$2,
                style: const TextStyle(
                  color: Color(0xFF555552),
                  fontSize: 17,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final technology in data.$5)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        technology,
                        style: const TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ArchitectureLayerCard extends StatelessWidget {
  const _ArchitectureLayerCard({
    required this.index,
    required this.scale,
    required this.data,
    required this.focused,
  });
  final int index;
  final double scale;
  final (String, String, Color, IconData, List<String>) data;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 350 * scale,
      height: 88 * scale,
      padding: EdgeInsets.symmetric(horizontal: 18 * scale),
      decoration: BoxDecoration(
        color: data.$3.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(19 * scale),
        border: Border.all(
          color: data.$3.withValues(alpha: .95),
          width: focused ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: data.$3.withValues(alpha: focused ? .65 : .38),
            blurRadius: focused ? 30 : 18,
            spreadRadius: focused ? 1 : 0,
            offset: Offset(0, 12 * scale),
          ),
          const BoxShadow(
            color: Color(0x16000000),
            blurRadius: 13,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            data.$4,
            size: 26 * scale,
            color: data.$3.computeLuminance() > .7 ? ink : Colors.white,
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 5 * scale,
              runSpacing: 4 * scale,
              children: [
                for (final technology in data.$5)
                  _ArchitectureTechnology(
                    label: technology,
                    scale: scale,
                    accent: _layerAccent(index),
                  ),
              ],
            ),
          ),
          Container(
            width: 6 * scale,
            height: 6 * scale,
            decoration: const BoxDecoration(
              color: Color(0xFF37A5A2),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Color _layerAccent(int i) => const [
    Color(0xFF119C99),
    Color(0xFF168ED8),
    Color(0xFF6356D9),
    Color(0xFF49A85B),
    Color(0xFFE08B18),
    Color(0xFF657084),
  ][i];
}

class _ArchitectureTechnology extends StatelessWidget {
  const _ArchitectureTechnology({
    required this.label,
    required this.scale,
    required this.accent,
  });
  final String label;
  final double scale;
  final Color accent;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18 * scale,
          height: 18 * scale,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .78),
            borderRadius: BorderRadius.circular(5 * scale),
          ),
          child: Text(
            label.substring(0, math.min(label.length, 2)).toUpperCase(),
            style: TextStyle(
              color: accent,
              fontSize: 6.5 * scale,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(height: 2 * scale),
        SizedBox(
          width: 45 * scale,
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: ink, fontSize: 6.8 * scale, height: 1.05),
          ),
        ),
      ],
    ),
  );
}

// ignore: unused_element
class _ArchitectureConnectorPainter extends CustomPainter {
  const _ArchitectureConnectorPainter({
    required this.entrance,
    required this.expansion,
    required this.scale,
    required this.focused,
  });
  final double entrance, expansion, scale;
  final int? focused;

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFF37C7B9),
      Color(0xFF70D9F5),
      Color(0xFFA77BEF),
      Color(0xFF52D3BE),
      Color(0xFFFFB45C),
      Color(0xFFDADDE2),
    ];
    final x = 492 * scale;
    final centers = <double>[
      for (var i = 0; i < 6; i++) (174 + i * 78 * expansion) * scale,
    ];
    for (var i = 0; i < centers.length - 1; i++) {
      final visible = ((entrance * 1.5) - i * .12).clamp(0.0, 1.0);
      final start = centers[i];
      final end = start + (centers[i + 1] - start) * visible;
      final paint = Paint()
        ..color = colors[i].withValues(
          alpha: focused == null || focused == i || focused == i + 1 ? .9 : .2,
        )
        ..strokeWidth = 2 * scale
        ..strokeCap = StrokeCap.round;
      const dash = 6.0;
      var y = start;
      while (y < end) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, math.min(y + dash * scale, end)),
          paint,
        );
        y += 12 * scale;
      }
      if (visible > .85) {
        canvas.drawCircle(
          Offset(x, centers[i + 1]),
          9 * scale,
          Paint()..color = colors[i].withValues(alpha: .16),
        );
        canvas.drawCircle(
          Offset(x, centers[i + 1]),
          4 * scale,
          Paint()..color = colors[i],
        );
        canvas.drawCircle(
          Offset(x, centers[i + 1]),
          2 * scale,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArchitectureConnectorPainter oldDelegate) =>
      oldDelegate.entrance != entrance ||
      oldDelegate.expansion != expansion ||
      oldDelegate.scale != scale ||
      oldDelegate.focused != focused;
}

class _AboutFace extends StatelessWidget {
  const _AboutFace();
  @override
  Widget build(BuildContext context) => _FaceFrame(
    number: '05',
    title: 'ABOUT',
    child: LayoutBuilder(
      builder: (_, c) {
        final compact = c.maxWidth < 650;
        final introduction = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engineer by skill.\nDesigner by mindset.',
              style: TextStyle(
                fontSize: compact ? 32 : 48,
                height: .98,
                fontWeight: FontWeight.w700,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'I build mobile and web products from idea, interaction design, and architecture through implementation.',
              style: TextStyle(
                fontSize: 17,
                height: 1.5,
                color: Color(0xFF696966),
              ),
            ),
          ],
        );
        return Column(
          children: [
            Expanded(
              child: compact
                  ? Column(
                      children: [
                        SizedBox(
                          height: 54,
                          child: Center(child: _Portrait(size: 48)),
                        ),
                        Expanded(child: introduction),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: Center(child: _Portrait(size: 190))),
                        Expanded(child: introduction),
                      ],
                    ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 82,
                  child: Text(
                    'EXPERIENCE',
                    style: _meta.copyWith(color: _monoMuted(context)),
                  ),
                ),
                const Expanded(
                  child: Text(
                    '2023—NOW\nSoftware development and independent product work',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '2021—2025\nAndroid development, digital products, and IT procurement',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openUri(
                  context,
                  Uri(
                    scheme: 'mailto',
                    queryParameters: const {
                      'subject': 'Résumé request — Nuruddin Mahmud',
                    },
                  ),
                ),
                icon: const Icon(Icons.download_rounded, size: 15),
                label: const Text('Request résumé'),
                style: TextButton.styleFrom(
                  foregroundColor: _monoInk(context),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _ContactFace extends StatelessWidget {
  const _ContactFace();
  @override
  Widget build(BuildContext context) => _FaceFrame(
    number: '06',
    title: 'CONTACT',
    child: LayoutBuilder(
      builder: (_, c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text('HAVE A USEFUL IDEA?', style: _meta.copyWith(color: blue)),
          const SizedBox(height: 14),
          Text(
            'Let’s make\nit real.',
            style: TextStyle(
              fontSize: c.maxWidth < 520 ? 48 : 66,
              height: .9,
              fontWeight: FontWeight.w700,
              letterSpacing: c.maxWidth < 520 ? -2.5 : -4,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Available by email',
            style: TextStyle(fontSize: 16, color: _monoMuted(context)),
          ),
          const SizedBox(height: 14),
          _ActionButton(
            label: 'Send an email',
            dark: true,
            icon: Icons.arrow_forward_rounded,
            onPressed: () => _openUri(
              context,
              Uri(
                scheme: 'mailto',
                queryParameters: const {
                  'subject': 'Portfolio enquiry — Nuruddin Mahmud',
                },
              ),
            ),
          ),
          const Spacer(),
          const Divider(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 28,
            runSpacing: 10,
            children: [
              _TextLink(
                label: 'GitHub',
                onTap: () => _openUri(
                  context,
                  Uri.parse('https://github.com/NuruddinMMS'),
                ),
              ),
              _TextLink(
                label: 'LinkedIn',
                onTap: () => _openUri(
                  context,
                  Uri.parse(
                    'https://www.linkedin.com/search/results/people/?keywords=Nuruddin%20Mahmud',
                  ),
                ),
              ),
              _TextLink(
                label: 'Résumé',
                onTap: () => _openUri(
                  context,
                  Uri(
                    scheme: 'mailto',
                    queryParameters: const {
                      'subject': 'Résumé request — Nuruddin Mahmud',
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 5),
          const Icon(Icons.arrow_outward_rounded, size: 14),
        ],
      ),
    ),
  );
}
