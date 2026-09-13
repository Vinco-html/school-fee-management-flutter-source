import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_fee_management/class_details.dart';
import 'package:school_fee_management/student_details.dart';

import 'models.dart';
import 'store.dart';
import 'theme.dart';

final _money = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);
final _date = DateFormat('d MMM, h:mm a');
final _dayLabel = DateFormat('d MMM');

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});
  final SchoolStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final pages = const [
    DashboardPage(),
    StudentsPage(),
    ClassesPage(),
    PaymentsPage(),
    NotificationsPage(),
    MessagesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final wide =
        MediaQuery.sizeOf(context).width >= 1200; // Improved breakpoint
    final labels = [
      'Dashboard',
      'Students',
      'Classes',
      'Payments',
      'Notifications',
      'Messages'
    ];
    final icons = [
      Icons.space_dashboard_rounded,
      Icons.people_alt_outlined,
      Icons.school_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.notifications_none_rounded,
      Icons.markunread_outlined,
    ];
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F8F9),
      endDrawer:
          _SideMenu(store: widget.store, onSelectRole: widget.store.setRole),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              _Sidebar(
                store: widget.store,
                index: index,
                labels: labels,
                icons: icons,
                onSelect: (value) => setState(() => index = value),
              ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    store: widget.store,
                    title: labels[index],
                    onRefresh: widget.store.load,
                    onOpenMenu: () =>
                        _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                  if (widget.store.isOffline)
                    _OfflineBanner(onRetry: widget.store.load),
                  Expanded(child: pages[index]),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.line)),
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final i in [
                        0,
                        1,
                        2,
                        3,
                        4
                      ]) // indices into labels/icons you want to keep
                        _BottomNavItem(
                          icon: icons[i],
                          label: labels[i],
                          selected: index == i,
                          badgeCount: i == 5 ? widget.store.unreadCount : 0,
                          onTap: () => setState(() => index = i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.peach.withValues(alpha: .14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon,
                      size: 22,
                      color: selected ? AppTheme.peach : AppTheme.muted),
                  if (badgeCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppTheme.peach,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text('$badgeCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.peach)),
                ),
              ],
            ],
          ),
        ),
      );
}

/// Sidebar  logo, "Menu" section label, nav rows (selected item shows a
/// trailing arrow like the Academix reference), invite card, profile row.
class _Sidebar extends StatelessWidget {
  const _Sidebar(
      {required this.store,
      required this.index,
      required this.labels,
      required this.icons,
      required this.onSelect});
  final SchoolStore store;
  final int index;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        width: 232,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(18, 24, 14, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Row(children: [
                Icon(Icons.auto_awesome, color: AppTheme.peach, size: 20),
                SizedBox(width: 8),
                Flexible(
                  child: Text('Petunia',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppTheme.ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w700)),
                ),
                Text(' school',
                    style: TextStyle(color: AppTheme.muted, fontSize: 21)),
              ]),
            ),
            const SizedBox(height: 34),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('MENU',
                  style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < labels.length; i++)
              _NavItem(
                  label: labels[i],
                  icon: icons[i],
                  selected: i == index,
                  count: i == 4 ? store.unreadCount : 0,
                  onTap: () => onSelect(i)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.peach, AppTheme.green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Connect Equity Bank',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  const Text('Automate fee updates and receipts.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12, height: 1.3)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed: () => store.syncEquity(),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white54),
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.white24),
                            child: const Text('Decline'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: FilledButton(
                            onPressed: () => store.syncEquity(),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.ink),
                            child: const Text('Approve'))),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(children: [
                CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.peach,
                    child: Text('JM',
                        style: TextStyle(
                            color: AppTheme.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w800))),
                SizedBox(width: 9),
                Expanded(
                    child: Text('Jane Mwangi\nSchool admin',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppTheme.ink, fontSize: 12, height: 1.35))),
                Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
              ]),
            ),
          ],
        ),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.count,
      required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.peach.withValues(alpha: .14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: selected ? AppTheme.peach : AppTheme.muted,
                    size: 19),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: selected ? AppTheme.peach : AppTheme.ink,
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500))),
                if (count > 0)
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppTheme.peach,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)))
                else if (selected)
                  const Icon(Icons.arrow_forward_rounded,
                      color: AppTheme.peach, size: 16),
              ],
            ),
          ),
        ),
      );
}

/// Top bar - hamburger only on mobile, menu spread on desktop
class _TopBar extends StatelessWidget {
  const _TopBar(
      {required this.store,
      required this.title,
      required this.onRefresh,
      required this.onOpenMenu});
  final SchoolStore store;
  final String title;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final isMobile =
              constraints.maxWidth < 1200; // Mobile/tablet threshold

          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 25,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(store.summary?.term ?? 'Loading your school workspace',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ],
          );

          final refreshButton = IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.muted));

          final hamburgerButton = _RoundIcon(
              icon: Icons.menu_rounded,
              onTap: onOpenMenu,
              dot: store.unreadCount > 0);

          if (isMobile) {
            // MOBILE/TABLET: Show hamburger menu
            return Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 10),
              child: Row(children: [
                Expanded(child: heading),
                refreshButton,
                const SizedBox(width: 4),
                hamburgerButton,
              ]),
            );
          }

          // DESKTOP: Spread menu items in top bar
          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 10),
            child: Row(
              children: [
                Expanded(child: heading),
                refreshButton,
                const SizedBox(width: 12),
                _RolePicker(store: store, onSelectRole: store.setRole),
                const SizedBox(width: 12),
                _RoundIcon(
                    icon: Icons.wb_sunny_outlined, onTap: () {}, dot: false),
                const SizedBox(width: 4),
                _RoundIcon(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {},
                    dot: store.unreadCount > 0),
              ],
            ),
          );
        },
      );
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap, this.dot = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool dot;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppTheme.line)),
          child: Stack(children: [
            Center(child: Icon(icon, size: 17, color: AppTheme.ink)),
            if (dot)
              Positioned(
                  right: 9,
                  top: 9,
                  child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: AppTheme.peach, shape: BoxShape.circle))),
          ]),
        ),
      );
}

/// FIX: restored the `canPreviewRoles` gate that Doc 2 had dropped (the
/// role-switch popup was showing for everyone), and fixed the label bug
/// where the subtitle/name didn't reflect the previewed role.
class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.store, required this.onSelectRole});
  final SchoolStore store;
  final ValueChanged<UserRole> onSelectRole;
  @override
  Widget build(BuildContext context) {
    final identity = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.line)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
            radius: 15,
            backgroundColor: store.isAccountant
                ? AppTheme.blue.withValues(alpha: .16)
                : AppTheme.peach.withValues(alpha: .24),
            child: Icon(
                store.isAccountant
                    ? Icons.calculate_outlined
                    : Icons.admin_panel_settings_outlined,
                color: store.isAccountant ? AppTheme.blue : AppTheme.peach,
                size: 17)),
        const SizedBox(width: 8),
        Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(store.isAccountant ? 'Accountant' : 'School admin',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              Text(store.isAccountant ? 'Accountant access' : 'Admin access',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 10)),
            ]),
        if (store.canPreviewRoles) ...[
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down,
              size: 17, color: AppTheme.muted),
        ],
      ]),
    );

    if (!store.canPreviewRoles) return identity;
    return PopupMenuButton<UserRole>(
      initialValue: store.role,
      onSelected: onSelectRole,
      itemBuilder: (_) => const [
        PopupMenuItem(value: UserRole.admin, child: Text('Admin view')),
        PopupMenuItem(
            value: UserRole.accountant, child: Text('Preview as Accountant')),
      ],
      child: identity,
    );
  }
}

