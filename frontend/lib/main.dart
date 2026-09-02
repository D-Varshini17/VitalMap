import 'dart:ui';

import 'package:flutter/material.dart';

import 'core/responsive.dart';
import 'screens/input_screen.dart';
import 'screens/login_screen.dart';
import 'screens/results_screen.dart';
import 'screens/insight_screen.dart';
import 'screens/more_screen.dart';
import 'screens/splash_screen.dart';
import 'storage/local_storage.dart';
import 'styles.dart';
import 'widgets/brand_logo.dart';

void main() {
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
  bool _loading = true;
  bool _authenticated = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final email = await LocalStorage.loadUserEmail();
    if (!mounted) return;
    setState(() {
      _email = email;
      _authenticated = email != null;
      _loading = false;
    });
  }

  Future<void> _handleLogin(String email) async {
    await LocalStorage.saveUserEmail(email);
    if (!mounted) return;
    setState(() {
      _email = email;
      _authenticated = true;
    });
  }

  Future<void> _handleSignOut() async {
    await LocalStorage.clearUserEmail();
    if (!mounted) return;
    setState(() {
      _email = null;
      _authenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _authenticated
        ? HomeContainer(
            key: const ValueKey('home'),
            onSignOut: _handleSignOut,
            userEmail: _email,
          )
        : LoginScreen(onLogin: _handleLogin);
  }
}

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
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    _loadLastResult();
  }

  Future<void> _loadLastResult() async {
    final stored = await LocalStorage.loadLastResponse();
    if (!mounted || stored == null) return;
    setState(() {
      _lastResponse = stored['response'] as Map<String, dynamic>?;
      final timestamp = stored['timestamp'] as String?;
      _lastChecked = timestamp == null ? null : DateTime.tryParse(timestamp);
    });
  }

  void _handleAnalysisComplete(Map<String, dynamic> response) {
    setState(() {
      _lastResponse = response;
      _lastChecked = DateTime.now();
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      InputScreen(onAnalysisComplete: _handleAnalysisComplete),
      ResultsScreen(response: _lastResponse, lastChecked: _lastChecked),
      const InsightScreen(),
      MoreScreen(
        onStartAnalysis: () => setState(() => _currentIndex = 0),
        onViewResults: () => setState(() => _currentIndex = 1),
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
        final showInsightPanel = constraints.maxWidth >= 1400;
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
              if (showInsightPanel)
                _DesktopInsightPanel(currentIndex: currentIndex),
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
      width: 264,
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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  BrandLogoMark(size: 44, glow: true),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VitalMap',
                          style: TextStyle(
                            color: AppStyles.navy,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'AI health companion',
                          style: TextStyle(
                            color: AppStyles.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              for (var i = 0; i < items.length; i++) ...[
                _DesktopNavButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
                const SizedBox(height: 10),
              ],
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEAF7FF), Color(0xFFFFFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppStyles.softBlueBorder),
                ),
                child: const Text(
                  'Screening insights only. Consult a qualified professional for medical decisions.',
                  style: TextStyle(
                    color: AppStyles.softBlueText,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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
          child: Row(
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                color: selected ? AppStyles.primary : AppStyles.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: selected ? AppStyles.primary : AppStyles.text,
                    fontWeight: FontWeight.w900,
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

class _DesktopNavItem {
  const _DesktopNavItem(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _DesktopInsightPanel extends StatelessWidget {
  const _DesktopInsightPanel({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final title = switch (currentIndex) {
      0 => 'Assessment Flow',
      1 => 'Result Reading',
      2 => 'Insight Guide',
      _ => 'Account Tools',
    };
    final body = switch (currentIndex) {
      0 =>
        'Move section by section: profile, lifestyle, environment, then reports. Optional labs can be added only when available.',
      1 =>
        'Risk labels explain calculated screening indicators. They do not diagnose or replace clinical care.',
      2 =>
        'Education cards connect organs, indexes, reference ranges, and everyday habits in plain language.',
      _ =>
        'Export, privacy notes, support, and saved data controls live here for release-readiness.',
    };

    return Container(
      width: 308,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.66),
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.82)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today',
                style: TextStyle(
                  color: AppStyles.tertiaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppStyles.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _PanelCard(
                icon: Icons.auto_awesome_outlined,
                title: 'AI-aware guidance',
                body: body,
              ),
              const SizedBox(height: 12),
              const _PanelCard(
                icon: Icons.verified_user_outlined,
                title: 'Privacy-first notes',
                body:
                    'Saved drafts stay local. Backend analysis is used only when an API endpoint is configured and reachable.',
              ),
              const SizedBox(height: 12),
              const _PanelCard(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Release export',
                body:
                    'Screening summaries include profile data, organ statuses, recommendations, and the medical safety disclaimer.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppStyles.border),
        boxShadow: [
          BoxShadow(
            color: AppStyles.navy.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppStyles.primary, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppStyles.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: AppStyles.muted,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
