import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'store.dart';
import 'theme.dart';

final _money = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);
final _date = DateFormat('d MMM, h:mm a');

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});
  final SchoolStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

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
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final labels = [
      'Overview',
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
                    onSelectRole: widget.store.setRole,
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
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              destinations: [
                for (var i = 0; i < labels.length; i++)
                  NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
              ],
            ),
    );
  }
}

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
        color: AppTheme.ink,
        padding: const EdgeInsets.fromLTRB(18, 24, 14, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(children: [
                Icon(Icons.auto_awesome, color: AppTheme.peach, size: 20),
                SizedBox(width: 8),
                Text('Kijani',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700)),
                Text(' school',
                    style: TextStyle(color: Color(0xFF9CA9B5), fontSize: 21)),
              ]),
            ),
            const SizedBox(height: 42),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('WORKSPACE',
                  style: TextStyle(
                      color: Color(0xFF87929D),
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
                  color: const Color(0xFF2C3B46),
                  borderRadius: BorderRadius.circular(18)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Connect Equity Bank',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  SizedBox(height: 5),
                  Text('Automate fee updates and receipts.',
                      style: TextStyle(
                          color: Color(0xFFAFBBC2), fontSize: 12, height: 1.3)),
                  SizedBox(height: 14),
                  Text('Ready for setup →',
                      style: TextStyle(
                          color: AppTheme.peach,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
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
                        style: TextStyle(
                            color: Colors.white, fontSize: 12, height: 1.35))),
                Icon(Icons.more_horiz, color: Color(0xFF92A0AC)),
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
                  ? AppTheme.peach.withValues(alpha: .18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(children: [
              Icon(icon,
                  color: selected ? AppTheme.peach : const Color(0xFFAAB4BD),
                  size: 19),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color:
                              selected ? Colors.white : const Color(0xFFAAB4BD),
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500))),
              if (count > 0)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppTheme.peach,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('$count',
                        style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 10,
                            fontWeight: FontWeight.w800))),
            ]),
          ),
        ),
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar(
      {required this.store,
      required this.title,
      required this.onRefresh,
      required this.onSelectRole});
  final SchoolStore store;
  final String title;
  final Future<void> Function() onRefresh;
  final ValueChanged<UserRole> onSelectRole;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 25,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(store.summary?.term ?? 'Loading your school workspace…',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ],
          );
          final rolePicker = PopupMenuButton<UserRole>(
            initialValue: store.role,
            onSelected: onSelectRole,
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: UserRole.admin, child: Text('Preview as Admin')),
              PopupMenuItem(
                  value: UserRole.accountant,
                  child: Text('Preview as Accountant')),
            ],
            child: Container(
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
                        color:
                            store.isAccountant ? AppTheme.blue : AppTheme.peach,
                        size: 17)),
                const SizedBox(width: 8),
                Text(store.isAccountant ? 'Accountant' : 'Admin',
                    style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const Icon(Icons.keyboard_arrow_down,
                    size: 17, color: AppTheme.muted),
              ]),
            ),
          );
          final search = TextField(
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: 'Search anything',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 11)),
            onSubmitted: (_) {},
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 10),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(children: [
                          Expanded(child: heading),
                          IconButton(
                              onPressed: onRefresh,
                              icon: const Icon(Icons.refresh_rounded,
                                  color: AppTheme.muted)),
                          rolePicker
                        ]),
                        const SizedBox(height: 13),
                        search,
                      ])
                : Row(children: [
                    Expanded(child: heading),
                    SizedBox(width: 190, child: search),
                    const SizedBox(width: 12),
                    IconButton(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppTheme.muted)),
                    const SizedBox(width: 4),
                    rolePicker
                  ]),
          );
        },
      );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = _store(context);
    final summary = store.summary;
    if (summary == null) return _DashboardSkeleton(store: store);
    return _PageScroll(
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _MetricCard(
                label: 'Total students',
                value: '${summary.students}',
                helper: 'Across 4 classes',
                icon: Icons.people_alt_outlined,
                tint: AppTheme.blue),
            _MetricCard(
                label: 'Collected this term',
                value: _money.format(summary.collected),
                helper: '${summary.paymentCount} completed payments',
                icon: Icons.trending_up_rounded,
                tint: AppTheme.green),
            _MetricCard(
                label: 'Outstanding balance',
                value: _money.format(summary.outstanding),
                helper: 'Needs follow-up',
                icon: Icons.account_balance_wallet_outlined,
                tint: AppTheme.peach),
            _MetricCard(
                label: 'Unread activity',
                value: '${summary.unreadNotifications}',
                helper: 'Admin review queue',
                icon: Icons.notifications_none_rounded,
                tint: const Color(0xFF9B6BD9)),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (context, constraints) {
          final split = constraints.maxWidth > 980;
          final left = Column(children: [
            _CollectionCard(summary: summary),
            const SizedBox(height: 18),
            _ActivityCard(items: summary.recentActivity),
          ]);
          final right = Column(children: [
            _EquityCard(store: store),
            const SizedBox(height: 18),
            _MessageCard(store: store),
          ]);
          return split
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 6, child: left),
                  const SizedBox(width: 18),
                  Expanded(flex: 4, child: right)
                ])
              : Column(children: [left, const SizedBox(height: 18), right]);
        }),
      ],
    );
  }
}