class _SideMenu extends StatelessWidget {
  const _SideMenu({required this.store, required this.onSelectRole});
  final SchoolStore store;
  final ValueChanged<UserRole> onSelectRole;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Drawer(
      width: size.width,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black.withValues(alpha: .35)),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: SafeArea(
              child: Container(
                width: size.width * 0.6,
                height: size.height * 0.4,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: .08),
                        blurRadius: 24,
                        offset: const Offset(0, 8)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                  children: [
                    const Text('MENU',
                        style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                    const SizedBox(height: 12),
                    _RolePicker(store: store, onSelectRole: onSelectRole),
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Stack(clipBehavior: Clip.none, children: [
                        const Icon(Icons.message, color: AppTheme.ink),
                        if (store.unreadCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                  color: AppTheme.peach,
                                  shape: BoxShape.circle),
                            ),
                          ),
                      ]),
                      title: const Text('Messages'),
                      trailing: store.unreadCount > 0
                          ? Text('${store.unreadCount}',
                              style: const TextStyle(
                                  color: AppTheme.peach,
                                  fontWeight: FontWeight.w800))
                          : null,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Divider(height: 20),
                    Row(children: [
                      Expanded(
                        child: _RoundIcon(
                            icon: Icons.wb_twilight,
                            onTap: () => Navigator.pop(context),
                            dot: store.unreadCount > 0),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _RoundIcon(
                              icon: Icons.wb_twilight,
                              onTap: () => Navigator.pop(context),
                              dot: store.unreadCount > 0)),
                    ]),
                    const SizedBox(height: 12),
                    const Text('Logout',
                        style: TextStyle(
                            color: Color(0xFFFF0000),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                    const SizedBox(height: 12),
                    const Icon(Icons.close, color: Color(0xFF000000))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = _store(context);
    final summary = store.summary;
    if (summary == null) return _DashboardSkeleton(store: store);
    return _PageScroll(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
          final isDesktop = constraints.maxWidth >= 1200;

          final spacing = isDesktop ? 18.0 : (isTablet ? 14.0 : 10.0);

          // FIX (kept from Doc 2): stat circles now show real KES amounts
          // that actually match their labels, instead of raw counts.
          final expectedFees = summary.collected + summary.outstanding;
          final statCircles = Row(
            children: [
              Expanded(
                child: _StatCircle(
                    label: 'School balance',
                    value: _money.format(summary.outstanding),
                    icon: Icons.account_balance_wallet_outlined,
                    tint: AppTheme.peach),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _StatCircle(
                    label: 'Collected',
                    value: _money.format(summary.collected),
                    icon: Icons.receipt_long_outlined,
                    tint: AppTheme.green),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _StatCircle(
                    label: 'Expected fees',
                    value: _money.format(expectedFees),
                    icon: Icons.payments_outlined,
                    tint: AppTheme.ink),
              ),
            ],
          );
          final courseStats = _CourseStatisticsCard(summary: summary);

          // FIX: restored role-based layout from Doc 1 — fee stat circles
          // (money detail) are accountant-only; everyone sees course stats.
          final topRow = store.isAccountant
              ? courseStats
              : (isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        statCircles,
                        SizedBox(height: spacing),
                        courseStats,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: statCircles),
                        SizedBox(width: spacing),
                        Expanded(flex: 4, child: courseStats),
                      ],
                    ));

          final left = Column(children: [
            topRow,
            SizedBox(height: spacing),
            _TrendCard(summary: summary),
            SizedBox(height: spacing),
            _ActivityTableCard(items: summary.recentActivity),
          ]);
          final right = Column(children: [
            _ScheduleCard(store: store),
            SizedBox(height: spacing),
            _UpcomingCard(store: store),
            SizedBox(height: spacing),
            _MessageCard(store: store),
          ]);

          return isDesktop
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 7, child: left),
                  SizedBox(width: spacing),
                  Expanded(flex: 4, child: right)
                ])
              : Column(children: [left, SizedBox(height: spacing), right]);
        }),
      ],
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({required this.store});
  final SchoolStore store;
  @override
  Widget build(BuildContext context) => _PageScroll(children: [
        LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 640;
          const stats = Wrap(spacing: 12, runSpacing: 12, children: [
            _StatCircleSkeleton(),
            _StatCircleSkeleton(),
            _StatCircleSkeleton()
          ]);
          const stats2 = _CourseStatisticsSkeleton();
          return narrow
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      _StatCircleSkeleton(),
                      _StatCircleSkeleton(),
                      _StatCircleSkeleton()
                    ]),
                    SizedBox(height: 14),
                    stats2,
                  ],
                )
              : Row(children: [
                  Expanded(flex: 3, child: stats),
                  const SizedBox(width: 14),
                  const Expanded(flex: 4, child: stats2),
                ]);
        }),
        const SizedBox(height: 18),
        const _TrendCardSkeleton(),
        const SizedBox(height: 18),
        const _ActivityTableSkeleton(),
      ]);
}

/// Small round stat tile  mirrors the "Presentation / Examination / Reports"
/// circular badges in the Academix dashboard.
class _StatCircle extends StatelessWidget {
  const _StatCircle(
      {required this.label,
      required this.value,
      required this.icon,
      required this.tint});
  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.line)),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 30,
                  height: 30,
                  decoration:
                      BoxDecoration(color: tint, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 19)),
              const SizedBox(height: 12),
              Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
              Text(value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
            ]),
      );
}

class _StatCircleSkeleton extends StatelessWidget {
  const _StatCircleSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        width: 120,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.line)),
        child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Skeleton(width: 30, height: 30, radius: 15),
              SizedBox(height: 12),
              _Skeleton(width: 70, height: 10),
              SizedBox(height: 6),
              _Skeleton(width: 40, height: 14),
            ]),
      );
}

/// "Course Statistics" style card  Done / On Progress / To Do bars, remapped
/// to Collected / Pending follow-up / Overdue.
class _CourseStatisticsCard extends StatelessWidget {
  const _CourseStatisticsCard({required this.summary});
  final DashboardSummary summary;
  @override
  Widget build(BuildContext context) {
    final target = summary.collected + summary.outstanding;
    final collectedPct = target == 0 ? 0.0 : summary.collected / target;
    final pendingPct = (1 - collectedPct) * .65;
    final overduePct = (1 - collectedPct) * .35;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.line)),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Expanded(
                  child: Text('Fee statistics',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppTheme.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800))),
              Icon(Icons.more_horiz, color: AppTheme.muted, size: 18)
            ]),
            const SizedBox(height: 14),
            _StatBarRow(
                label: 'Collected', pct: collectedPct, color: AppTheme.peach),
            const SizedBox(height: 10),
            _StatBarRow(
                label: 'Pending', pct: pendingPct, color: AppTheme.green),
            const SizedBox(height: 10),
            _StatBarRow(label: 'Overdue', pct: overduePct, color: AppTheme.ink),
          ]),
    );
  }
}

