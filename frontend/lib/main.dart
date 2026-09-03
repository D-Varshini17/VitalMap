import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/responsive.dart';
import 'firebase_options.dart';
import 'screens/input_screen.dart';
import 'screens/login_screen.dart';
import 'screens/results_screen.dart';
import 'screens/insight_screen.dart';
import 'screens/more_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'storage/local_storage.dart';
import 'styles.dart';
import 'widgets/brand_logo.dart';

bool firebaseInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (_) {
    // The app can still render its logged-out state when Firebase is not
    // configured in a local test environment.
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalMap',
      theme: AppStyles.theme,
      home: const SplashGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

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
          : const AuthGate(key: ValueKey('auth')),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen(onLogin: _noopLogin);
        }
        _ensureProfile(user);
        return HomeContainer(
          key: ValueKey(user.uid),
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
    required this.onSignOut,
    required this.userEmail,
  });

  final VoidCallback onSignOut;
  final String? userEmail;

  @override
  State<HomeContainer> createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {
  int _currentIndex = 0;
  Map<String, dynamic>? _lastResponse;
  Map<String, dynamic>? _lastPayload;
  DateTime? _lastChecked;

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
    setState(() {
      _lastResponse = saved['response'] as Map<String, dynamic>?;
      final payload = saved['payload'];
      _lastPayload = payload is Map ? Map<String, dynamic>.from(payload) : null;
      final timestamp = saved['timestamp'] as String?;
      _lastChecked = timestamp == null ? null : DateTime.tryParse(timestamp);
    });
  }

  void _handleAnalysisComplete(Map<String, dynamic> response) {
    setState(() {
      _lastResponse = response;
      _lastChecked = DateTime.now();
      _currentIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ResultsScreen(response: _lastResponse, lastChecked: _lastChecked),
      InputScreen(onAnalysisComplete: _handleAnalysisComplete),
      ResultsScreen(
        response: _lastResponse,
        payload: _lastPayload,
        lastChecked: _lastChecked,
      ),
      const InsightScreen(),
      MoreScreen(
        onStartAnalysis: () => setState(() => _currentIndex = 1),
        onViewResults: () => setState(() => _currentIndex = 2),
        onSignOut: widget.onSignOut,
        userEmail: widget.userEmail,
      ),
    ];
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: isDesktop
          ? _DesktopShell(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              child: pages[_currentIndex],
            )
          : pages[_currentIndex],
      bottomNavigationBar: isDesktop
          ? null
          : _MobileBottomNav(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _DesktopNavItem('Home', Icons.home_outlined, Icons.home),
    _DesktopNavItem('Input', Icons.edit_note_outlined, Icons.edit_note),
    _DesktopNavItem('Result', Icons.insights_outlined, Icons.insights),
    _DesktopNavItem('Insight', Icons.lightbulb_outline, Icons.lightbulb),
    _DesktopNavItem('More', Icons.more_horiz, Icons.more),
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
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppStyles.navy.withValues(alpha: 0.14),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Expanded(
                        child: _MobileNavItemButton(
                          item: _items[i],
                          selected: currentIndex == i,
                          onTap: () => onTap(i),
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

  final _DesktopNavItem item;
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
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF0B63CE), Color(0xFF22C6D5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(22),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppStyles.primary.withValues(alpha: 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                color: selected ? Colors.white : AppStyles.unitText,
                size: 22,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selected ? Colors.white : AppStyles.muted,
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

  static const _items = [
    _DesktopNavItem('Home', Icons.home_outlined, Icons.home),
    _DesktopNavItem('Input', Icons.edit_note_outlined, Icons.edit_note),
    _DesktopNavItem('Result', Icons.insights_outlined, Icons.insights),
    _DesktopNavItem(
      'Insight',
      Icons.lightbulb_outline,
      Icons.lightbulb,
    ),
    _DesktopNavItem('More', Icons.more_horiz, Icons.more),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppStyles.pageStart, AppStyles.pageEnd],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              _DesktopSidebar(
                items: _items,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_DesktopNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.78)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.navy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: BrandLogoMark(size: 42, glow: true)),
              const SizedBox(height: 30),
              for (var i = 0; i < items.length; i++) ...[
                _DesktopNavButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
                const SizedBox(height: 8),
              ],
              const Spacer(),
              const Tooltip(
                message: 'Screening insights only',
                child: Icon(Icons.info_outline, color: AppStyles.muted),
              ),
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

  final _DesktopNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFFEAF7FF), Color(0xFFFFFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppStyles.softBlueBorder : Colors.transparent,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppStyles.primary.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              selected ? item.activeIcon : item.icon,
              color: selected ? AppStyles.primary : AppStyles.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopNavItem {
  const _DesktopNavItem(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