/// Mirrors the real dashboard layout using shimmering placeholders, shown
/// while data is loading for the first time or while the API is unreachable.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({required this.store});
  final SchoolStore store;
  @override
  Widget build(BuildContext context) => _PageScroll(children: [
        Wrap(spacing: 14, runSpacing: 14, children: [
          for (var i = 0; i < 4; i++) const _MetricCardSkeleton()
        ]),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (context, constraints) {
          final split = constraints.maxWidth > 980;
          final left = Column(children: const [
            _CollectionCardSkeleton(),
            SizedBox(height: 18),
            _ActivityCardSkeleton()
          ]);
          // The Equity and Messages cards don't depend on fetched data, so
          // they render for real even while the rest of the page is a
          // skeleton — no reason to fake something that already works.
          final right = Column(children: [
            _EquityCard(store: store),
            const SizedBox(height: 18),
            _MessageCard(store: store)
          ]);
          return split
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 6, child: left),
                  const SizedBox(width: 18),
                  Expanded(flex: 4, child: right)
                ])
              : Column(children: [left, const SizedBox(height: 18), right]);
        }),
      ]);
}

class _MetricCardSkeleton extends StatelessWidget {
  const _MetricCardSkeleton();
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 230,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _Skeleton(width: 36, height: 36, radius: 12),
              const SizedBox(height: 20),
              const _Skeleton(width: 90, height: 11),
              const SizedBox(height: 9),
              const _Skeleton(width: 120, height: 20),
              const SizedBox(height: 9),
              const _Skeleton(width: 100, height: 11),
            ]),
          ),
        ),
      );
}

class _CollectionCardSkeleton extends StatelessWidget {
  const _CollectionCardSkeleton();
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              _Skeleton(width: 140, height: 16),
              Spacer(),
              _Skeleton(width: 40, height: 20)
            ]),
            const SizedBox(height: 24),
            ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const _Skeleton(height: 11, radius: 0)),
            const SizedBox(height: 15),
            const Row(children: [
              _Skeleton(width: 120, height: 11),
              SizedBox(width: 20),
              _Skeleton(width: 120, height: 11)
            ]),
          ]),
        ),
      );
}

class _ActivityCardSkeleton extends StatelessWidget {
  const _ActivityCardSkeleton();
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _Skeleton(width: 120, height: 14),
            const SizedBox(height: 16),
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Skeleton(width: 34, height: 34, radius: 17),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              _Skeleton(height: 12),
                              SizedBox(height: 6),
                              _Skeleton(width: 160, height: 11),
                            ]),
                      ),
                    ]),
              ),
          ]),
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.helper,
      required this.icon,
      required this.tint});
  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color tint;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 230,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: tint.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: tint, size: 19)),
                const Spacer(),
                const Icon(Icons.more_horiz, color: Color(0xFFB2BDC2), size: 18)
              ]),
              const SizedBox(height: 20),
              Text(label,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
              const SizedBox(height: 5),
              Text(value,
                  style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(helper,
                  style: TextStyle(
                      color: tint, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.summary});
  final DashboardSummary summary;
  @override
  Widget build(BuildContext context) {
    final target = summary.collected + summary.outstanding;
    final progress = target == 0 ? 0.0 : summary.collected / target;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Fee collection',
                      style: TextStyle(
                          color: AppTheme.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('How the term is tracking against balances',
                      style: TextStyle(color: AppTheme.muted, fontSize: 12))
                ])),
            Text('${(progress * 100).round()}%',
                style: const TextStyle(
                    color: AppTheme.green,
                    fontSize: 20,
                    fontWeight: FontWeight.w800))
          ]),
          const SizedBox(height: 24),
          ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 11,
                  backgroundColor: const Color(0xFFE9F0ED),
                  color: AppTheme.green)),
          const SizedBox(height: 15),
          Row(children: [
            const Icon(Icons.circle, color: AppTheme.green, size: 10),
            const SizedBox(width: 6),
            Text('Collected ${_money.format(summary.collected)}',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            const SizedBox(width: 20),
            const Icon(Icons.circle, color: AppTheme.peach, size: 10),
            const SizedBox(width: 6),
            Text('Outstanding ${_money.format(summary.outstanding)}',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12))
          ]),
        ]),
      ),
    );
  }
}