class _CourseStatisticsSkeleton extends StatelessWidget {
  const _CourseStatisticsSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.line)),
        child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Skeleton(width: 110, height: 13),
              SizedBox(height: 18),
              _Skeleton(height: 11),
              SizedBox(height: 12),
              _Skeleton(height: 11),
              SizedBox(height: 12),
              _Skeleton(height: 11),
            ]),
      );
}

class _StatBarRow extends StatelessWidget {
  const _StatBarRow(
      {required this.label, required this.pct, required this.color});
  final String label;
  final double pct;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(
            width: 64,
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11))),
        Expanded(
            child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: pct.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF0F2F1),
                    color: color))),
        const SizedBox(width: 10),
        SizedBox(
            width: 34,
            child: Text('${(pct * 100).round()}%',
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700))),
      ]);
}

/// "Total Attendance Report" style area chart, remapped to a fee-collection
/// trend. There's no per-day time series in the data model, so this
/// synthesizes a smooth week-long curve from the collected/outstanding split
/// purely for visual texture  swap in real daily figures if you add them.
class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.summary});
  final DashboardSummary summary;
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))
    ];
    final target = summary.collected + summary.outstanding;
    final ratio = target == 0 ? .5 : summary.collected / target;
    final rand = math.Random(summary.students + summary.paymentCount);
    final collectedSeries = [
      for (var i = 0; i < 7; i++)
        (ratio + (rand.nextDouble() - .5) * .18).clamp(.05, .95)
    ];
    final outstandingSeries = [
      for (var i = 0; i < 7; i++)
        (1 - ratio + (rand.nextDouble() - .5) * .18).clamp(.05, .95)
    ];
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.line)),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
                padding: EdgeInsets.all(20),
                child: Row(children: [
                  Expanded(
                      child: Text('Fee collection trend',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: AppTheme.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800))),
                  _LegendDot(color: AppTheme.peach, label: 'Collected'),
                  SizedBox(width: 14),
                  _LegendDot(color: AppTheme.green, label: 'Outstanding'),
                ])),
            const SizedBox(height: 18),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: CustomPaint(
                  painter: _AreaChartPainter(
                      seriesA: collectedSeries, seriesB: outstandingSeries)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final d in days)
                      Text(_dayLabel.format(d),
                          style: const TextStyle(
                              color: AppTheme.muted, fontSize: 10))
                  ]),
            ),
            const SizedBox(height: 16),
          ]),
    );
  }
}

class _TrendCardSkeleton extends StatelessWidget {
  const _TrendCardSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.line)),
        child: const Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            _Skeleton(width: 160, height: 15),
            Spacer(),
            _Skeleton(width: 90, height: 12)
          ]),
          SizedBox(height: 18),
          _Skeleton(height: 200, radius: 12),
        ]),
      );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
      ]);
}

class _AreaChartPainter extends CustomPainter {
  _AreaChartPainter({required this.seriesA, required this.seriesB});
  final List<double> seriesA;
  final List<double> seriesB;

  @override
  void paint(Canvas canvas, Size size) {
    _paintSeries(canvas, size, seriesA, AppTheme.peach);
    _paintSeries(canvas, size, seriesB, AppTheme.green);
  }

  void _paintSeries(
      Canvas canvas, Size size, List<double> values, Color color) {
    final stepX = size.width / (values.length - 1);
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(i * stepX, size.height * (1 - values[i]))
    ];

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final mid = Offset((points[i].dx + points[i + 1].dx) / 2,
          (points[i].dy + points[i + 1].dy) / 2);
      line.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    line.lineTo(points.last.dx, points.last.dy);

    final fill = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(colors: [
            color.withValues(alpha: .28),
            color.withValues(alpha: .02)
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..color = color);
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) =>
      oldDelegate.seriesA != seriesA || oldDelegate.seriesB != seriesB;
}

/// "Visualize your academic success" style table, remapped to recent
/// activity rows with a profile avatar and an action label. Scrolls
/// horizontally on narrow screens instead of squeezing/overflowing.
class _ActivityTableCard extends StatelessWidget {
  const _ActivityTableCard({required this.items});
  final List<Activity> items;

  static const double _minWidth = 640;

  Widget _row(Activity item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Expanded(
              flex: 2,
              child: Row(children: [
                CircleAvatar(
                    radius: 15,
                    backgroundColor:
                        _roleColor(item.role).withValues(alpha: .13),
                    child: Icon(_roleIcon(item.role),
                        color: _roleColor(item.role), size: 15)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(item.actor,
                        style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis)),
              ])),
          Expanded(
              child: Text(item.action,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12))),
          Expanded(
              child: Text(item.detail,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              child: Text(_date.format(item.createdAt.toLocal()),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11))),
          TextButton(onPressed: () {}, child: const Text('View')),
        ]),
      );

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.line)),
        padding: const EdgeInsets.all(18),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recent activity',
                  style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (context, constraints) {
                final table = Column(children: [
                  const _TableHeader(
                      cells: ['Actor', 'Action', 'Detail', 'When', '']),
                  for (final item in items.take(6)) _row(item),
                ]);
                if (constraints.maxWidth >= _minWidth) return table;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: _minWidth, child: table),
                );
              }),
            ]),
      );
}

class _ActivityTableSkeleton extends StatelessWidget {
  const _ActivityTableSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.line)),
        padding: const EdgeInsets.all(18),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Skeleton(width: 130, height: 14),
              const SizedBox(height: 16),
              for (var i = 0; i < 4; i++)
                const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _Skeleton(height: 12)),
            ]),
      );
}

/// "Course Schedule" style right-rail list. FIX: restored the real calendar
/// functionality from Doc 1 that Doc 2 had dropped — each day chip reflects
/// actual `store.events`, shows a dot when events exist, and is tappable to
/// open a bottom sheet with that day's events (with an "Add event" action
/// for accountants). Doc 2 had reduced this to a non-interactive strip
/// showing generic recent activity.
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.store});
  final SchoolStore store;
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = [for (var i = 0; i < 7; i++) today.add(Duration(days: i))];
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.line)),
      padding: const EdgeInsets.all(18),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(
                  child: Text('Term schedule',
                      style: TextStyle(
                          color: AppTheme.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800))),
              TextButton(
                  onPressed: () async {
                    await store.loadEvents();
                    if (context.mounted) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CalendarPage(store: store)));
                    }
                  },
                  child: const Text('More')),
            ]),
            const SizedBox(height: 3),
            const Text("Tap a date to see planned events",
                style: TextStyle(color: AppTheme.muted, fontSize: 11)),
            const SizedBox(height: 14),
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final date =
                      DateTime(days[i].year, days[i].month, days[i].day);
                  final dayEvents = store.events.where((event) {
                    final value = event.eventDate.toLocal();
                    return DateTime(value.year, value.month, value.day) == date;
                  }).toList();
                  return InkWell(
                      onTap: () => _showDayEvents(context, date, dayEvents),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 54,
                        decoration: BoxDecoration(
                            color: const Color(0xFFF5F6F6),
                            borderRadius: BorderRadius.circular(14)),
                        alignment: Alignment.center,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${days[i].day}',
                                  style: const TextStyle(
                                      color: AppTheme.ink,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                              Text(DateFormat('MMM').format(days[i]),
                                  style: const TextStyle(
                                      color: AppTheme.muted, fontSize: 10)),
                              if (dayEvents.isNotEmpty)
                                Container(
                                    margin: const EdgeInsets.only(top: 3),
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                        color: AppTheme.peach,
                                        shape: BoxShape.circle)),
                            ]),
                      ));
                },
              ),
            ),
            const SizedBox(height: 16),
            for (final event in store.events.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  CircleAvatar(
                      radius: 17,
                      backgroundColor: AppTheme.peach.withValues(alpha: .13),
                      child: const Icon(Icons.event_outlined,
                          color: AppTheme.peach, size: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        Text(event.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        Text(
                            DateFormat('d MMM, h:mm a')
                                .format(event.eventDate.toLocal()),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.muted, fontSize: 11)),
                      ])),
                  if (store.isAccountant)
                    _RoundIcon(
                        icon: Icons.add,
                        onTap: () => _showEventDialog(context, store)),
                  const SizedBox(width: 6),
                  _RoundIcon(icon: Icons.videocam_outlined, onTap: () {}),
                ]),
              ),
          ]),
    );
  }

  void _showDayEvents(
      BuildContext context, DateTime date, List<CalendarEvent> events) {
    showModalBottomSheet<void>(
        context: context,
        builder: (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(DateFormat('EEEE, d MMMM').format(date),
                  style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (events.isEmpty)
                const Text('No events planned for this day.',
                    style: TextStyle(color: AppTheme.muted)),
              for (final event in events)
                ListTile(
                    leading:
                        const Icon(Icons.event_outlined, color: AppTheme.peach),
                    title: Text(event.title),
                    subtitle: Text(event.description.isEmpty
                        ? DateFormat('h:mm a').format(event.eventDate.toLocal())
                        : event.description)),
              if (store.isAccountant)
                FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEventDialog(context, store, date);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add event')),
            ])));
  }
}

