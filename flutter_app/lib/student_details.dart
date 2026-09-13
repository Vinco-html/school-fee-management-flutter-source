import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'theme.dart';
import 'store.dart';

final _money = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);
final _date = DateFormat('d MMM yyyy, h:mm a');

class StudentDetails extends StatefulWidget {
  const StudentDetails({super.key, required this.student, required this.store});
  final Student student;
  final SchoolStore store;

  @override
  State<StudentDetails> createState() => _StudentDetailsState();
}

class _StudentDetailsState extends State<StudentDetails>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final payments = widget.store.payments
        .where((p) => p.studentId == student.id)
        .toList()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F9),
        elevation: 0,
        title: const Text(""),
        iconTheme: const IconThemeData(color: AppTheme.ink),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Breakpoints — tune these to your app's needs.
          final maxWidth = constraints.maxWidth;
          final isTablet = maxWidth >= 600 && maxWidth < 1024;
          final isDesktop = maxWidth >= 1024;

          // Horizontal padding scales with screen size.
          final horizontalPadding = isDesktop
              ? maxWidth * 0.2 // wide gutters on desktop
              : isTablet
                  ? 40.0
                  : 20.0;

          // Cap content width so it doesn't stretch edge-to-edge on large screens.
          final contentMaxWidth = isDesktop ? 720.0 : double.infinity;
          double cardWidth;
          if (isDesktop) {
            cardWidth = (maxWidth * 0.6);
          } else if (isTablet) {
            cardWidth = (maxWidth * 0.8);
          } else {
            cardWidth = double.infinity;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, 8, horizontalPadding, 20),
            child: Center(
              child: Container(
                padding: isDesktop || isTablet
                    ? const EdgeInsets.all(50)
                    : const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.line)),
                width: cardWidth,
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _AvatarHeader(student: student),
                    const SizedBox(height: 6),
                    Text(student.name,
                        style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('@${student.admissionNo}',
                        style: const TextStyle(
                            color: AppTheme.muted, fontSize: 12)),
                    const SizedBox(height: 18),
                    _ActionRow(
                      onEdit: () => _editStudent(context),
                      onMessage: () => _messageParent(context),
                      onDelete: () => _confirmDeleteStudent(context),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 180,
                      height: 30,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.line)),
                      child: TabBar(
                        controller: _tab,
                        indicator: BoxDecoration(
                            color: AppTheme.peach.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(9)),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: AppTheme.peach,
                        unselectedLabelColor: AppTheme.muted,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 12),
                        tabs: const [
                          Tab(text: 'Fee'),
                          Tab(text: 'History'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // IndexedStack keeps both tabs alive so the TabBarView
                    // doesn't need a fixed height hack inside a
                    // SingleChildScrollView.
                    AnimatedBuilder(
                      animation: _tab,
                      builder: (_, __) => _tab.index == 0
                          ? _FeeDashboardTab(
                              student: student, payments: payments)
                          : _PaymentHistoryTab(
                              student: student,
                              payments: payments,
                              store: widget.store,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _editStudent(BuildContext context) {
    // TODO: reuse your existing _showStudentDialog(context, store) pattern,
    // pre-filled with this student's current values, then call
    // store.updateStudent(student.id, {...}) on submit.
  }

  void _messageParent(BuildContext context) {
    // TODO: launch tel:/https://wa.me/ using student.guardianPhone,
    // or open your existing campaign/message flow scoped to this parent.
  }

  Future<void> _confirmDeleteStudent(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove student?'),
        content: Text(
            'This removes ${widget.student.name} and their payment history. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await widget.store.deleteStudent(widget.student.id);
        if (context.mounted) {
          Navigator.pop(context);
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete student: $error')),
          );
        }
      }
    }
  }
}

/// Big circular avatar with an edit affordance, echoing the "Customize
/// Avatar" reference — tap to change photo.
class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({required this.student});
  final Student student;
  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: AppTheme.peach.withValues(alpha: .18),
            backgroundImage: student.avatarUrl == null
                ? null
                : NetworkImage(student.avatarUrl!),
            child: student.avatarUrl == null
                ? Text(student.name.substring(0, 1),
                    style: const TextStyle(
                        color: AppTheme.peach,
                        fontSize: 28,
                        fontWeight: FontWeight.w800))
                : null,
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.line)),
            child: const Icon(Icons.camera_alt_outlined,
                size: 15, color: AppTheme.ink),
          ),
        ],
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow(
      {required this.onEdit, required this.onMessage, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onMessage;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _ActionButton(icon: Icons.edit_outlined, label: 'Edit', onTap: onEdit),
        const SizedBox(width: 10),
        _ActionButton(
            icon: Icons.chat_outlined, label: 'Message', onTap: onMessage),
        const SizedBox(width: 10),
        _ActionButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            destructive: true,
            onTap: onDelete),
      ]);
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.destructive = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red : AppTheme.ink;
    return SizedBox(
        width: 80,
        height: 36,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(
                color: destructive
                    ? Colors.red.withValues(alpha: .3)
                    : AppTheme.line),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
          ]),
        ));
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Fee dashboard: balance summary + a simple bar chart of payments
// over the student's recent terms/months.
// ---------------------------------------------------------------------------

