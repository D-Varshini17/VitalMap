import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/responsive.dart';
import 'firebase_options.dart';
import 'screens/body_health_map_screen.dart';
import 'screens/health_history_screen.dart';
import 'screens/home_overview_screen.dart';
import 'screens/input_screen.dart';
import 'screens/insight_screen.dart';
import 'screens/login_screen.dart';
import 'screens/more_screen.dart';
import 'screens/results_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/symptom_tracker_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'storage/local_storage.dart';
import 'styles.dart';
import 'theme/app_theme_controller.dart';
import 'widgets/brand_logo.dart';

bool firebaseInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseInitialized = true;
  } catch (_) {
    // Local preview still renders the signed-out flow if Firebase is unavailable.
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _themeController = AppThemeController();

  @override
  void initState() {
    super.initState();
    _themeController.load();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, child) => MaterialApp(
        title: 'VitalMap',
        theme: AppStyles.lightTheme,
        darkTheme: AppStyles.darkTheme,
        themeMode: _themeController.themeMode,
        home: SplashGate(themeController: _themeController),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.themeController});

  final AppThemeController themeController;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _showSplash = true;

  void _handleSplashComplete() {
    if (!mounted || !_showSplash) return;
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showSplash
          ? SplashScreen(
              key: const ValueKey('splash'),
              onComplete: _handleSplashComplete,
            )
          : AuthGate(
              key: const ValueKey('auth'),
              themeController: widget.themeController,
            ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.themeController});

  final AppThemeController themeController;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _profileEnsuredForUid;

  void _ensureProfile(User user) {
    if (_profileEnsuredForUid == user.uid) return;
    _profileEnsuredForUid = user.uid;
    FirestoreService.ensureUserProfile(user).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    if (!firebaseInitialized) {
      return LoginScreen(onLogin: (_) {});
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen(onLogin: _noopLogin);
        _ensureProfile(user);
        return HomeContainer(
          key: ValueKey(user.uid),
          themeController: widget.themeController,
          onSignOut: AuthService.signOut,
          userEmail: user.email,
        );
      },
    );
  }
}

void _noopLogin(String _) {}

class HomeContainer extends StatefulWidget {
  const HomeContainer({
    super.key,
    required this.themeController,
    required this.onSignOut,
    required this.userEmail,
  });

  final VoidCallback onSignOut;
  final String? userEmail;
  final AppThemeController themeController;

  @override
  State<HomeContainer> createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {
  // 0 Home, 1 Input, 2 Result, 3 Health Map, 4 History, 5 Daily Check-in,
  // 6 Insight, 7 More.
  int _currentIndex = 0;
  Map<String, dynamic>? _lastResponse;
  Map<String, dynamic>? _lastPayload;
  DateTime? _lastChecked;
  int _dataRevision = 0;

  @override
  void initState() {
    super.initState();
    _loadLastResult();
  }

  Future<void> _loadLastResult() async {
    Map<String, dynamic>? stored;
    final user = firebaseInitialized ? FirebaseAuth.instance.currentUser : null;
    if (user != null) {
      try {
        stored = await FirestoreService.loadLatestScreening(user.uid);
      } catch (_) {}
    }
    stored ??= await LocalStorage.loadLastResponse();
    if (!mounted || stored == null) return;
    final saved = stored;
    final payload = saved['payload'];
    setState(() {
      _lastResponse = saved['response'] is Map
          ? Map<String, dynamic>.from(saved['response'] as Map)
          : null;
      _lastPayload = payload is Map
          ? Map<String, dynamic>.from(payload)
          : _lastPayload;
      final timestamp = saved['timestamp']?.toString();
      _lastChecked = timestamp == null ? null : DateTime.tryParse(timestamp);
    });
    if (_lastPayload == null) {
      final localPayload = await LocalStorage.loadLastPayload();
      if (mounted && localPayload != null) {
        setState(() => _lastPayload = localPayload);
      }
    }
  }

  void _handleAnalysisComplete(Map<String, dynamic> response) {
    setState(() {
      _lastResponse = response;
      _lastChecked = DateTime.now();
      _currentIndex = 2;
    });
    LocalStorage.loadLastPayload().then((payload) {
      if (mounted && payload != null) setState(() => _lastPayload = payload);
    });
  }

  void _go(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeOverviewScreen(
        response: _lastResponse,
        payload: _lastPayload,
        lastChecked: _lastChecked,
        onStartAnalysis: () => _go(1),
        onViewResults: () => _go(2),
        onOpenHealthMap: () => _go(3),
        onOpenHistory: () => _go(4),
        onOpenCheckIn: () => _go(5),
      ),
      InputScreen(
        key: ValueKey(_dataRevision),
        onAnalysisComplete: _handleAnalysisComplete,
      ),
      ResultsScreen(
        response: _lastResponse,
        payload: _lastPayload,
        lastChecked: _lastChecked,
      ),
      const BodyHealthMapScreen(),
      const HealthHistoryScreen(),
      const SymptomTrackerScreen(),
      const InsightScreen(),
      MoreScreen(
        key: ValueKey('${_lastChecked ?? ''}-${widget.themeController.themeMode.name}'),
        themeMode: widget.themeController.themeMode,
        onThemeModeChanged: widget.themeController.setThemeMode,
        onStartAnalysis: () => _go(1),
        onViewResults: () => _go(2),
        onSignOut: widget.onSignOut,
        onDataCleared: () => setState(() {
          _lastResponse = null;
          _lastPayload = null;
          _lastChecked = null;
          _dataRevision++;
          _currentIndex = 0;
        }),
        userEmail: widget.userEmail,
      ),
    ];

    final isDesktop = Responsive.isDesktop(context);
    final content = IndexedStack(index: _currentIndex, children: pages);
    return Scaffold(
      body: isDesktop
          ? _DesktopShell(
              currentIndex: _currentIndex,
              onTap: _go,
              child: content,
            )
          : content,
      bottomNavigationBar: isDesktop
          ? null
          : _MobileBottomNav(currentIndex: _currentIndex, onTap: _go),
    );
  }
}