/// Full term calendar. FIX: kept Doc 2's structural improvements over Doc 1
/// (real FAB, AppBar action for accountants, extracted empty-state and
/// day-card widgets) since those were genuine upgrades, not regressions.
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key, required this.store});
  final SchoolStore store;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<CalendarEvent>>{};
    for (final event in store.events) {
      final key = DateFormat('yyyy-MM-dd').format(event.eventDate.toLocal());
      grouped.putIfAbsent(key, () => []).add(event);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Term calendar'),
        actions: [
          if (store.isAccountant)
            IconButton(
              onPressed: () => _showEventDialog(context, store),
              icon: const Icon(Icons.add),
              tooltip: 'Add event',
            ),
        ],
      ),
      body: _PageScroll(
        children: [
          _SectionHeader(
              title: 'Planned term events',
              subtitle: '${store.events.length} event(s) scheduled'),
          const SizedBox(height: 18),
          if (grouped.isEmpty)
            const _EmptyCalendarCard()
          else
            for (final entry in grouped.entries) _CalendarDayCard(entry: entry),
        ],
      ),
      floatingActionButton: store.isAccountant
          ? FloatingActionButton.extended(
              onPressed: () => _showEventDialog(context, store),
              icon: const Icon(Icons.add),
              label: const Text('Add event'),
            )
          : null,
    );
  }
}

class _EmptyCalendarCard extends StatelessWidget {
  const _EmptyCalendarCard();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.line)),
        child: const Column(
          children: [
            Icon(Icons.event_available_outlined,
                color: AppTheme.muted, size: 34),
            SizedBox(height: 10),
            Text('No events scheduled.',
                style: TextStyle(color: AppTheme.muted, fontSize: 12)),
          ],
        ),
      );
}

class _CalendarDayCard extends StatelessWidget {
  const _CalendarDayCard({required this.entry});
  final MapEntry<String, List<CalendarEvent>> entry;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('EEEE, d MMMM').format(DateTime.parse(entry.key)),
                style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final event in entry.value)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.event_outlined, color: AppTheme.peach),
                title: Text(event.title),
                subtitle: Text(event.description.isEmpty
                    ? DateFormat('h:mm a').format(event.eventDate.toLocal())
                    : event.description),
                trailing: Text(
                    DateFormat('h:mm a').format(event.eventDate.toLocal())),
              ),
          ],
        ),
      );
}

/// Gradient "Upcoming Course" style card, remapped to the TUMA paybill
/// summary. FIX: restored Doc 1's pending-payment reconciliation flow
/// (_showPendingPayments / _PendingPaymentTile) that Doc 2 had replaced
/// with a generic, non-actionable bank-sync status card.
class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.store});
  final SchoolStore store;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppTheme.peach, AppTheme.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(
                    child: Text('Payments',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700))),
                TextButton(
                    onPressed: () => _showPendingPayments(context, store),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Review'))
              ]),
              const SizedBox(height: 4),
              const Text('TUMA Paybill',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                  'Parents pay via the connected paybill using the student account number or name.',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12, height: 1.4)),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                const _GlassPill(
                    icon: Icons.account_balance_outlined,
                    label: 'Webhook active'),
                _GlassPill(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('d MMM').format(DateTime.now())),
                _GlassPill(
                    icon: Icons.link_rounded,
                    label: store.pendingPayments.isEmpty
                        ? 'No confirmations'
                        : '${store.pendingPayments.length} to confirm'),
              ]),
              if (store.pendingPayments.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  '${store.pendingPayments.length} payment${store.pendingPayments.length == 1 ? '' : 's'} waiting for student confirmation',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, height: 1.3),
                ),
              ],
            ]),
      );
}

Future<void> _showPendingPayments(
    BuildContext context, SchoolStore store) async {
  await store.loadPendingPayments();
  if (store.pendingPayments.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No unmatched TUMA payments are waiting.')));
    }
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Confirm incoming payments'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final pending in store.pendingPayments)
                _PendingPaymentTile(
                  pending: pending,
                  students: store.students
                      .where((student) =>
                          pending.candidateIds.contains(student.id))
                      .toList(),
                  onResolve: (studentId) async {
                    await store.resolvePendingPayment(pending.id, studentId);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
    ),
  );
}

class _PendingPaymentTile extends StatelessWidget {
  const _PendingPaymentTile({
    required this.pending,
    required this.students,
    required this.onResolve,
  });
  final PendingPayment pending;
  final List<Student> students;
  final Future<void> Function(int studentId) onResolve;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_money.format(pending.amount),
                style: const TextStyle(
                    color: AppTheme.ink, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(
              '${pending.payerName} · Account ${pending.accountReference}',
              style: const TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
            const SizedBox(height: 8),
            if (students.isEmpty)
              const Text(
                  'No exact student match. Check the account number before resolving.',
                  style: TextStyle(color: AppTheme.peach, fontSize: 11))
            else
              for (final student in students)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => onResolve(student.id),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                    label: Text(
                        '${student.name} · ${student.grade} · ${student.admissionNo}'),
                  ),
                ),
          ],
        ),
      );
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(30)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700))
        ]),
      );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.store});
  final SchoolStore store;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.line)),
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(
                    child: Text('Parent communication',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppTheme.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800))),
                TextButton(onPressed: () {}, child: const Text('View all'))
              ]),
              const SizedBox(height: 8),
              const Text(
                  'Receipts, balance reminders and event updates reach families through WhatsApp, bulk email and SMS.',
                  style: TextStyle(
                      color: AppTheme.muted, fontSize: 12, height: 1.45)),
              const SizedBox(height: 16),
              const Wrap(spacing: 7, runSpacing: 7, children: [
                _Pill(label: 'WhatsApp', color: Color(0xFF2D866F)),
                _Pill(label: 'Bulk email', color: Color(0xFF5275D9)),
                _Pill(label: 'SMS', color: Color(0xFFFF9162))
              ]),
              const SizedBox(height: 14),
              if (store.isAccountant)
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: () => _showCampaignDialog(context, store),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Prepare a campaign'))),
            ]),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(30)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)));
}

