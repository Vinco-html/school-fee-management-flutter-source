import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'store.dart';
import 'theme.dart';

final _documentMoney = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);
final _documentDate = DateFormat('d MMM yyyy');

enum DocumentKind { report, classList, termSchedule, feeStructure }

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key, required this.store});
  final SchoolStore store;

  @override
  Widget build(BuildContext context) {
    return _DocumentScroll(
      children: [
        const _DocumentHeading(
          title: 'Documents',
          subtitle:
              'Generate polished school records from your live workspace data.',
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 2
                : constraints.maxWidth >= 560
                    ? 2
                    : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: columns == 1 ? 2.2 : 1.65,
              children: [
                _DocumentCard(
                  icon: Icons.assessment_outlined,
                  tint: AppTheme.blue,
                  title: 'School report',
                  description:
                      'A summary of enrolment, collections and balances.',
                  onGenerate: () => _showDocument(
                    context,
                    kind: DocumentKind.report,
                    title: 'School report',
                    store: store,
                  ),
                ),
                _DocumentCard(
                  icon: Icons.groups_outlined,
                  tint: AppTheme.green,
                  title: 'Class lists',
                  description: 'Student registers grouped by class and stream.',
                  onGenerate: () => _showDocument(
                    context,
                    kind: DocumentKind.classList,
                    title: 'Class lists',
                    store: store,
                  ),
                ),
                _DocumentCard(
                  icon: Icons.event_note_outlined,
                  tint: AppTheme.purple,
                  title: 'Term schedule',
                  description:
                      'The planned events currently in the schedule section.',
                  onGenerate: () => _showDocument(
                    context,
                    kind: DocumentKind.termSchedule,
                    title: 'Term schedule',
                    store: store,
                  ),
                ),
                _DocumentCard(
                  icon: Icons.account_balance_wallet_outlined,
                  tint: AppTheme.peach,
                  title: 'Fee structure',
                  description: 'Fee targets and balances for every class.',
                  onGenerate: () => _showDocument(
                    context,
                    kind: DocumentKind.feeStructure,
                    title: 'Fee structure',
                    store: store,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

void showClassReport(BuildContext context, SchoolStore store,
    SchoolClass schoolClass, List<Student> students, List<Payment> payments) {
  _showDocument(
    context,
    kind: DocumentKind.report,
    title: '${schoolClass.name} report',
    store: store,
    schoolClass: schoolClass,
    students: students,
    payments: payments,
  );
}

void showClassFeeStructure(
    BuildContext context, SchoolStore store, SchoolClass schoolClass) {
  _showDocument(
    context,
    kind: DocumentKind.feeStructure,
    title: '${schoolClass.name} fee structure',
    store: store,
    schoolClass: schoolClass,
  );
}

void showPaymentReceipt(
    BuildContext context, Payment payment, Student? student) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DocumentPreview(
        title: 'Payment receipt',
        child: _ReceiptDocument(payment: payment, student: student),
      ),
    ),
  );
}

void _showDocument(
  BuildContext context, {
  required DocumentKind kind,
  required String title,
  SchoolStore? store,
  SchoolClass? schoolClass,
  List<Student>? students,
  List<Payment>? payments,
}) {
  final activeStore = store;
  if (activeStore == null) {
    throw ArgumentError('A store is required for this document.');
  }
  final classStudents = students ??
      (schoolClass == null
          ? activeStore.students
          : activeStore.students
              .where((student) =>
                  student.grade.trim().toLowerCase() ==
                  schoolClass.name.trim().toLowerCase())
              .toList());
  final classPayments = payments ??
      activeStore.payments
          .where((payment) =>
              classStudents.any((student) => student.id == payment.studentId))
          .toList();

  final document = switch (kind) {
    DocumentKind.report => _ReportDocument(
        store: activeStore,
        schoolClass: schoolClass,
        students: classStudents,
        payments: classPayments,
      ),
    DocumentKind.classList => _ClassListDocument(store: activeStore),
    DocumentKind.termSchedule => _ScheduleDocument(store: activeStore),
    DocumentKind.feeStructure => _FeeStructureDocument(
        store: activeStore,
        selectedClass: schoolClass,
      ),
  };

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DocumentPreview(title: title, child: document),
    ),
  );
}

class DocumentPreview extends StatelessWidget {
  const DocumentPreview({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              tooltip: 'Print or save',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Document is ready to print or save.')),
              ),
              icon: const Icon(Icons.download_outlined),
            ),
          ],
        ),
        body: _DocumentScroll(children: [child]),
      );
}