class _EquityCard extends StatelessWidget {
  const _EquityCard({required this.store});
  final SchoolStore store;
  @override
  Widget build(BuildContext context) => Card(
        color: AppTheme.ink,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: AppTheme.peach.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.account_balance,
                      color: AppTheme.peach, size: 18)),
              const SizedBox(width: 10),
              const Expanded(
                  child: Text('Equity Bank',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800))),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppTheme.green.withValues(alpha: .3),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('READY',
                      style: TextStyle(
                          color: Color(0xFF8DE1C7),
                          fontSize: 9,
                          fontWeight: FontWeight.w800)))
            ]),
            const SizedBox(height: 20),
            const Text('Automated payment updates',
                style: TextStyle(color: Color(0xFFD8E0E4), fontSize: 12)),
            const SizedBox(height: 5),
            const Text('Sync new bank deposits into receipts and balances.',
                style: TextStyle(
                    color: Color(0xFF9FAEB6), fontSize: 12, height: 1.35)),
            const SizedBox(height: 18),
            SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                    onPressed: store.loading ? null : () => store.syncEquity(),
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Sync now'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF53616B)),
                        padding: const EdgeInsets.symmetric(vertical: 12)))),
          ]),
        ),
      );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.store});
  final SchoolStore store;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(
                  child: Text('Parent communication',
                      style: TextStyle(
                          color: AppTheme.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800))),
              TextButton(onPressed: () {}, child: const Text('View all'))
            ]),
            const SizedBox(height: 8),
            const Text(
                'Receipts, balance reminders and event updates are ready to reach families through WhatsApp, bulk email and SMS.',
                style: TextStyle(
                    color: AppTheme.muted, fontSize: 12, height: 1.45)),
            const SizedBox(height: 16),
            Wrap(spacing: 7, runSpacing: 7, children: const [
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
        ),
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.items});
  final List<Activity> items;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Recent activity',
                style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            for (final item in items.take(4))
              Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                            radius: 17,
                            backgroundColor:
                                _roleColor(item.role).withValues(alpha: .13),
                            child: Icon(_roleIcon(item.role),
                                color: _roleColor(item.role), size: 17)),
                        const SizedBox(width: 11),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(item.action,
                                  style: const TextStyle(
                                      color: AppTheme.ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 3),
                              Text(item.detail,
                                  style: const TextStyle(
                                      color: AppTheme.muted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                  '${item.actor} · ${_date.format(item.createdAt.toLocal())}',
                                  style: const TextStyle(
                                      color: Color(0xFFA0AAB0), fontSize: 10))
                            ]))
                      ])),
          ]),
        ),
      );
}

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});
  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final store = _store(context);
    final showSkeleton = !store.hasLoadedOnce && store.students.isEmpty;
    final filtered = store.students
        .where((student) =>
            '${student.name} ${student.admissionNo} ${student.grade}'
                .toLowerCase()
                .contains(query.toLowerCase()))
        .toList();
    return _PageScroll(
      children: [
        _SectionHeader(
            title: 'Students',
            subtitle: 'Keep the school register and family details in sync.',
            actionLabel: store.isAccountant ? 'Add student' : null,
            onAction: () => _showStudentDialog(context, store)),
        const SizedBox(height: 16),
        TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name, admission number or grade')),
        const SizedBox(height: 16),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(children: [
                  const _TableHeader(cells: [
                    'Student',
                    'Class',
                    'Guardian',
                    'Balance',
                    'Status'
                  ]),
                  if (showSkeleton)
                    for (var i = 0; i < 6; i++) const _SkeletonRow(cells: 5)
                  else
                    for (final student in filtered)
                      _StudentRow(student: student),
                ]))),
      ],
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student});
  final Student student;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(children: [
          Expanded(
              flex: 3,
              child: Row(children: [
                CircleAvatar(
                    radius: 17,
                    backgroundImage: student.avatarUrl == null
                        ? null
                        : NetworkImage(student.avatarUrl!),
                    backgroundColor: AppTheme.peach.withValues(alpha: .18),
                    child: student.avatarUrl == null
                        ? Text(student.name.substring(0, 1))
                        : null),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(student.name,
                      style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  Text(student.admissionNo,
                      style:
                          const TextStyle(color: AppTheme.muted, fontSize: 10))
                ])
              ])),
          Expanded(
              child: Text(student.grade,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12))),
          Expanded(
              flex: 2,
              child: Text(student.guardian,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12))),
          Expanded(
              child: Text(
                  student.balance == 0
                      ? 'Paid'
                      : _money.format(student.balance),
                  style: TextStyle(
                      color: student.balance == 0
                          ? AppTheme.green
                          : AppTheme.peach,
                      fontSize: 12,
                      fontWeight: FontWeight.w700))),
          Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusPill(
                      label: student.status,
                      positive: student.status == 'Active'))),
        ]),
      );
}

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = _store(context);
    final showSkeleton = !store.hasLoadedOnce && store.classes.isEmpty;
    return _PageScroll(children: [
      _SectionHeader(
          title: 'Classes',
          subtitle:
              'See enrolment, fee targets and class ownership at a glance.',
          actionLabel: store.isAccountant ? 'Add class' : null,
          onAction: () => _showClassDialog(context, store)),
      const SizedBox(height: 18),
      LayoutBuilder(
          builder: (_, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth > 1000
                      ? 3
                      : constraints.maxWidth > 650
                          ? 2
                          : 1,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.6),
              itemCount: showSkeleton ? 6 : store.classes.length,
              itemBuilder: (_, i) => showSkeleton
                  ? const _ClassCardSkeleton()
                  : _ClassCard(schoolClass: store.classes[i]))),
    ]);
  }
}