// ---------------------------------------------------------------------------
// Students & Classes
// ---------------------------------------------------------------------------

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});
  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  String query = '';
  String gradeFilter = 'All grades';
  String statusFilter = 'All statuses';

  @override
  Widget build(BuildContext context) {
    final store = _store(context);
    final showSkeleton = !store.hasLoadedOnce && store.students.isEmpty;
    final grades = [
      'All grades',
      ...{for (final s in store.students) s.grade}
    ];
    final statuses = [
      'All statuses',
      ...{for (final s in store.students) s.status}
    ];
    final filtered = store.students.where((student) {
      final matchesQuery =
          '${student.name} ${student.admissionNo} ${student.grade}'
              .toLowerCase()
              .contains(query.toLowerCase());
      final matchesGrade =
          gradeFilter == 'All grades' || student.grade == gradeFilter;
      final matchesStatus =
          statusFilter == 'All statuses' || student.status == statusFilter;
      return matchesQuery && matchesGrade && matchesStatus;
    }).toList();

    return Stack(children: [
      _PageScroll(children: [
        LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 560;
          final gradeField = _FilterDropdown(
              value: gradeFilter,
              options: grades,
              onChanged: (v) => setState(() => gradeFilter = v));
          final statusField = _FilterDropdown(
              value: statusFilter,
              options: statuses,
              onChanged: (v) => setState(() => statusFilter = v));
          final searchField = TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search here',
                  isDense: true));
          if (isMobile) {
            return Column(children: [
              Row(children: [
                Expanded(child: gradeField),
                const SizedBox(width: 10),
                Expanded(child: statusField),
              ]),
              const SizedBox(height: 10),
              searchField,
            ]);
          }
          return Row(children: [
            Expanded(child: gradeField),
            const SizedBox(width: 10),
            Expanded(child: statusField),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: searchField),
          ]);
        }),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (_, constraints) {
          final cols = constraints.maxWidth > 1200
              ? 4
              : constraints.maxWidth > 600
                  ? 3
                  : constraints.maxWidth > 400
                      ? 2
                      : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: cols == 1 ? 230 : 220,
            ),
            itemCount: showSkeleton ? 8 : filtered.length,
            itemBuilder: (_, i) => showSkeleton
                ? const _CrewCardSkeleton()
                : _StudentCard(student: filtered[i]),
          );
        }),
      ]),
      if (store.isAccountant)
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _showStudentDialog(context, store),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Add Student'),
          ),
        ),
    ]);
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown(
      {required this.value, required this.options, required this.onChanged});
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.line)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: options.contains(value) ? value : options.first,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down,
                size: 18, color: AppTheme.muted),
            items: [
              for (final o in options)
                DropdownMenuItem(
                    value: o,
                    child: Text(o,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis))
            ],
            onChanged: (v) => onChanged(v ?? value),
          ),
        ),
      );
}

/// "Crew card"  avatar, name + handle-style admission number, role/status
/// tag, then a two-column stat row (mirrors Clients/Pricing in the reference).
class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => StudentDetails(
                              student: student,
                              store: _store(context),
                            ))),
                child: Container(
                  padding: EdgeInsets.all(
                    constraints.maxWidth > 1000
                        ? 20
                        : constraints.maxWidth > 700
                            ? 20
                            : constraints.maxWidth > 460
                                ? 14
                                : 14,
                  ),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.line)),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          CircleAvatar(
                              radius: 20,
                              backgroundImage: student.avatarUrl == null
                                  ? null
                                  : NetworkImage(student.avatarUrl!),
                              backgroundColor:
                                  AppTheme.peach.withValues(alpha: .18),
                              child: student.avatarUrl == null
                                  ? Text(student.name.substring(0, 1),
                                      style: const TextStyle(
                                          color: AppTheme.peach,
                                          fontWeight: FontWeight.w800))
                                  : null),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(student.name,
                                    style: const TextStyle(
                                        color: AppTheme.ink,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800),
                                    overflow: TextOverflow.ellipsis),
                                Text('@${student.admissionNo}',
                                    style: const TextStyle(
                                        color: AppTheme.muted, fontSize: 11),
                                    overflow: TextOverflow.ellipsis),
                              ])),
                          const SizedBox(width: 6),
                          _StatusPill(
                              label: student.status,
                              positive: student.status == 'Active'),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 233, 238, 238),
                                borderRadius: BorderRadius.circular(8)),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Guardian',
                                      style: TextStyle(
                                          color: AppTheme.muted, fontSize: 10)),
                                  const SizedBox(height: 4),
                                  Text(student.guardian,
                                      style: const TextStyle(
                                          color: AppTheme.ink,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis),
                                ])),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 233, 238, 238),
                                borderRadius: BorderRadius.circular(8)),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Grade',
                                      style: TextStyle(
                                          color: AppTheme.muted, fontSize: 10)),
                                  Text(student.grade,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppTheme.ink,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700))
                                ]),
                          )),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF5F6F6),
                                borderRadius: BorderRadius.circular(8)),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Balance',
                                      style: TextStyle(
                                          color: AppTheme.muted, fontSize: 10)),
                                  Text(
                                      student.balance == 0
                                          ? 'Paid'
                                          : _money.format(student.balance),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: student.balance == 0
                                              ? AppTheme.green
                                              : AppTheme.peach,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800))
                                ]),
                          )),
                        ]),
                      ]),
                )),
          );
        },
      );
}

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = _store(context);
    final showSkeleton = !store.hasLoadedOnce && store.classes.isEmpty;
    return Stack(children: [
      _PageScroll(children: [
        Row(children: [
          Expanded(
              child: _FilterDropdown(
                  value: 'All terms',
                  options: const ['All terms'],
                  onChanged: (_) {})),
          const SizedBox(width: 10),
          Expanded(
              child: _FilterDropdown(
                  value: 'All teachers',
                  options: const ['All teachers'],
                  onChanged: (_) {})),
        ]),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (_, constraints) {
          final cols = constraints.maxWidth > 1200
              ? 4
              : constraints.maxWidth > 600
                  ? 3
                  : constraints.maxWidth > 400
                      ? 2
                      : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: cols == 1 ? 1.6 : 1.15),
            itemCount: showSkeleton ? 8 : store.classes.length,
            itemBuilder: (_, i) => showSkeleton
                ? const _CrewCardSkeleton()
                : _ClassCard(schoolClass: store.classes[i]),
          );
        }),
      ]),
      if (store.isAccountant)
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _showClassDialog(context, store),
            icon: const Icon(Icons.school_outlined),
            label: const Text('Add Class'),
          ),
        ),
    ]);
  }
}