class _DocumentHeading extends StatelessWidget {
  const _DocumentHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 25,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
        ],
      );
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.icon,
    required this.tint,
    required this.title,
    required this.description,
    required this.onGenerate,
  });
  final IconData icon;
  final Color tint;
  final String title;
  final String description;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: tint.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: Text(description,
                  style: const TextStyle(
                      color: AppTheme.muted, fontSize: 12, height: 1.35)),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Generate'),
                ),
              ),
            ), // Spacer
          ],
        ),
      );
}

class _DocumentScroll extends StatelessWidget {
  const _DocumentScroll({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children),
          ),
        ),
      );
}

class _Paper extends StatelessWidget {
  const _Paper(
      {required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.line),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D1E2936), blurRadius: 18, offset: Offset(0, 8))
          ],
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: AppTheme.peach.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.school_outlined, color: AppTheme.peach),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PETUNIA SCHOOL',
                        style: TextStyle(
                            color: AppTheme.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1)),
                    Text(title,
                        style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ]),
            ),
            Text(_documentDate.format(DateTime.now()),
                style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
          ]),
          const Divider(height: 30),
          Text(subtitle,
              style: const TextStyle(
                  color: AppTheme.muted, fontSize: 12, height: 1.4)),
          const SizedBox(height: 20),
          child,
        ]),
      );
}

class _ReportDocument extends StatelessWidget {
  const _ReportDocument(
      {required this.store,
      required this.schoolClass,
      required this.students,
      required this.payments});
  final SchoolStore store;
  final SchoolClass? schoolClass;
  final List<Student> students;
  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    final collected = payments.fold<int>(0, (sum, item) => sum + item.amount);
    final outstanding =
        students.fold<int>(0, (sum, item) => sum + item.balance);
    final title = schoolClass == null
        ? 'School performance report'
        : '${schoolClass!.name} performance report';
    return _Paper(
      title: title,
      subtitle: 'A generated summary of student enrolment and fee collection.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _MetricGrid(metrics: [
          ('Students', '${students.length}'),
          ('Collected', _documentMoney.format(collected)),
          ('Outstanding', _documentMoney.format(outstanding)),
          ('Payments', '${payments.length}'),
        ]),
        const SizedBox(height: 22),
        const _DocumentSectionTitle('Student fee status'),
        const SizedBox(height: 8),
        for (final student in students.take(30))
          _DocumentRow(
              leading: student.admissionNo,
              title: student.name,
              trailing: student.balance == 0
                  ? 'Paid'
                  : _documentMoney.format(student.balance)),
        if (students.isEmpty)
          const _DocumentEmpty('No students are available for this report.'),
        if (schoolClass == null) ...[
          const SizedBox(height: 22),
          Text('Current term: ${store.summary?.term ?? 'Current term'}',
              style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
        ],
      ]),
    );
  }
}

class _ClassListDocument extends StatelessWidget {
  const _ClassListDocument({required this.store});
  final SchoolStore store;

  @override
  Widget build(BuildContext context) => _Paper(
        title: 'Class lists',
        subtitle:
            'Student registers grouped by the class recorded on each student profile.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final schoolClass in store.classes) ...[
              _DocumentSectionTitle(
                  '${schoolClass.name} ${schoolClass.stream}'),
              const SizedBox(height: 6),
              ...store.students
                  .where((student) =>
                      student.grade.trim().toLowerCase() ==
                      schoolClass.name.trim().toLowerCase())
                  .map((student) => _DocumentRow(
                      leading: student.admissionNo,
                      title: student.name,
                      trailing: student.guardian)),
              const SizedBox(height: 16),
            ],
            if (store.classes.isEmpty)
              const _DocumentEmpty('No classes are available.'),
          ],
        ),
      );
}