class _NavItem {
  const _NavItem(this.index, this.label, this.icon, this.activeIcon);

  final int index;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(0, 'Home', Icons.home_outlined, Icons.home),
    _NavItem(1, 'Input', Icons.edit_note_outlined, Icons.edit_note),
    _NavItem(2, 'Result', Icons.insights_outlined, Icons.insights),
    _NavItem(6, 'Insight', Icons.lightbulb_outline, Icons.lightbulb),
    _NavItem(7, 'More', Icons.more_horiz, Icons.more),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.isMobile(context) ? double.infinity : 720,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .shadow
                          .withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    for (final item in _items)
                      Expanded(
                        child: _MobileNavItemButton(
                          item: item,
                          selected: currentIndex == item.index,
                          onTap: () => onTap(item.index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavItemButton extends StatelessWidget {
  const _MobileNavItemButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.surfaceContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.currentIndex,
    required this.onTap,
    required this.child,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget child;

  static const _primary = [
    _NavItem(0, 'Home', Icons.home_outlined, Icons.home),
    _NavItem(1, 'Input', Icons.edit_note_outlined, Icons.edit_note),
    _NavItem(2, 'Result', Icons.insights_outlined, Icons.insights),
  ];
  static const _intelligence = [
    _NavItem(3, 'Health Map', Icons.accessibility_new_outlined, Icons.accessibility_new),
    _NavItem(4, 'History', Icons.timeline_outlined, Icons.timeline),
    _NavItem(5, 'Daily Check-in', Icons.favorite_border, Icons.favorite),
  ];
  static const _secondary = [
    _NavItem(6, 'Insight', Icons.lightbulb_outline, Icons.lightbulb),
    _NavItem(7, 'More', Icons.more_horiz, Icons.more),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      child: Row(
        children: [
          _DesktopSidebar(
            primary: _primary,
            intelligence: _intelligence,
            secondary: _secondary,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.primary,
    required this.intelligence,
    required this.secondary,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> primary;
  final List<_NavItem> intelligence;
  final List<_NavItem> secondary;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 216,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: BrandLogoMark(size: 44, glow: true)),
              const SizedBox(height: 24),
              for (final item in primary) ...[
                _DesktopNavButton(
                  item: item,
                  selected: currentIndex == item.index,
                  onTap: () => onTap(item.index),
                ),
                const SizedBox(height: 7),
              ],
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 8, 8),
                child: Text(
                  'HEALTH INTELLIGENCE',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              for (final item in intelligence) ...[
                _DesktopNavButton(
                  item: item,
                  selected: currentIndex == item.index,
                  onTap: () => onTap(item.index),
                ),
                const SizedBox(height: 7),
              ],
              const Spacer(),
              for (final item in secondary) ...[
                _DesktopNavButton(
                  item: item,
                  selected: currentIndex == item.index,
                  onTap: () => onTap(item.index),
                ),
                const SizedBox(height: 7),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopNavButton extends StatelessWidget {
  const _DesktopNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? colors.surfaceContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colors.outlineVariant : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                size: 21,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: selected ? colors.onSurface : colors.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