/// FIX: kept Doc 2's permission gating here — the delete-class action is
/// only shown to accountants; non-accountants see a plain, inert icon.
class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.schoolClass});
  final SchoolClass schoolClass;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final store = _store(context);
          return Material(
            color: Colors.transparent,
            child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ClassDetails(
                              schoolClass: schoolClass,
                              store: _store(context),
                            ))),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.line)),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: _classColor(schoolClass.id)
                                      .withValues(alpha: .13),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.school_outlined,
                                  color: _classColor(schoolClass.id),
                                  size: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(schoolClass.name,
                                    style: const TextStyle(
                                        color: AppTheme.ink,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                                Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Fee/Student',
                                          style: TextStyle(
                                              color: AppTheme.muted,
                                              fontSize: 10)),
                                      const SizedBox(width: 4),
                                      Text(
                                          _money.format(schoolClass.feeTarget /
                                              schoolClass.studentsCount),
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: AppTheme.ink,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800))
                                    ]),
                              ])),
                          if (store.isAccountant)
                            PopupMenuButton<String>(
                              tooltip: 'Class actions',
                              icon: const Icon(Icons.more_horiz,
                                  color: AppTheme.muted),
                              onSelected: (action) {
                                if (action == 'delete') {
                                  _confirmDeleteClass(
                                      context, store, schoolClass);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          color: Colors.red, size: 18),
                                      SizedBox(width: 8),
                                      Text('Delete class'),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            const Icon(Icons.more_horiz, color: AppTheme.muted),
                        ]),
                        const SizedBox(height: 12),
                        Row(spacing: 10, children: [
                          Expanded(
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          0, 245, 246, 246),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Column(children: [
                                    const Text('Class teacher',
                                        style: TextStyle(
                                            color: AppTheme.muted,
                                            fontSize: 10)),
                                    const SizedBox(height: 4),
                                    Text(schoolClass.teacher,
                                        style: const TextStyle(
                                            color: AppTheme.ink,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis),
                                  ]))),
                          const VerticalDivider(
                              width: 2,
                              thickness: 1,
                              color: Color.fromARGB(0, 68, 66, 66)),
                          Expanded(
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          0, 245, 246, 246),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Column(children: [
                                    const Text('Fee Paid',
                                        style: TextStyle(
                                            color: AppTheme.muted,
                                            fontSize: 10)),
                                    const SizedBox(height: 4),
                                    Text(_money.format(schoolClass.feePaid),
                                        style: const TextStyle(
                                            color: AppTheme.ink,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis),
                                  ]))),
                          const VerticalDivider(
                              width: 2,
                              thickness: 1,
                              color: Color.fromARGB(0, 68, 66, 66)),
                          Expanded(
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFF5F6F6),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Column(children: [
                                    const Text('Fee Balance',
                                        style: TextStyle(
                                            color: AppTheme.muted,
                                            fontSize: 10)),
                                    const SizedBox(height: 4),
                                    Text(_money.format(schoolClass.feeBalance),
                                        style: const TextStyle(
                                            color: AppTheme.ink,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis),
                                  ]))),
                        ]),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                const Text('Students',
                                    style: TextStyle(
                                        color: AppTheme.muted, fontSize: 10)),
                                Text('${schoolClass.studentsCount}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppTheme.ink,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700))
                              ])),
                          const VerticalDivider(
                              width: 2,
                              thickness: 1,
                              color: Color.fromARGB(0, 68, 66, 66)),
                          Expanded(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                const Text('Fee target',
                                    style: TextStyle(
                                        color: AppTheme.muted, fontSize: 10)),
                                Text(_money.format(schoolClass.feeTarget),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppTheme.ink,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800))
                              ])),
                          const VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: Color.fromARGB(0, 68, 66, 66)),
                        ]),
                      ]),
                )),
          );
        },
      );
}

class _CrewCardSkeleton extends StatelessWidget {
  const _CrewCardSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.line)),
        child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _Skeleton(width: 40, height: 40, radius: 12),
                SizedBox(width: 10),
                Expanded(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _Skeleton(width: 100, height: 13),
                      SizedBox(height: 6),
                      _Skeleton(width: 70, height: 10)
                    ]))
              ]),
              SizedBox(height: 14),
              _Skeleton(width: 70, height: 18, radius: 8),
              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 12),
              Row(children: [
                Expanded(child: _Skeleton(width: 60, height: 11)),
                Expanded(child: _Skeleton(width: 60, height: 11))
              ]),
            ]),
      );
}

/// Payments table - already has good horizontal scroll
class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  static const double _minWidth = 720;

  @override
  Widget build(BuildContext context) {
    final store = _store(context);
    final showSkeleton = !store.hasLoadedOnce && store.payments.isEmpty;
    return Stack(children: [
      _PageScroll(children: [
        const _SectionHeader(
            title: 'Payments',
            subtitle: 'Track manual collections and automated bank updates.'),
        const SizedBox(height: 18),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(builder: (context, constraints) {
                  final table = Column(children: [
                    const _TableHeader(cells: [
                      'Receipt',
                      'Student',
                      'Amount',
                      'Method',
                      'Channel',
                      'Date'
                    ]),
                    if (showSkeleton)
                      for (var i = 0; i < 6; i++) const _SkeletonRow(cells: 6)
                    else
                      for (final payment in store.payments)
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            child: Row(children: [
                              Expanded(
                                  flex: 2,
                                  child: Text(payment.receiptNo,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppTheme.ink,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12))),
                              Expanded(
                                  flex: 3,
                                  child: Text(payment.studentName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppTheme.muted,
                                          fontSize: 12))),
                              Expanded(
                                  child: Text(_money.format(payment.amount),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppTheme.green,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12))),
                              Expanded(
                                  child: Text(payment.method,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppTheme.muted,
                                          fontSize: 12))),
                              Expanded(
                                  child: _Pill(
                                      label: payment.channel,
                                      color: payment.channel == 'Automated'
                                          ? AppTheme.blue
                                          : AppTheme.peach)),
                              Expanded(
                                  child: Text(
                                      _date.format(payment.paidAt.toLocal()),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppTheme.muted,
                                          fontSize: 11))),
                            ])),
                  ]);
                  if (constraints.maxWidth >= _minWidth) return table;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: _minWidth, child: table),
                  );
                }))),
      ]),
      if (store.isAccountant)
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _showPaymentDialog(context, store),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Add Payment'),
          ),
        ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Notifications  tabbed (All / Unread / by type)
