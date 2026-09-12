import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'store.dart';
import 'student_details.dart';
import 'theme.dart';

final _money = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);

class ClassDetails extends StatefulWidget {
  const ClassDetails({
    super.key,
    required this.schoolClass,
    required this.store,
  });

  final SchoolClass schoolClass;
  final SchoolStore store;

  @override
  State<ClassDetails> createState() => _ClassDetailsState();
}

class _ClassDetailsState extends State<ClassDetails>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  bool _studentsAsCards = false;

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolClass = widget.schoolClass;
    final students = _studentsInClass(schoolClass);
    final payments = _paymentsFor(students);
    final feePaid =
        payments.fold<int>(0, (sum, payment) => sum + payment.amount);
    final paid = payments.isEmpty ? schoolClass.feePaid : feePaid;
    final balance = students.isEmpty
        ? schoolClass.feeBalance
        : students.fold<int>(0, (sum, student) => sum + student.balance);
    final target = paid + balance;
    final paidPercentage = target == 0 ? 0.0 : (paid / target).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F9),
        elevation: 0,
        title: const Text(''),
        iconTheme: const IconThemeData(color: AppTheme.ink),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          final isDesktop = constraints.maxWidth >= 1024;
          final horizontalPadding = isDesktop
              ? constraints.maxWidth * 0.2
              : isTablet
                  ? 40.0
                  : 20.0;
          final cardWidth = isDesktop
              ? constraints.maxWidth * 0.6
              : isTablet
                  ? constraints.maxWidth * 0.8
                  : double.infinity;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, 8, horizontalPadding, 20),
            child: Center(
              child: Container(
                width: cardWidth,
                constraints: const BoxConstraints(maxWidth: 720),
                padding: EdgeInsets.all(isTablet ? 50 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ClassHeader(schoolClass: schoolClass),
                    const SizedBox(height: 18),
                    _ActionRow(
                      onEdit: () => _showUnavailableMessage(
                          context, 'Class editing is not available yet.'),
                      onMessage: () => _showUnavailableMessage(
                          context, 'Class messaging is not available yet.'),
                    ),
                    const SizedBox(height: 14),
                    _TabSelector(controller: _tab),
                    const SizedBox(height: 18),
                    AnimatedBuilder(
                      animation: _tab,
                      builder: (_, __) => _tab.index == 0
                          ? _FeeDashboardTab(
                              schoolClass: schoolClass,
                              students: students,
                              paid: paid,
                              balance: balance,
                              paidPercentage: paidPercentage,
                            )
                          : _StudentsTab(
                              students: students,
                              asCards: _studentsAsCards,
                              onToggle: (value) =>
                                  setState(() => _studentsAsCards = value),
                              onStudentTap: (student) => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentDetails(
                                    student: student,
                                    store: widget.store,
                                  ),
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
    );
  }

  List<Student> _studentsInClass(SchoolClass schoolClass) {
    final className = schoolClass.name.trim().toLowerCase();
    final matching = widget.store.students
        .where((student) => student.grade.trim().toLowerCase() == className)
        .toList();
    return matching.isEmpty &&
            widget.store.students.length == schoolClass.studentsCount
        ? List<Student>.from(widget.store.students)
        : matching;
  }

  List<Payment> _paymentsFor(List<Student> students) {
    final ids = students.map((student) => student.id).toSet();
    return widget.store.payments
        .where((payment) => ids.contains(payment.studentId))
        .toList();
  }

  void _showUnavailableMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ClassHeader extends StatelessWidget {
  const _ClassHeader({required this.schoolClass});
  final SchoolClass schoolClass;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppTheme.peach.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.school_outlined,
                color: AppTheme.peach, size: 46),
          ),
          const SizedBox(height: 12),
          Text(
            '${schoolClass.name} ${schoolClass.stream}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text('@${schoolClass.stream.toLowerCase()}',
              style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
        ],
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onEdit, required this.onMessage});
  final VoidCallback onEdit;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionButton(
              icon: Icons.edit_outlined, label: 'Edit', onTap: onEdit),
          const SizedBox(width: 10),
          _ActionButton(
              icon: Icons.chat_outlined, label: 'Message', onTap: onMessage),
        ],
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 38,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 15),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.ink,
            side: const BorderSide(color: AppTheme.line),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      );
}

