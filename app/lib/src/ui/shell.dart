import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../l10n/strings.dart';
import '../design/logo.dart';
import '../design/theme.dart';
import '../sora.dart';
import 'about.dart';
import 'connections.dart';
import 'home.dart';
import 'logs.dart';
import 'notifications_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'tour.dart';

class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.select, required this.replayTour, required super.child});
  final ValueChanged<int> select;
  final VoidCallback replayTour;
  static ShellScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellScope>()!;
  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});
  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> with WidgetsBindingObserver {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _tourKeys = List.generate(5, (_) => GlobalKey());
  final _focus = FocusNode();
  GlobalKey<NavigatorState> _contentNavigator = GlobalKey();
  late final ShowcaseView _tour;
  int _section = 0;
  int _tourStep = 0;
  bool _tourScheduled = false;
  OverlayEntry? _scrim;
  Rect? _targetRect;
  BuildContext? _targetContext;

  @override
  void initState() {
    super.initState();
    _tour = ShowcaseView.register(
      scope: 'sora-tour',
      enableAutoScroll: true,
      disableMovingAnimation: true,
      disableBarrierInteraction: true,
      onStart: (_, key) => _tourStep = _tourKeys.indexOf(key),
      onFinish: _tourDone,
      onDismiss: (_) => _tourDone(),
    );
    HardwareKeyboard.instance.addHandler(_keyboard);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tour.scrollDuration = Motion.of(context, const Duration(milliseconds: 220));
    _tour.disableScaleAnimation = !Motion.enabled(context);
    if (!_tourScheduled) {
      _tourScheduled = true;
      if (!SoraScope.read(context).settings.tourDone) WidgetsBinding.instance.addPostFrameCallback((_) => _startTour());
    }
  }

  void _tourDone() {
    _scrim?.remove();
    _scrim?.dispose();
    _scrim = null;
    _targetRect = null;
    _targetContext = null;
    if (mounted) unawaited(SoraScope.read(context).settings.completeTour());
  }

  void _startTour() {
    if (!mounted) return;
    if (_tour.isShowcaseRunning) _tour.dismiss();
    _scaffold.currentState?.closeDrawer();
    if (_section == 0) {
      _contentNavigator.currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _section = 0;
        _contentNavigator = GlobalKey();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrim = OverlayEntry(
          builder: (_) => _targetRect == null
              ? const SizedBox()
              : TourScrim(rect: _targetRect!, duration: Motion.of(context, const Duration(milliseconds: 220))),
        );
        Overlay.of(context, rootOverlay: true).insert(_scrim!);
        _focus.requestFocus();
        _tour.startShowCase(_tourKeys);
      }
    });
  }

  void _updateTarget(int step, Rect rect, BuildContext target) {
    if (step != _tourStep || rect.isEmpty || rect == _targetRect) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tour.isShowcaseRunning || step != _tourStep) return;
      _targetRect = rect;
      _targetContext = target;
      _scrim?.markNeedsBuild();
    });
  }

  @override
  void didChangeMetrics() {
    if (!_tour.isShowcaseRunning) return;
    // Targets can move between panes at a breakpoint; remeasure after layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tour.isShowcaseRunning) return;
      final target = _targetContext;
      if (target != null && target.mounted) {
        unawaited(Scrollable.ensureVisible(target, duration: _tour.scrollDuration, alignment: 0.5));
      }
    });
  }

  void _select(int value) {
    if (_tour.isShowcaseRunning) _tour.dismiss();
    _scaffold.currentState?.closeDrawer();
    if (_section == value) {
      _contentNavigator.currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _section = value;
        _contentNavigator = GlobalKey();
      });
    }
  }

  void _toggle() {
    if (MediaQuery.sizeOf(context).width < 720) {
      _scaffold.currentState?.openDrawer();
    } else {
      final sora = SoraScope.read(context);
      unawaited(sora.change((x) => x.sidebarExpanded = !x.sidebarExpanded, replan: false));
    }
  }

  bool _keyboard(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;
    if (_tour.isShowcaseRunning) {
      if (key == LogicalKeyboardKey.escape) {
        _tour.dismiss();
        return true;
      }
      if (key == LogicalKeyboardKey.arrowRight) {
        _tour.next();
        return true;
      }
      if (key == LogicalKeyboardKey.arrowLeft) {
        _tour.previous();
        return true;
      }
      return false;
    }
    if (key == LogicalKeyboardKey.escape) {
      final root = Navigator.of(context, rootNavigator: true);
      if (root.canPop()) {
        unawaited(root.maybePop());
      } else if (_scaffold.currentState?.isDrawerOpen ?? false) {
        _scaffold.currentState?.closeDrawer();
      } else {
        unawaited(_contentNavigator.currentState?.maybePop());
      }
      return true;
    }
    if (!HardwareKeyboard.instance.isControlPressed) return false;
    const numbers = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
    ];
    final index = numbers.indexOf(key);
    if (index >= 0) {
      _select(index);
      return true;
    }
    if (key == LogicalKeyboardKey.keyB) {
      _toggle();
      return true;
    }
    if (key == LogicalKeyboardKey.comma) {
      _select(5);
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keyboard);
    WidgetsBinding.instance.removeObserver(this);
    _tour.unregister();
    _scrim?.remove();
    _scrim?.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context), palette = Palette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;
    final expanded = width >= 1000 && sora.settings.sidebarExpanded;
    final pages = <Widget>[
      const HomeScreen(),
      const RulesScreen(),
      const ConnectionsScreen(),
      const LogsScreen(),
      const NotificationsScreen(),
      const SettingsScreen(),
      const AboutScreen(),
    ];
    final page = pages[_section];
    final pane = AnimatedSwitcher(
      duration: Motion.of(context, const Duration(milliseconds: 150)),
      child: KeyedSubtree(
        key: ObjectKey(_contentNavigator),
        child: Navigator(
          key: _contentNavigator,
          onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => page),
        ),
      ),
    );
    return ShellScope(
      select: _select,
      replayTour: _startTour,
      child: TourScope(
        keys: _tourKeys,
        view: _tour,
        targetRect: _updateTarget,
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          child: Scaffold(
            key: _scaffold,
            drawer: compact
                ? Drawer(
                    width: 224,
                    backgroundColor: palette.surface,
                    shape: const RoundedRectangleBorder(),
                    child: _sidebar(true, drawer: true),
                  )
                : null,
            body: SafeArea(
              child: Row(
                children: [
                  if (!compact)
                    AnimatedContainer(
                      key: const ValueKey('sidebar'),
                      width: expanded ? 224 : 56,
                      duration: Motion.of(context, const Duration(milliseconds: 200)),
                      curve: Curves.easeOutCubic,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(color: palette.surface),
                      foregroundDecoration: BoxDecoration(
                        border: Border(right: BorderSide(color: palette.field)),
                      ),
                      child: _sidebar(expanded),
                    ),
                  Expanded(child: pane),
                ],
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
            floatingActionButton: compact
                ? TourTarget(
                    step: 4,
                    child: Material(
                      color: palette.surface,
                      elevation: 2,
                      borderRadius: BorderRadius.circular(12),
                      child: IconButton(
                        key: const ValueKey('drawer-button'),
                        tooltip: S.of(context).sidebarToggle,
                        icon: const Icon(Symbols.menu_rounded),
                        onPressed: _toggle,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _sidebar(bool expanded, {bool drawer = false}) {
    final s = S.of(context), sora = SoraScope.of(context), palette = Palette.of(context);
    final labels = [s.home, s.navRules, s.navConnections, s.navLogs, s.notifications, s.settings, s.navAbout];
    const icons = [
      Symbols.home_rounded,
      Symbols.rule_rounded,
      Symbols.swap_vert_rounded,
      Symbols.terminal_rounded,
      Symbols.notifications_rounded,
      Symbols.settings_rounded,
      Symbols.info_rounded,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: IconButton(
                  key: const ValueKey('sidebar-toggle'),
                  tooltip: s.sidebarToggle,
                  onPressed: drawer ? () => _scaffold.currentState?.closeDrawer() : _toggle,
                  icon: Icon(drawer ? Symbols.close_rounded : Symbols.menu_rounded, color: palette.ink, size: 22),
                ),
              ),
              if (expanded)
                Expanded(
                  child: Text('Sora', maxLines: 1, style: Styles.heading.copyWith(color: palette.ink)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (var index = 0; index < labels.length; index++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: index == 5 && !drawer
                ? TourTarget(step: 4, child: _navItem(index, labels[index], icons[index], expanded, sora, palette))
                : _navItem(index, labels[index], icons[index], expanded, sora, palette),
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: SoraMark(size: 20, color: palette.ink3),
        ),
      ],
    );
  }

  Widget _navItem(int index, String label, IconData icon, bool expanded, Sora sora, Palette palette) => Tooltip(
    message: '$label (Ctrl+${index + 1})',
    child: Semantics(
      selected: _section == index,
      child: Material(
        color: _section == index ? palette.field : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _select(index),
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Center(
                    child: Badge(
                      isLabelVisible: index == 4 && sora.unreadCount > 0,
                      backgroundColor: palette.ink,
                      textColor: palette.surface,
                      label: Text('${sora.unreadCount}', style: Styles.caption.copyWith(color: palette.surface)),
                      child: Icon(icon, size: 22, color: _section == index ? palette.ink : palette.ink2),
                    ),
                  ),
                ),
                if (expanded)
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Styles.secondary.copyWith(color: palette.ink),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