class _ClassCardSkeleton extends StatelessWidget {
  const _ClassCardSkeleton();
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              _Skeleton(width: 38, height: 38, radius: 12),
              SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _Skeleton(width: 100, height: 13),
                    SizedBox(height: 6),
                    _Skeleton(width: 70, height: 10)
                  ]))
            ]),
            const Spacer(),
            const Row(children: [
              Expanded(child: _Skeleton(width: 80, height: 11)),
              _Skeleton(width: 60, height: 12)
            ]),
            const SizedBox(height: 8),
            const _Skeleton(width: 120, height: 11),
          ])));
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.schoolClass});
  final SchoolClass schoolClass;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: _classColor(schoolClass.id).withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.school_outlined,
                      color: _classColor(schoolClass.id), size: 20)),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('${schoolClass.name} ${schoolClass.stream}',
                        style: const TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                    Text(schoolClass.term,
                        style: const TextStyle(
                            color: AppTheme.muted, fontSize: 11))
                  ])),
              const Icon(Icons.more_horiz, color: AppTheme.muted)
            ]),
            const Spacer(),
            Row(children: [
              Expanded(
                  child: Text('${schoolClass.studentsCount} students',
                      style: const TextStyle(
                          color: AppTheme.muted, fontSize: 11))),
              Text(_money.format(schoolClass.feeTarget),
                  style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 12))
            ]),
            const SizedBox(height: 8),
            Text('Teacher · ${schoolClass.teacher}',
                style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
          ])));
}

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = _store(context);
    final showSkeleton = !store.hasLoadedOnce && store.payments.isEmpty;
    return _PageScroll(children: [
      _SectionHeader(
          title: 'Payments',
          subtitle: 'Track manual collections and automated bank updates.',
          actionLabel: store.isAccountant ? 'Record payment' : null,
          onAction: () => _showPaymentDialog(context, store)),
      const SizedBox(height: 18),
      Card(
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(children: [
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
                                  style: const TextStyle(
                                      color: AppTheme.ink,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12))),
                          Expanded(
                              flex: 3,
                              child: Text(payment.studentName,
                                  style: const TextStyle(
                                      color: AppTheme.muted, fontSize: 12))),
                          Expanded(
                              child: Text(_money.format(payment.amount),
                                  style: const TextStyle(
                                      color: AppTheme.green,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12))),
                          Expanded(
                              child: Text(payment.method,
                                  style: const TextStyle(
                                      color: AppTheme.muted, fontSize: 12))),
                          Expanded(
                              child: _Pill(
                                  label: payment.channel,
                                  color: payment.channel == 'Automated'
                                      ? AppTheme.blue
                                      : AppTheme.peach)),
                          Expanded(
                              child: Text(
                                  _date.format(payment.paidAt.toLocal()),
                                  style: const TextStyle(
                                      color: AppTheme.muted, fontSize: 11))),
                        ])),
              ]))),
    ]);
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = _store(context);
    final showSkeleton = !store.hasLoadedOnce && store.notifications.isEmpty;
    return _PageScroll(children: [
      _SectionHeader(
          title: 'Notifications',
          subtitle: 'Admin review queue for accountant and automated activity.',
          actionLabel: store.unreadCount > 0 ? 'Mark all read' : null,
          onAction: store.markRead),
      const SizedBox(height: 18),
      if (showSkeleton)
        for (var i = 0; i < 5; i++) const _NotificationSkeleton()
      else
        for (final item in store.notifications)
          Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: _typeColor(item.type).withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(13)),
                      child: Icon(_typeIcon(item.type),
                          color: _typeColor(item.type), size: 19)),
                  title: Row(children: [
                    Expanded(
                        child: Text(item.title,
                            style: const TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 13))),
                    if (!item.read)
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppTheme.peach, shape: BoxShape.circle))
                  ]),
                  subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                          '${item.body}\n${_date.format(item.createdAt.toLocal())}',
                          style: const TextStyle(
                              color: AppTheme.muted,
                              height: 1.4,
                              fontSize: 12))))),
    ]);
  }
}