class _TabSelector extends StatelessWidget {
  const _TabSelector({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) => Container(
        width: 190,
        height: 34,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.line),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
              color: AppTheme.peach.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(9)),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppTheme.peach,
          unselectedLabelColor: AppTheme.muted,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          tabs: const [Tab(text: 'Fee'), Tab(text: 'Students')],
        ),
      );
}

class _FeeDashboardTab extends StatelessWidget {
  const _FeeDashboardTab({
    required this.schoolClass,
    required this.students,
    required this.paid,
    required this.balance,
    required this.paidPercentage,
  });

  final SchoolClass schoolClass;
  final List<Student> students;
  final int paid;
  final int balance;
  final double paidPercentage;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _SectionCard(
            title: 'Fee payment dashboard',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _MiniStat(
                            label: 'Paid so far', value: _money.format(paid))),
                    Expanded(
                      child: _MiniStat(
                        label: 'Balance',
                        value: balance == 0 ? 'Paid' : _money.format(balance),
                        color: balance == 0 ? AppTheme.green : AppTheme.peach,
                      ),
                    ),
                    Expanded(
                        child: _MiniStat(
                            label: 'Students', value: '${students.length}')),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: paidPercentage,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFF0F2F1),
                    color: AppTheme.green,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${(paidPercentage * 100).round()}% of expected fees collected',
                    style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Students against fees',
            child: _StudentFeeChart(
              schoolClass: schoolClass,
              students: students,
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Class details',
            child: Column(
              children: [
                _DetailRow(label: 'Class teacher', value: schoolClass.teacher),
                _DetailRow(label: 'Term', value: schoolClass.term),
                _DetailRow(
                    label: 'Fee target',
                    value: _money.format(schoolClass.feeTarget)),
              ],
            ),
          ),
        ],
      );
}

class _StudentFeeChart extends StatelessWidget {
  const _StudentFeeChart({required this.schoolClass, required this.students});
  final SchoolClass schoolClass;
  final List<Student> students;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Legend(color: AppTheme.green, label: 'Paid'),
          const SizedBox(height: 10),
          _FeeBar(
            label: 'Class total',
            value: schoolClass.feePaid,
            max: schoolClass.feeTarget,
            color: AppTheme.green,
          ),
          _FeeBar(
            label: 'Balance',
            value: schoolClass.feeBalance,
            max: schoolClass.feeTarget,
            color: AppTheme.peach,
          ),
          const SizedBox(height: 8),
          const Text('Student records are not available for this class yet.',
              style: TextStyle(color: AppTheme.muted, fontSize: 11)),
        ],
      );
    }

    final visibleStudents = students.take(8).toList();
    final max = students.fold<int>(
        schoolClass.feeTarget,
        (current, student) =>
            [current, student.balance].reduce((a, b) => a > b ? a : b));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            _Legend(color: AppTheme.green, label: 'Paid'),
            SizedBox(width: 14),
            _Legend(color: AppTheme.peach, label: 'Balance'),
          ],
        ),
        const SizedBox(height: 14),
        for (final student in visibleStudents) ...[
          Text(student.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          _FeeBar(
            label: 'Paid',
            value: schoolClass.feeTarget > student.balance
                ? schoolClass.feeTarget - student.balance
                : 0,
            max: max,
            color: AppTheme.green,
          ),
          _FeeBar(
              label: 'Balance',
              value: student.balance,
              max: max,
              color: AppTheme.peach),
          const SizedBox(height: 7),
        ],
        if (students.length > visibleStudents.length)
          Text('+ ${students.length - visibleStudents.length} more students',
              style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 10)),
        ],
      );
}