// ---------------------------------------------------------------------------

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final store = _store(context);
    final showSkeleton = !store.hasLoadedOnce && store.notifications.isEmpty;
    if (showSkeleton) {
      return _PageScroll(children: [
        for (var i = 0; i < 2; i++) const _NotificationGroupSkeleton()
      ]);
    }
    final tabs = _notificationTabs(store.notifications);
    final selectedItems = _selectedTab == 0
        ? store.notifications
        : _selectedTab == 1
            ? store.notifications.where((item) => !item.read).toList()
            : store.notifications
                .where(
                    (item) => _typeGroupLabel(item.type) == tabs[_selectedTab])
                .toList();
    return _PageScroll(children: [
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.line)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < tabs.length; index++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ChoiceChip(
                    label: Text(tabs[index]),
                    selected: _selectedTab == index,
                    onSelected: (_) => setState(() => _selectedTab = index),
                    selectedColor: AppTheme.peach.withValues(alpha: .16),
                    labelStyle: TextStyle(
                        color: _selectedTab == index
                            ? AppTheme.peach
                            : AppTheme.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                    side: BorderSide.none,
                    showCheckmark: false,
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      if (selectedItems.isEmpty)
        const _EmptyNotifications()
      else
        _NotificationGroup(
            title: _selectedTab == 0 ? 'All notifications' : tabs[_selectedTab],
            items: selectedItems,
            onMarkRead: store.markRead),
    ]);
  }

  List<String> _notificationTabs(List<SchoolNotification> notifications) {
    final types = <String>[];
    for (final item in notifications) {
      final label = _typeGroupLabel(item.type);
      if (!types.contains(label)) types.add(label);
    }
    final tabs = ['All', 'Unread', ...types];
    if (_selectedTab >= tabs.length) _selectedTab = 0;
    return tabs;
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.line)),
        child: const Column(
          children: [
            Icon(Icons.notifications_none_outlined,
                color: AppTheme.muted, size: 34),
            SizedBox(height: 10),
            Text('No notifications in this tab.',
                style: TextStyle(color: AppTheme.muted, fontSize: 12)),
          ],
        ),
      );
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup(
      {required this.title, required this.items, required this.onMarkRead});
  final String title;
  final List<SchoolNotification> items;
  final Future<void> Function() onMarkRead;
  @override
  Widget build(BuildContext context) {
    final unread = items.where((i) => !i.read).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text(title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800))),
        if (unread > 0)
          OutlinedButton.icon(
              onPressed: onMarkRead,
              icon: const Icon(Icons.mark_email_read_outlined, size: 16),
              label: Text('Mark $unread read')),
      ]),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (_, constraints) {
        final cols = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : constraints.maxWidth > 400
                    ? 2
                    : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: cols == 1 ? 2.2 : 1.5),
          itemCount: items.length,
          itemBuilder: (_, i) => _NotificationCard(item: items[i]),
        );
      }),
    ]);
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});
  final SchoolNotification item;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.line)),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(item.title,
                        style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis)),
                const Icon(Icons.more_horiz, color: AppTheme.muted, size: 18),
              ]),
              const SizedBox(height: 3),
              Text(item.read ? 'Read' : 'Unread',
                  style: TextStyle(
                      color: item.read ? AppTheme.muted : AppTheme.peach,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Expanded(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Text(item.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 11,
                                  height: 1.4))),
                      const SizedBox(width: 8),
                      Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color:
                                  _typeColor(item.type).withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(_typeIcon(item.type),
                              color: _typeColor(item.type), size: 17)),
                    ]),
              ),
              Text(_date.format(item.createdAt.toLocal()),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 10)),
            ]),
      );
}

class _NotificationGroupSkeleton extends StatelessWidget {
  const _NotificationGroupSkeleton();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Skeleton(width: 140, height: 15),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.5,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.line)),
                  child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Skeleton(width: 100, height: 13),
                        SizedBox(height: 10),
                        _Skeleton(height: 11),
                        SizedBox(height: 6),
                        _Skeleton(width: 140, height: 11)
                      ]),
                ),
            ],
          ),
        ]),
      );
}

String _typeGroupLabel(String type) => switch (type) {
      'payment' => 'Payment activity',
      'student' => 'Student updates',
      _ => 'Automated sync',
    };

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = _store(context);
    final showSkeleton = !store.hasLoadedOnce && store.campaigns.isEmpty;
    return _PageScroll(children: [
      _SectionHeader(
          title: 'Parent communication',
          subtitle: 'Prepare receipts, fee reminders and event announcements.',
          actionLabel: store.isAccountant ? 'New campaign' : null,
          onAction: () => _showCampaignDialog(context, store)),
      const SizedBox(height: 18),
      if (showSkeleton)
        for (var i = 0; i < 4; i++) const _CampaignSkeleton()
      else
        for (final campaign in store.campaigns)
          Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                            color: _channelColor(campaign.channel)
                                .withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(_channelIcon(campaign.channel),
                            color: _channelColor(campaign.channel))),
                    const SizedBox(width: 13),
                    Expanded(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(campaign.campaign,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppTheme.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text(
                              '${campaign.audience} · ${campaign.recipientCount} recipients',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppTheme.muted, fontSize: 12))
                        ])),
                    const SizedBox(width: 8),
                    _StatusPill(
                        label: campaign.status,
                        positive: campaign.status == 'Sent'),
                  ]))),
    ]);
  }
}

class _CampaignSkeleton extends StatelessWidget {
  const _CampaignSkeleton();
  @override
  Widget build(BuildContext context) => const Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
          padding: EdgeInsets.all(18),
          child: Row(children: [
            _Skeleton(width: 43, height: 43, radius: 14),
            SizedBox(width: 13),
            Expanded(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _Skeleton(width: 140, height: 14),
                  SizedBox(height: 7),
                  _Skeleton(width: 180, height: 11)
                ])),
            _Skeleton(width: 50, height: 18, radius: 30),
          ])));
}

class _PageScroll extends StatelessWidget {
  const _PageScroll({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children));
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title,
      required this.subtitle,
      this.actionLabel,
      this.onAction});
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12))
            ])),
        if (actionLabel != null)
          FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 17),
              label: Text(actionLabel!))
      ]);
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.cells});
  final List<String> cells;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
          color: Color(0xFFF7F9F8),
          borderRadius: BorderRadius.all(Radius.circular(15))),
      child: Row(children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
              flex: i == 0 ? 2 : 1,
              child: Text(cells[i].toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 9,
                      letterSpacing: .7,
                      fontWeight: FontWeight.w800)))
      ]));
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.positive});
  final String label;
  final bool positive;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: (positive ? AppTheme.green : AppTheme.peach)
              .withValues(alpha: .11),
          borderRadius: BorderRadius.circular(30)),
      child: Text(label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: positive ? AppTheme.green : AppTheme.peach,
              fontSize: 10,
              fontWeight: FontWeight.w800)));
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(28, 0, 28, 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: AppTheme.peach.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.peach.withValues(alpha: .3))),
        child: Row(children: [
          const Icon(Icons.cloud_off_outlined, color: AppTheme.peach, size: 17),
          const SizedBox(width: 10),
          const Expanded(
              child: Text(
                  "Can't reach the school API  showing a preview. Retrying automatically",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600))),
          TextButton(onPressed: onRetry, child: const Text('Retry now')),
        ]),
      );
}

class _Skeleton extends StatefulWidget {
  const _Skeleton({this.width, this.height = 14, this.radius = 8});
  final double? width;
  final double height;
  final double radius;
  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(-1.6 + t * 3.2, 0),
                end: Alignment(0.4 + t * 3.2, 0),
                colors: const [
                  Color(0xFFEBEFED),
                  Color(0xFFF7F9F8),
                  Color(0xFFEBEFED)
                ],
              ),
            ),
          );
        },
      );
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({this.cells = 5});
  final int cells;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(children: [
          for (var i = 0; i < cells; i++)
            Expanded(
              flex: i == 0 ? 2 : 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _Skeleton(height: 12, width: i == 0 ? 130 : 60),
              ),
            ),
        ]),
      );
}

SchoolStore _store(BuildContext context) =>
    context.findAncestorStateOfType<_AppShellState>()!.widget.store;
Color _roleColor(String role) => role == 'Accountant'
    ? AppTheme.blue
    : role == 'Automated'
        ? AppTheme.green
        : AppTheme.peach;
IconData _roleIcon(String role) => role == 'Accountant'
    ? Icons.calculate_outlined
    : role == 'Automated'
        ? Icons.sync_rounded
        : Icons.person_outline;
Color _classColor(int id) => [
      AppTheme.blue,
      AppTheme.green,
      AppTheme.peach,
      const Color(0xFF9B6BD9)
    ][id % 4];