class _ScheduleDocument extends StatelessWidget {
  const _ScheduleDocument({required this.store});
  final SchoolStore store;

  @override
  Widget build(BuildContext context) => _Paper(
        title: 'Term schedule',
        subtitle: 'Planned events from the schedule section.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final event in store.events)
              _DocumentRow(
                leading: DateFormat('EEE').format(event.eventDate.toLocal()),
                title: event.title,
                trailing: DateFormat('d MMM, h:mm a')
                    .format(event.eventDate.toLocal()),
              ),
            if (store.events.isEmpty)
              const _DocumentEmpty('No term events have been scheduled.'),
          ],
        ),
      );
}

class _FeeStructureDocument extends StatelessWidget {
  const _FeeStructureDocument({required this.store, this.selectedClass});
  final SchoolStore store;
  final SchoolClass? selectedClass;

  @override
  Widget build(BuildContext context) {
    final classes = selectedClass == null ? store.classes : [selectedClass!];
    return _Paper(
      title: selectedClass == null
          ? 'Fee structure'
          : '${selectedClass!.name} fee structure',
      subtitle:
          'Fee targets and collection status by class for ${store.summary?.term ?? 'the current term'}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final schoolClass in classes)
            _DocumentRow(
              leading: '${schoolClass.name} ${schoolClass.stream}',
              title: 'Target ${_documentMoney.format(schoolClass.feeTarget)}',
              trailing: '${_documentMoney.format(schoolClass.feePaid)} paid',
            ),
          if (classes.isEmpty)
            const _DocumentEmpty('No classes are available.'),
        ],
      ),
    );
  }
}

class _ReceiptDocument extends StatelessWidget {
  const _ReceiptDocument({required this.payment, required this.student});
  final Payment payment;
  final Student? student;

  @override
  Widget build(BuildContext context) => _Paper(
        title: 'Official payment receipt',
        subtitle: 'Payment received and recorded in the school fee register.',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: AppTheme.green.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.check_circle_outline,
                  color: AppTheme.green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_documentMoney.format(payment.amount),
                    style: const TextStyle(
                        color: AppTheme.green,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
              ),
              Text(
                  payment.status.isEmpty
                      ? 'PAID'
                      : payment.status.toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 18),
          _ReceiptLine(label: 'Receipt number', value: payment.receiptNo),
          _ReceiptLine(
              label: 'Student', value: student?.name ?? payment.studentName),
          _ReceiptLine(
              label: 'Admission number', value: student?.admissionNo ?? '—'),
          _ReceiptLine(label: 'Payment method', value: payment.method),
          _ReceiptLine(
              label: 'Date received',
              value: DateFormat('d MMM yyyy, h:mm a')
                  .format(payment.paidAt.toLocal())),
        ]),
      );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final metric in metrics)
            Container(
              width: 170,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F6),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(metric.$1,
                        style: const TextStyle(
                            color: AppTheme.muted, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(metric.$2,
                        style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ]),
            ),
        ],
      );
}

class _DocumentSectionTitle extends StatelessWidget {
  const _DocumentSectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppTheme.ink, fontSize: 14, fontWeight: FontWeight.w800));
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow(
      {required this.leading, required this.title, required this.trailing});
  final String leading;
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.line))),
        child: Row(children: [
          SizedBox(
              width: 92,
              child: Text(leading,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11))),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Flexible(
              child: Text(trailing,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11))),
        ]),
      );
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Row(children: [
          SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12))),
          Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700))),
        ]),
      );
}

class _DocumentEmpty extends StatelessWidget {
  const _DocumentEmpty(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
      );
}