class _FeeBar extends StatelessWidget {
  const _FeeBar(
      {required this.label,
      required this.value,
      required this.max,
      required this.color});
  final String label;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
              width: 48,
              child: Text(label,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 9))),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: max == 0 ? 0 : (value / max).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF0F2F1),
                  color: color,
                ),
              ),
            ),
          ),
          SizedBox(
              width: 72,
              child: Text(_money.format(value),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 9,
                      fontWeight: FontWeight.w700))),
        ],
      );
}

class _StudentsTab extends StatelessWidget {
  const _StudentsTab({
    required this.students,
    required this.asCards,
    required this.onToggle,
    required this.onStudentTap,
  });

  final List<Student> students;
  final bool asCards;
  final ValueChanged<bool> onToggle;
  final ValueChanged<Student> onStudentTap;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const _SectionCard(
        title: 'Students',
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Center(
              child: Text('No students found in this class.',
                  style: TextStyle(color: AppTheme.muted, fontSize: 12))),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Students',
                  style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ),
            ToggleButtons(
              isSelected: [!asCards, asCards],
              onPressed: (index) => onToggle(index == 1),
              borderRadius: BorderRadius.circular(9),
              constraints: const BoxConstraints(minWidth: 38, minHeight: 34),
              color: AppTheme.muted,
              selectedColor: AppTheme.peach,
              fillColor: AppTheme.peach.withValues(alpha: .12),
              borderColor: AppTheme.line,
              selectedBorderColor: AppTheme.peach.withValues(alpha: .5),
              children: const [
                Icon(Icons.view_list_outlined, size: 18),
                Icon(Icons.grid_view_outlined, size: 18),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (asCards)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2),
            itemBuilder: (_, index) => _StudentCard(
                student: students[index],
                onTap: () => onStudentTap(students[index])),
          )
        else
          Column(
            children: [
              for (final student in students)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StudentListTile(
                      student: student, onTap: () => onStudentTap(student)),
                ),
            ],
          ),
      ],
    );
  }
}

class _StudentListTile extends StatelessWidget {
  const _StudentListTile({required this.student, required this.onTap});
  final Student student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.line),
          ),
          child: Row(
            children: [
              _StudentAvatar(student: student, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                    Text('${student.admissionNo} · ${student.status}',
                        style: const TextStyle(
                            color: AppTheme.muted, fontSize: 10)),
                  ],
                ),
              ),
              Text(
                  student.balance == 0
                      ? 'Paid'
                      : _money.format(student.balance),
                  style: TextStyle(
                      color: student.balance == 0
                          ? AppTheme.green
                          : AppTheme.peach,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppTheme.muted, size: 18),
            ],
          ),
        ),
      );
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student, required this.onTap});
  final Student student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StudentAvatar(student: student, size: 48),
              const SizedBox(height: 8),
              Text(student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(student.admissionNo,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 10)),
              const SizedBox(height: 5),
              Text(
                  student.balance == 0
                      ? 'Paid'
                      : _money.format(student.balance),
                  style: TextStyle(
                      color: student.balance == 0
                          ? AppTheme.green
                          : AppTheme.peach,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({required this.student, required this.size});
  final Student student;
  final double size;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: size / 2,
        backgroundColor: AppTheme.peach.withValues(alpha: .18),
        backgroundImage:
            student.avatarUrl == null ? null : NetworkImage(student.avatarUrl!),
        child: student.avatarUrl == null
            ? Text(
                student.name.isEmpty ? '?' : student.name.substring(0, 1),
                style: TextStyle(
                    color: AppTheme.peach,
                    fontSize: size * .38,
                    fontWeight: FontWeight.w800),
              )
            : null,
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
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
          const SizedBox(height: 4),
          Text(value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color ?? AppTheme.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ],
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Text(label,
                    style:
                        const TextStyle(color: AppTheme.muted, fontSize: 12))),
            const SizedBox(width: 16),
            Flexible(
                child: Text(value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
          ],
        ),
      );
}