class _NotificationSkeleton extends StatelessWidget {
  const _NotificationSkeleton();
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(children: [
            const _Skeleton(width: 40, height: 40, radius: 13),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                  _Skeleton(width: 150, height: 13),
                  SizedBox(height: 8),
                  _Skeleton(height: 11),
                  SizedBox(height: 6),
                  _Skeleton(width: 100, height: 11)
                ])),
          ])));
}

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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(campaign.campaign,
                              style: const TextStyle(
                                  color: AppTheme.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text(
                              '${campaign.audience} · ${campaign.recipientCount} recipients',
                              style: const TextStyle(
                                  color: AppTheme.muted, fontSize: 12))
                        ])),
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
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            const _Skeleton(width: 43, height: 43, radius: 14),
            const SizedBox(width: 13),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                  _Skeleton(width: 140, height: 14),
                  SizedBox(height: 7),
                  _Skeleton(width: 180, height: 11)
                ])),
            const _Skeleton(width: 50, height: 18, radius: 30),
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle,
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
          style: TextStyle(
              color: positive ? AppTheme.green : AppTheme.peach,
              fontSize: 10,
              fontWeight: FontWeight.w800)));
}

/// Slim, non-blocking strip shown above the current page when the API is
/// unreachable. The page underneath keeps rendering (with skeletons where
/// real data would go) instead of being replaced by a full error screen.
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
                  "Can't reach the school API — showing a preview. Retrying automatically…",
                  style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600))),
          TextButton(onPressed: onRetry, child: const Text('Retry now')),
        ]),
      );
}

/// Animated shimmering placeholder block used to sketch the shape of
/// content that hasn't loaded yet.
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

/// A full-width skeleton row, used for table-style lists.
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

BuildContext _dialogContext(BuildContext context) => context;
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

Future<void> _showStudentDialog(BuildContext context, SchoolStore store) async {
  final name = TextEditingController();
  final admission = TextEditingController();
  final grade = TextEditingController(text: 'Grade 8');
  final guardian = TextEditingController();
  final phone = TextEditingController();
  await showDialog<void>(
      context: context,
      builder: (_) => _FormDialog(
          title: 'Add student',
          fields: [
            ('Student name', name),
            ('Admission number', admission),
            ('Grade', grade),
            ('Parent / guardian', guardian),
            ('Guardian phone', phone)
          ],
          submitLabel: 'Save student',
          onSubmit: () async {
            await store.addStudent({
              'name': name.text,
              'admissionNo': admission.text,
              'grade': grade.text,
              'guardian': guardian.text,
              'guardianPhone': phone.text
            });
          }));
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