class _FeeDashboardTab extends StatelessWidget {
  const _FeeDashboardTab({required this.student, required this.payments});
  final Student student;
  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    final totalPaid = payments.fold<num>(0, (sum, p) => sum + p.amount);
    final target = totalPaid + student.balance; // total owed = paid + remaining
    final paidPct = target == 0 ? 0.0 : totalPaid / target;

    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: _MiniStat(
                    label: 'Paid so far', value: _money.format(totalPaid))),
            Expanded(
                child: _MiniStat(
                    label: 'Balance',
                    value: student.balance == 0
                        ? 'Paid'
                        : _money.format(student.balance),
                    color: student.balance == 0
                        ? AppTheme.green
                        : AppTheme.peach)),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: paidPct.clamp(0, 1),
              minHeight: 10,
              backgroundColor: const Color(0xFFF0F2F1),
              color: AppTheme.green,
            ),
          ),
          const SizedBox(height: 6),
          Text('${(paidPct * 100).round()}% of expected fees collected',
              style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
        ]),
      ),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Payments by month',
              style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          SizedBox(height: 140, child: _MonthlyBarChart(payments: payments)),
        ]),
      ),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  color: color ?? AppTheme.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ],
      );
}

/// Groups payments into the last 6 calendar months and draws simple bars —
/// no external chart package needed.
class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({required this.payments});
  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i)
    ];
    final totals = [
      for (final m in months)
        payments
            .where((p) => p.paidAt.year == m.year && p.paidAt.month == m.month)
            .fold<num>(0, (sum, p) => sum + p.amount)
    ];
    final maxVal = totals.fold<num>(1, (a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < months.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(totals[i] == 0 ? '' : _money.format(totals[i]),
                    style: const TextStyle(color: AppTheme.muted, fontSize: 8)),
                const SizedBox(height: 4),
                Container(
                  height: 90 * (totals[i] / maxVal).clamp(0.03, 1.0),
                  decoration: BoxDecoration(
                      color: AppTheme.peach,
                      borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(height: 6),
                Text(DateFormat('MMM').format(months[i]),
                    style:
                        const TextStyle(color: AppTheme.muted, fontSize: 10)),
              ]),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — Payment history: editable/deletable list, each change adjusts the
// student's balance accordingly.
// ---------------------------------------------------------------------------

class _PaymentHistoryTab extends StatelessWidget {
  const _PaymentHistoryTab(
      {required this.student, required this.payments, required this.store});
  final Student student;
  final List<Payment> payments;
  final SchoolStore store;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.line)),
        child: const Text('No payments recorded yet.',
            style: TextStyle(color: AppTheme.muted, fontSize: 12)),
      );
    }
    return Column(
      children: [
        for (final payment in payments)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.line)),
              child: Row(children: [
                Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: AppTheme.green.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.receipt_long_outlined,
                        color: AppTheme.green, size: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_money.format(payment.amount),
                          style: const TextStyle(
                              color: AppTheme.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                      Text(
                          '${payment.method} · ${_date.format(payment.paidAt.toLocal())}',
                          style: const TextStyle(
                              color: AppTheme.muted, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppTheme.muted),
                  onPressed: () => _editPayment(context, payment),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  onPressed: () => _confirmDeletePayment(context, payment),
                ),
              ]),
            ),
          ),
      ],
    );
  }

  Future<void> _editPayment(BuildContext context, Payment payment) async {
    final amountController = TextEditingController(text: '${payment.amount}');
    final newAmount = await showDialog<num>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit payment amount'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (KES)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, num.tryParse(amountController.text)),
              child: const Text('Save')),
        ],
      ),
    );
    if (newAmount == null || newAmount == payment.amount) return;

    final diff = newAmount - payment.amount; // positive = paid more than before
    // TODO: implement in SchoolStore — should update the payment record AND
    // adjust student.balance by -diff (balance drops as more is paid).
    // await store.updatePayment(payment.id, amount: newAmount);
    // await store.adjustStudentBalance(student.id, -diff);
  }

  Future<void> _confirmDeletePayment(
      BuildContext context, Payment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this payment?'),
        content: Text(
            'Removing ${_money.format(payment.amount)} paid on ${_date.format(payment.paidAt)} will add it back to ${student.name}\'s balance.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    // TODO: implement in SchoolStore — delete the payment record AND
    // adjust student.balance by +payment.amount (balance rises since this
    // payment no longer counts).
    // await store.deletePayment(payment.id);
    // await store.adjustStudentBalance(student.id, payment.amount);
  }
}