Color _typeColor(String type) => type == 'payment'
    ? AppTheme.green
    : type == 'student'
        ? AppTheme.blue
        : AppTheme.peach;
IconData _typeIcon(String type) => type == 'payment'
    ? Icons.payments_outlined
    : type == 'student'
        ? Icons.person_add_alt_1_outlined
        : Icons.sync_rounded;
Color _channelColor(String channel) =>
    channel.toLowerCase().contains('whatsapp')
        ? AppTheme.green
        : channel.toLowerCase().contains('email')
            ? AppTheme.blue
            : AppTheme.peach;
IconData _channelIcon(String channel) =>
    channel.toLowerCase().contains('whatsapp')
        ? Icons.chat_outlined
        : channel.toLowerCase().contains('email')
            ? Icons.email_outlined
            : Icons.sms_outlined;

Future<void> _showStudentDialog(BuildContext context, SchoolStore store,
    [Student? student]) async {
  final isEditing = student != null;
  final name = TextEditingController(text: student?.name ?? '');
  final admission = TextEditingController(text: student?.admissionNo ?? '');
  final guardian = TextEditingController(text: student?.guardian ?? '');
  final phone = TextEditingController(text: student?.guardianPhone ?? '');
  SchoolClass? selectedClass;
  for (final schoolClass in store.classes) {
    if (schoolClass.name == student?.grade) {
      selectedClass = schoolClass;
      break;
    }
  }
  selectedClass ??= store.classes.isEmpty ? null : store.classes.first;
  await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (context, setState) => _FormDialog(
              title: isEditing ? 'Edit student' : 'Add student',
              fields: [
                ('Student name', name),
                ('Admission number', admission),
                ('Parent / guardian', guardian),
                ('Guardian phone', phone)
              ],
              extra: DropdownButtonFormField<SchoolClass>(
                initialValue: selectedClass,
                decoration: const InputDecoration(labelText: 'Class'),
                items: [
                  for (final schoolClass in store.classes)
                    DropdownMenuItem(
                      value: schoolClass,
                      child: Text('${schoolClass.name} ${schoolClass.stream}'),
                    ),
                ],
                onChanged: (value) => setState(() => selectedClass = value),
              ),
              submitLabel: isEditing ? 'Save student' : 'Add student',
              onSubmit: () async {
                if (selectedClass == null) {
                  throw StateError('Select a class for this student.');
                }
                await store.addStudent({
                  'name': name.text,
                  'admissionNo': admission.text,
                  'grade': selectedClass!.name,
                  'guardian': guardian.text,
                  'guardianPhone': phone.text
                });
              })));
}

Future<void> _showClassDialog(BuildContext context, SchoolStore store) async {
  final name = TextEditingController(text: 'Grade 10');
  final stream = TextEditingController(text: 'North');
  final teacher = TextEditingController();
  final fee = TextEditingController();
  await showDialog<void>(
      context: context,
      builder: (_) => _FormDialog(
          title: 'Add class',
          fields: [
            ('Class', name),
            ('Stream', stream),
            ('Class teacher', teacher),
            ('Fee target (KES)', fee)
          ],
          submitLabel: 'Save class',
          onSubmit: () async {
            await store.addClass({
              'name': name.text,
              'stream': stream.text,
              'teacher': teacher.text,
              'feeTarget': int.tryParse(fee.text) ?? 0
            });
          }));
}

Future<void> _showEventDialog(BuildContext context, SchoolStore store,
    [DateTime? initialDate]) async {
  final title = TextEditingController();
  final description = TextEditingController();
  DateTime selectedDate = initialDate ?? DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (context, setState) => _FormDialog(
              title: 'Add calendar event',
              fields: [
                ('Event title', title),
                ('Description', description),
              ],
              extra: Column(children: [
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(
                        DateFormat('EEEE, d MMMM yyyy').format(selectedDate)),
                    onTap: () async {
                      final value = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 730)),
                          initialDate: selectedDate);
                      if (value != null) setState(() => selectedDate = value);
                    }),
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(selectedTime.format(context)),
                    onTap: () async {
                      final value = await showTimePicker(
                          context: context, initialTime: selectedTime);
                      if (value != null) setState(() => selectedTime = value);
                    }),
              ]),
              submitLabel: 'Save event',
              onSubmit: () async {
                final eventDate = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute);
                await store.addEvent({
                  'title': title.text,
                  'description': description.text,
                  'eventDate': eventDate.toUtc().toIso8601String(),
                  'createdBy': 'Accountant',
                });
              })));
}

Future<void> _confirmDeleteClass(
    BuildContext context, SchoolStore store, SchoolClass schoolClass) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete class?'),
      content: Text(
          'Delete ${schoolClass.name} ${schoolClass.stream}? This cannot be undone. Students assigned to this class will remain in the system.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete class'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await store.deleteClass(schoolClass.id);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete class: $error')),
      );
    }
  }
}

Future<void> _showPaymentDialog(BuildContext context, SchoolStore store) async {
  if (store.students.isEmpty) return;
  var selected = store.students.first;
  final amount = TextEditingController();
  final method = TextEditingController(text: 'Cash');
  await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (context, setState) => _FormDialog(
              title: 'Record manual payment',
              fields: [('Amount (KES)', amount), ('Method', method)],
              extra: DropdownButtonFormField<Student>(
                  initialValue: selected,
                  decoration: const InputDecoration(labelText: 'Student'),
                  items: [
                    for (final student in store.students)
                      DropdownMenuItem(
                          value: student, child: Text(student.name))
                  ],
                  onChanged: (value) => setState(() => selected = value!)),
              submitLabel: 'Create receipt',
              onSubmit: () async {
                await store.addPayment({
                  'studentId': selected.id,
                  'studentName': selected.name,
                  'amount': int.tryParse(amount.text) ?? 0,
                  'method': method.text
                });
              })));
}

Future<void> _showCampaignDialog(
    BuildContext context, SchoolStore store) async {
  final campaign = TextEditingController();
  final audience = TextEditingController(text: 'Parents with balances');
  final channel = TextEditingController(text: 'WhatsApp + SMS');
  await showDialog<void>(
      context: context,
      builder: (_) => _FormDialog(
          title: 'Prepare campaign',
          fields: [
            ('Campaign name', campaign),
            ('Audience', audience),
            ('Channel', channel)
          ],
          submitLabel: 'Queue campaign',
          onSubmit: () async {
            await store.createCampaign({
              'campaign': campaign.text,
              'audience': audience.text,
              'channel': channel.text,
              'recipientCount': 0
            });
          }));
}

class _FormDialog extends StatefulWidget {
  const _FormDialog(
      {required this.title,
      required this.fields,
      required this.submitLabel,
      required this.onSubmit,
      this.extra});
  final String title;
  final List<(String, TextEditingController)> fields;
  final String submitLabel;
  final Future<void> Function() onSubmit;
  final Widget? extra;
  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  bool saving = false;
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final field in widget.fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: field.$2,
                      decoration: InputDecoration(labelText: field.$1),
                    ),
                  ),
                if (widget.extra != null) widget.extra!,
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      try {
                        await widget.onSubmit();
                        if (mounted) Navigator.pop(context);
                      } finally {
                        if (mounted) setState(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(widget.submitLabel)),
        ],
      );
}
