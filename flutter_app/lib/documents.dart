import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'models.dart';
import 'store.dart';
import 'theme.dart';

final _documentMoney = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);
final _documentDate = DateFormat('d MMM yyyy');

/// Builds a fresh pdf.Document on demand — called right before export so the
/// PDF always reflects the latest store data, not whatever was true when the
/// preview screen first opened.
typedef PdfBuilder = pw.Document Function();

enum DocumentKind { report, classList, termSchedule, feeStructure, feeReport }

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key, required this.store});
  final SchoolStore store;

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  Map<DocumentKind, Widget?> previewCache = {};

  Widget? _getPreview(DocumentKind kind) {
    if (previewCache.containsKey(kind)) {
      return previewCache[kind];
    }

    final preview = switch (kind) {
      DocumentKind.report => _ReportDocumentPreview(
          store: widget.store,
          students: widget.store.students,
          payments: widget.store.payments,
        ),
      DocumentKind.classList => _ClassListDocumentPreview(store: widget.store),
      DocumentKind.termSchedule =>
        _ScheduleDocumentPreview(store: widget.store),
      DocumentKind.feeStructure => _FeeStructureDocumentPreview(
          store: widget.store,
        ),
      DocumentKind.feeReport => _FeeReportDocumentPreview(store: widget.store),
    };

    previewCache[kind] = preview;
    return preview;
  }

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
                ? 3
                : constraints.maxWidth >= 560
                    ? 2
                    : 1;
            // Fixed mainAxisExtent instead of a childAspectRatio: the card's
            // content height doesn't scale with width, so an aspect-ratio
            // based height can end up shorter than the content needs,
            // causing a bottom overflow. A fixed extent guarantees enough
            // room regardless of column count.
            return GridView(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 300,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Material(
                    color: Colors.transparent,
                    child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _showDocument(context,
                            kind: DocumentKind.report,
                            title: 'School Report',
                            store: widget.store),
                        child: _DocumentCard(
                          icon: Icons.assessment_outlined,
                          tint: AppTheme.blue,
                          title: 'School report',
                          description:
                              'A summary of enrolment, collections and balances.',
                          preview: _getPreview(DocumentKind.report),
                        ))),
                Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showDocument(context,
                          kind: DocumentKind.classList,
                          title: 'ClassList',
                          store: widget.store),
                      child: _DocumentCard(
                        icon: Icons.groups_outlined,
                        tint: AppTheme.green,
                        title: 'Class lists',
                        description: 'Student registers grouped by class.',
                        preview: _getPreview(DocumentKind.classList),
                      ),
                    )),
                Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _showDocument(
                        context,
                        kind: DocumentKind.termSchedule,
                        title: 'Term schedule',
                        store: widget.store,
                      ),
                      child: _DocumentCard(
                        icon: Icons.event_note_outlined,
                        tint: AppTheme.purple,
                        title: 'Term schedule',
                        description:
                            'The planned events currently in the schedule section.',
                        preview: _getPreview(DocumentKind.termSchedule),
                      ),
                    )),
                Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _showDocument(
                        context,
                        kind: DocumentKind.feeStructure,
                        title: 'Fee structure',
                        store: widget.store,
                      ),
                      child: _DocumentCard(
                        icon: Icons.account_balance_wallet_outlined,
                        tint: AppTheme.peach,
                        title: 'Fee structure',
                        description:
                            'Fee targets and balances for every class.',
                        preview: _getPreview(DocumentKind.feeStructure),
                      ),
                    )),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _showDocument(
                      context,
                      kind: DocumentKind.feeReport,
                      title: 'Fee report',
                      store: widget.store,
                    ),
                    child: _DocumentCard(
                      icon: Icons.summarize_outlined,
                      tint: AppTheme.blue,
                      title: 'Fee report',
                      description:
                          'Collection progress, balances and per-class breakdown.',
                      preview: _getPreview(DocumentKind.feeReport),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showDocument(
    BuildContext context, {
    required DocumentKind kind,
    required String title,
    SchoolStore? store,
    SchoolClass? schoolClass,
  }) {
    final activeStore = store;
    if (activeStore == null) {
      throw ArgumentError('A store is required for this document.');
    }

    final document = switch (kind) {
      DocumentKind.report => _ReportDocument(
          store: activeStore,
        ),
      DocumentKind.classList => _ClassListDocument(store: activeStore),
      DocumentKind.termSchedule => _ScheduleDocument(store: activeStore),
      DocumentKind.feeStructure => _FeeStructureDocument(
          store: activeStore,
        ),
      DocumentKind.feeReport => _FeeReportDocument(
          store: activeStore,
          students: activeStore.students,
          payments: activeStore.payments,
        ),
    };

    final pdfBuilder = switch (kind) {
      DocumentKind.report => () => _buildReportPdf(activeStore),
      DocumentKind.classList => () => _buildClassListPdf(activeStore),
      DocumentKind.termSchedule => () => _buildSchedulePdf(activeStore),
      DocumentKind.feeStructure => () => _buildFeeStructurePdf(activeStore),
      DocumentKind.feeReport => () => _buildFeeReportPdf(
            activeStore,
            activeStore.students,
            activeStore.payments,
          ),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentPreview(
          title: title,
          fileName: title,
          buildPdf: pdfBuilder,
          child: document,
        ),
      ),
    );
  }
}

void showClassReport(BuildContext context, SchoolStore store,
    SchoolClass schoolClass, List<Student> students, List<Payment> payments) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DocumentPreview(
        title: '${schoolClass.name} report',
        fileName: '${schoolClass.name} report',
        buildPdf: () => _buildReportPdf(
          store,
          schoolClass: schoolClass,
          students: students,
          payments: payments,
        ),
        child: _ReportDocument(
          store: store,
          schoolClass: schoolClass,
          students: students,
          payments: payments,
        ),
      ),
    ),
  );
}

void showClassFeeStructure(
    BuildContext context, SchoolStore store, SchoolClass schoolClass) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DocumentPreview(
        title: '${schoolClass.name} fee structure',
        fileName: '${schoolClass.name} fee structure',
        buildPdf: () =>
            _buildFeeStructurePdf(store, selectedClass: schoolClass),
        child: _FeeStructureDocument(
          store: store,
          selectedClass: schoolClass,
        ),
      ),
    ),
  );
}

void showPaymentReceipt(
    BuildContext context, Payment payment, Student? student) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DocumentPreview(
        title: 'Payment receipt',
        fileName: 'Receipt ${payment.receiptNo}',
        buildPdf: () => _buildReceiptPdf(payment, student),
        child: _ReceiptDocument(payment: payment, student: student),
      ),
    ),
  );
}

/// Standalone entry point for the fee report, mirroring showClassReport /
/// showPaymentReceipt above. Use this wherever the old separate
/// fee_report_document.dart file used to be imported and opened directly.
void showFeeReport(BuildContext context, SchoolStore store) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DocumentPreview(
        title: 'Fee report',
        fileName: 'Fee report',
        buildPdf: () =>
            _buildFeeReportPdf(store, store.students, store.payments),
        child: _FeeReportDocument(
          store: store,
          students: store.students,
          payments: store.payments,
        ),
      ),
    ),
  );
}

class DocumentPreview extends StatefulWidget {
  const DocumentPreview({
    super.key,
    required this.title,
    required this.child,
    required this.buildPdf,
    required this.fileName,
  });
  final String title;
  final Widget child;
  final PdfBuilder buildPdf;
  final String fileName;

  @override
  State<DocumentPreview> createState() => _DocumentPreviewState();
}

class _DocumentPreviewState extends State<DocumentPreview> {
  bool _exporting = false;

  String get _safeFileName {
    final cleaned =
        widget.fileName.trim().replaceAll(RegExp(r'[^A-Za-z0-9 _-]+'), '');
    final withUnderscores = cleaned.replaceAll(RegExp(r'\s+'), '_');
    return withUnderscores.isEmpty ? 'document' : withUnderscores;
  }

  Future<void> _export(
      Future<void> Function(Uint8List bytes, String fileName) action) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await widget.buildPdf().save();
      await action(bytes, '$_safeFileName.pdf');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong creating the PDF.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            if (_exporting)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              PopupMenuButton<String>(
                tooltip: 'Export as PDF',
                icon: const Icon(Icons.ios_share_outlined),
                onSelected: (value) {
                  switch (value) {
                    case 'share':
                      _export((bytes, name) => Printing.sharePdf(
                            bytes: bytes,
                            filename: name,
                          ));
                      break;
                    case 'print':
                      _export((bytes, name) => Printing.layoutPdf(
                            onLayout: (_) async => bytes,
                            name: name,
                          ));
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(Icons.ios_share_outlined),
                      title: Text('Share / Save PDF'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'print',
                    child: ListTile(
                      leading: Icon(Icons.print_outlined),
                      title: Text('Print'),
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: _DocumentScroll(children: [widget.child]),
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
    this.preview,
  });
  final IconData icon;
  final Color tint;
  final String title;
  final String description;

  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preview != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: AppTheme.line),
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  color: AppTheme.line,
                ),
                padding: const EdgeInsets.all(5),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Transform.scale(
                      scale: 1,
                      child: SizedBox(
                        child: preview,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                        color: tint.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(13)),
                    child: Icon(icon, color: tint),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.muted, fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
  const _Paper({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
                    const Text('PETUNIA SCHOOLS',
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

class _ReportDocumentPreview extends StatelessWidget {
  const _ReportDocumentPreview({
    required this.store,
    required this.students,
    required this.payments,
  });
  final SchoolStore store;
  final List<Student> students;
  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    final collected = payments.fold<int>(0, (sum, item) => sum + item.amount);
    final outstanding =
        students.fold<int>(0, (sum, item) => sum + item.balance);

    return _Paper(
      title: 'School Performance Report',
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
        for (final student in students.take(10))
          _DocumentRow(
              leading: student.admissionNo,
              title: student.name,
              trailing: student.balance == 0
                  ? 'Paid'
                  : _documentMoney.format(student.balance)),
      ]),
    );
  }
}

class _ReportDocument extends StatelessWidget {
  const _ReportDocument({
    required this.store,
    this.schoolClass,
    this.students,
    this.payments,
  });
  final SchoolStore store;
  final SchoolClass? schoolClass;
  final List<Student>? students;
  final List<Payment>? payments;

  @override
  Widget build(BuildContext context) {
    final classStudents = students ??
        (schoolClass == null
            ? store.students
            : store.students
                .where((student) =>
                    student.grade.trim().toLowerCase() ==
                    schoolClass!.name.trim().toLowerCase())
                .toList());
    final classPayments = payments ??
        store.payments
            .where((payment) =>
                classStudents.any((student) => student.id == payment.studentId))
            .toList();

    final collected =
        classPayments.fold<int>(0, (sum, item) => sum + item.amount);
    final outstanding =
        classStudents.fold<int>(0, (sum, item) => sum + item.balance);
    final title = schoolClass == null
        ? 'School Performance Report'
        : '${schoolClass!.name} Performance Report';
    return _Paper(
      title: title,
      subtitle: 'A generated summary of student enrolment and fee collection.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _MetricGrid(metrics: [
          ('Students', '${classStudents.length}'),
          ('Collected', _documentMoney.format(collected)),
          ('Outstanding', _documentMoney.format(outstanding)),
          ('Payments', '${classPayments.length}'),
        ]),
        const SizedBox(height: 22),
        const _DocumentSectionTitle('Student fee status'),
        const SizedBox(height: 8),
        for (final student in classStudents)
          _DocumentRow(
              leading: student.admissionNo,
              title: student.name,
              trailing: student.balance == 0
                  ? 'Paid'
                  : _documentMoney.format(student.balance)),
        if (classStudents.isEmpty)
          const _DocumentEmpty('No students are available for this report.'),
      ]),
    );
  }
}

class _ClassListDocumentPreview extends StatelessWidget {
  const _ClassListDocumentPreview({required this.store});
  final SchoolStore store;

  @override
  Widget build(BuildContext context) {
    final firstClass = store.classes.isNotEmpty ? store.classes.first : null;
    if (firstClass == null) {
      return const _DocumentEmpty('No classes are available.');
    }

    final classStudents = store.students
        .where((student) =>
            student.grade.trim().toLowerCase() ==
            firstClass.name.trim().toLowerCase())
        .toList();

    return _Paper(
      title: '${firstClass.name} ${firstClass.stream} - Class List',
      subtitle: 'Student register for ${firstClass.name} ${firstClass.stream}.',
      child: _ClassTable(students: classStudents),
    );
  }
}

class _ClassListDocument extends StatelessWidget {
  const _ClassListDocument({required this.store});
  final SchoolStore store;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          children: [
            for (final schoolClass in store.classes) ...[
              _ClassListPage(
                schoolClass: schoolClass,
                students: store.students
                    .where((student) =>
                        student.grade.trim().toLowerCase() ==
                        schoolClass.name.trim().toLowerCase())
                    .toList(),
              ),
              const SizedBox(height: 30),
            ],
            if (store.classes.isEmpty)
              const _DocumentEmpty('No classes are available.'),
          ],
        ),
      );
}

class _ClassListPage extends StatelessWidget {
  const _ClassListPage({
    required this.schoolClass,
    required this.students,
  });
  final SchoolClass schoolClass;
  final List<Student> students;

  @override
  Widget build(BuildContext context) => _Paper(
        title: '${schoolClass.name} ${schoolClass.stream} - Class List',
        subtitle:
            'Student register for ${schoolClass.name} ${schoolClass.stream}.',
        child: _ClassTable(students: students),
      );
}

class _ClassTable extends StatelessWidget {
  const _ClassTable({required this.students});
  final List<Student> students;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table header
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.line),
            ),
            child: Row(
              children: [
                _TableCell(
                  text: 'No.',
                  flex: 1,
                  isHeader: true,
                ),
                _TableCell(
                  text: 'Admission No.',
                  flex: 2,
                  isHeader: true,
                ),
                _TableCell(
                  text: 'Student Name',
                  flex: 3,
                  isHeader: true,
                ),
                _TableCell(
                  text: 'Guardian',
                  flex: 2,
                  isHeader: true,
                ),
              ],
            ),
          ),
          // Table rows
          for (int i = 0; i < students.length; i++)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.line),
                  left: BorderSide(color: AppTheme.line),
                  right: BorderSide(color: AppTheme.line),
                ),
              ),
              child: Row(
                children: [
                  _TableCell(
                    text: '${i + 1}',
                    flex: 1,
                  ),
                  _TableCell(
                    text: students[i].admissionNo,
                    flex: 2,
                  ),
                  _TableCell(
                    text: students[i].name,
                    flex: 3,
                  ),
                  _TableCell(
                    text: students[i].guardian,
                    flex: 2,
                  ),
                ],
              ),
            ),
          if (students.isEmpty)
            const _DocumentEmpty('No students in this class.'),
        ],
      );
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.text,
    required this.flex,
    this.isHeader = false,
  });
  final String text;
  final int flex;
  final bool isHeader;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: AppTheme.line),
            ),
          ),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isHeader ? AppTheme.ink : AppTheme.ink,
              fontSize: isHeader ? 12 : 11,
              fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      );
}

class _ScheduleDocumentPreview extends StatelessWidget {
  const _ScheduleDocumentPreview({required this.store});
  final SchoolStore store;

  @override
  Widget build(BuildContext context) => _Paper(
        title: 'Term Schedule',
        subtitle: 'Planned events from the schedule section.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final event in store.events.take(8))
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

class _ScheduleDocument extends StatelessWidget {
  const _ScheduleDocument({required this.store});
  final SchoolStore store;

  @override
  Widget build(BuildContext context) => _Paper(
        title: 'Term Schedule',
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

class _FeeStructureDocumentPreview extends StatelessWidget {
  const _FeeStructureDocumentPreview({required this.store});
  final SchoolStore store;

  @override
  Widget build(BuildContext context) {
    final classes = store.classes;
    return _Paper(
      title: 'Fee Structure',
      subtitle:
          'Fee targets and collection status by class for ${store.summary?.term ?? 'the current term'}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final schoolClass in classes.take(3))
            _DocumentRow(
              leading: '${schoolClass.name} ${schoolClass.stream}',
              title: 'Target ${_documentMoney.format(schoolClass.feeTarget)}',
              trailing: '${_documentMoney.format(schoolClass.feePaid)} paid',
            ),
        ],
      ),
    );
  }
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
          ? 'Fee Structure'
          : '${selectedClass!.name} Fee Structure',
      subtitle:
          'Fee targets and collection status by class for ${store.summary?.term ?? 'the current term'}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final schoolClass in classes)
            _FeeClassSection(schoolClass: schoolClass),
          if (classes.isEmpty)
            const _DocumentEmpty('No classes are available.'),
        ],
      ),
    );
  }
}

class _FeeClassSection extends StatelessWidget {
  const _FeeClassSection({required this.schoolClass});
  final SchoolClass schoolClass;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${schoolClass.name} ${schoolClass.stream}',
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.line),
            ),
            child: Column(
              children: [
                // Header row
                Container(
                  color: const Color(0xFFF5F6F6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: AppTheme.line),
                            ),
                          ),
                          child: const Text(
                            'Description',
                            style: TextStyle(
                              color: AppTheme.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Text(
                            'Amount',
                            style: TextStyle(
                              color: AppTheme.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              textBaseline: TextBaseline.alphabetic,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Fee rows
                _FeeRow(
                  label: 'Term Fee',
                  amount: _documentMoney.format(schoolClass.feeTarget),
                ),
                _FeeRow(
                  label: 'Amount Paid',
                  amount: _documentMoney.format(schoolClass.feePaid),
                ),
                _FeeRow(
                  label: 'Outstanding Balance',
                  amount: _documentMoney
                      .format(schoolClass.feeTarget - schoolClass.feePaid),
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });
  final String label;
  final String amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: isTotal ? const Color(0xFFF5F6F6) : null,
          border: Border(
            bottom: BorderSide(color: AppTheme.line),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppTheme.line),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 11,
                    fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Text(
                  amount,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 11,
                    fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
      );
}

class _ReceiptDocument extends StatelessWidget {
  const _ReceiptDocument({required this.payment, required this.student});
  final Payment payment;
  final Student? student;

  @override
  Widget build(BuildContext context) => _Paper(
        title: 'Official Payment Receipt',
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

// ---------------------------------------------------------------------------
// Fee report — merged in from the old standalone fee_report_document.dart so
// it lives alongside the other document types with no extra import needed.
// ---------------------------------------------------------------------------

class _FeeReportDocumentPreview extends StatelessWidget {
  const _FeeReportDocumentPreview({required this.store});
  final SchoolStore store;

  @override
  Widget build(BuildContext context) {
    final students = store.students;
    final payments = store.payments;
    final collected = payments.fold<int>(0, (sum, p) => sum + p.amount);
    final cleared = students.where((s) => s.balance == 0).length;

    return _Paper(
      title: 'Fee Collection Report',
      subtitle: 'Collection progress and balances across every class.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _MetricGrid(metrics: [
          ('Collected', _documentMoney.format(collected)),
          ('Cleared', '$cleared / ${students.length}'),
          ('Payments', '${payments.length}'),
        ]),
        const SizedBox(height: 18),
        const _DocumentSectionTitle('Class breakdown'),
        const SizedBox(height: 8),
        for (final schoolClass in store.classes.take(4))
          _DocumentRow(
            leading: '${schoolClass.name} ${schoolClass.stream}',
            title: 'Target ${_documentMoney.format(schoolClass.feeTarget)}',
            trailing: '${_documentMoney.format(schoolClass.feePaid)} paid',
          ),
        if (store.classes.isEmpty)
          const _DocumentEmpty('No classes are available.'),
      ]),
    );
  }
}

/// Full fee report: totals, an overall-progress metric grid and a per-class
/// breakdown table.
class _FeeReportDocument extends StatelessWidget {
  const _FeeReportDocument({
    required this.store,
    required this.students,
    required this.payments,
  });

  final SchoolStore store;
  final List<Student> students;
  final List<Payment> payments;

  /// Looks up the fee target for a student's class. Returns 0 if the
  /// student's class can't be matched, instead of throwing.
  int _expectedFor(Student student) {
    final matches = store.classes.where((c) =>
        c.name.trim().toLowerCase() == student.grade.trim().toLowerCase());
    return matches.isNotEmpty ? matches.first.feeTarget : 0;
  }

  @override
  Widget build(BuildContext context) {
    final totalExpected =
        students.fold<int>(0, (sum, student) => sum + _expectedFor(student));
    final totalCollected =
        payments.fold<int>(0, (sum, payment) => sum + payment.amount);
    final clearedStudents = students.where((s) => s.balance == 0).length;
    final overallProgress =
        totalExpected == 0 ? 0.0 : (totalCollected / totalExpected) * 100;
    final avgPayment =
        payments.isEmpty ? 0 : (totalCollected ~/ payments.length);

    return _Paper(
      title: 'Fee Collection Report',
      subtitle:
          'Collection progress, balances and per-class breakdown for ${store.summary?.term ?? 'the current term'}.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
          children: [
            _FeeReportMetricCard(
              title: 'TOTAL EXPECTED',
              value: _documentMoney.format(totalExpected),
              color: AppTheme.blue,
            ),
            _FeeReportMetricCard(
              title: 'TOTAL COLLECTED',
              value: _documentMoney.format(totalCollected),
              color: AppTheme.green,
            ),
            _FeeReportMetricCard(
              title: 'OVERALL PROGRESS',
              value: '${overallProgress.toStringAsFixed(1)}%',
              color: AppTheme.purple,
            ),
            _FeeReportMetricCard(
              title: 'AVG PAYMENT',
              value: _documentMoney.format(avgPayment),
              color: AppTheme.peach,
            ),
          ],
        ),
        const SizedBox(height: 26),
        const _DocumentSectionTitle('Class summary'),
        const SizedBox(height: 12),
        _FeeReportTable(store: store, students: students, payments: payments),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.line),
          ),
          child: Text(
            'Total payments: ${payments.length} · $clearedStudents/${students.length} students cleared',
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (students.isEmpty)
          const _DocumentEmpty('No students are available for this report.'),
      ]),
    );
  }
}

class _FeeReportMetricCard extends StatelessWidget {
  const _FeeReportMetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}

class _FeeReportTable extends StatelessWidget {
  const _FeeReportTable({
    required this.store,
    required this.students,
    required this.payments,
  });

  final SchoolStore store;
  final List<Student> students;
  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF5F6F6),
            child: const Row(
              children: [
                _FeeTableHeader(text: '#', flex: 1),
                _FeeTableHeader(text: 'Class', flex: 2),
                _FeeTableHeader(text: 'Students', flex: 1),
                _FeeTableHeader(text: 'Expected', flex: 2),
                _FeeTableHeader(text: 'Collected', flex: 2),
                _FeeTableHeader(text: 'Balance', flex: 2),
                _FeeTableHeader(text: 'Progress', flex: 1),
              ],
            ),
          ),
          for (int i = 0; i < store.classes.length; i++)
            _FeeReportTableRow(
              classNumber: i + 1,
              schoolClass: store.classes[i],
              students: students
                  .where((s) =>
                      s.grade.trim().toLowerCase() ==
                      store.classes[i].name.trim().toLowerCase())
                  .toList(),
              payments: payments
                  .where((p) => students
                      .where((s) =>
                          s.grade.trim().toLowerCase() ==
                          store.classes[i].name.trim().toLowerCase())
                      .any((s) => s.id == p.studentId))
                  .toList(),
            ),
          if (store.classes.isEmpty)
            const _DocumentEmpty('No classes are available.'),
        ],
      ),
    );
  }
}

class _FeeTableHeader extends StatelessWidget {
  const _FeeTableHeader({required this.text, required this.flex});
  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppTheme.line)),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
}

class _FeeReportTableRow extends StatelessWidget {
  const _FeeReportTableRow({
    required this.classNumber,
    required this.schoolClass,
    required this.students,
    required this.payments,
  });

  final int classNumber;
  final SchoolClass schoolClass;
  final List<Student> students;
  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    final totalExpected = students.length * schoolClass.feeTarget;
    final totalCollected = payments.fold<int>(0, (sum, p) => sum + p.amount);
    final balance = totalExpected - totalCollected;
    final progress =
        totalExpected == 0 ? 0.0 : (totalCollected / totalExpected) * 100;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.line)),
      ),
      child: Row(
        children: [
          _FeeTableCell(text: '#$classNumber', flex: 1),
          _FeeTableCell(
              text: '${schoolClass.name} ${schoolClass.stream}', flex: 2),
          _FeeTableCell(text: '${students.length}', flex: 1),
          _FeeTableCell(text: _documentMoney.format(totalExpected), flex: 2),
          _FeeTableCell(text: _documentMoney.format(totalCollected), flex: 2),
          _FeeTableCell(text: _documentMoney.format(balance), flex: 2),
          _FeeTableCell(text: '${progress.toStringAsFixed(1)}%', flex: 1),
        ],
      ),
    );
  }
}

class _FeeTableCell extends StatelessWidget {
  const _FeeTableCell({required this.text, required this.flex});
  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppTheme.line)),
          ),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// PDF builders — one per document kind, used by DocumentPreview's export
// menu (Share / Save, Print). Built with pw.MultiPage so long lists (a big
// class, many payments) paginate automatically instead of clipping.
// ---------------------------------------------------------------------------

pw.Widget _pdfHeader(String title, String subtitle) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PETUNIA SCHOOLS',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2)),
                pw.SizedBox(height: 2),
                pw.Text(title,
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Text(_documentDate.format(DateTime.now()),
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 6),
        pw.Text(subtitle,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 14),
      ],
    );

pw.Widget _pdfMetricGrid(List<(String, String)> metrics) => pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final metric in metrics)
          pw.Container(
            width: 130,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(metric.$1,
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey600)),
                pw.SizedBox(height: 2),
                pw.Text(metric.$2,
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
      ],
    );

pw.Widget _pdfRow(String leading, String title, String trailing) =>
    pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(children: [
        pw.SizedBox(
          width: 70,
          child: pw.Text(leading,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
        pw.Expanded(
          child: pw.Text(title,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Text(trailing,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ]),
    );

pw.Widget _pdfClassTable(List<Student> students) {
  if (students.isEmpty) {
    return pw.Text('No students in this class.',
        style: const pw.TextStyle(color: PdfColors.grey600));
  }
  return pw.TableHelper.fromTextArray(
    headers: const ['No.', 'Admission No.', 'Student Name', 'Guardian'],
    data: [
      for (int i = 0; i < students.length; i++)
        [
          '${i + 1}',
          students[i].admissionNo,
          students[i].name,
          students[i].guardian,
        ],
    ],
    headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
    cellStyle: const pw.TextStyle(fontSize: 9),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
  );
}

pw.Document _buildReportPdf(
  SchoolStore store, {
  SchoolClass? schoolClass,
  List<Student>? students,
  List<Payment>? payments,
}) {
  final classStudents = students ??
      (schoolClass == null
          ? store.students
          : store.students
              .where((s) =>
                  s.grade.trim().toLowerCase() ==
                  schoolClass.name.trim().toLowerCase())
              .toList());
  final classPayments = payments ??
      store.payments
          .where((p) => classStudents.any((s) => s.id == p.studentId))
          .toList();
  final collected = classPayments.fold<int>(0, (sum, i) => sum + i.amount);
  final outstanding = classStudents.fold<int>(0, (sum, i) => sum + i.balance);
  final title = schoolClass == null
      ? 'School Performance Report'
      : '${schoolClass.name} Performance Report';

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => context.pageNumber == 1
          ? _pdfHeader(title,
              'A generated summary of student enrolment and fee collection.')
          : pw.SizedBox(),
      build: (context) => [
        _pdfMetricGrid([
          ('Students', '${classStudents.length}'),
          ('Collected', _documentMoney.format(collected)),
          ('Outstanding', _documentMoney.format(outstanding)),
          ('Payments', '${classPayments.length}'),
        ]),
        pw.SizedBox(height: 16),
        pw.Text('Student fee status',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        if (classStudents.isEmpty)
          pw.Text('No students are available for this report.',
              style: const pw.TextStyle(color: PdfColors.grey600))
        else
          for (final s in classStudents)
            _pdfRow(s.admissionNo, s.name,
                s.balance == 0 ? 'Paid' : _documentMoney.format(s.balance)),
      ],
    ),
  );
  return doc;
}

pw.Document _buildClassListPdf(SchoolStore store) {
  final doc = pw.Document();
  if (store.classes.isEmpty) {
    doc.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(28),
        build: (context) =>
            _pdfHeader('Class Lists', 'No classes are available.'),
      ),
    );
    return doc;
  }
  for (final schoolClass in store.classes) {
    final classStudents = store.students
        .where((s) =>
            s.grade.trim().toLowerCase() ==
            schoolClass.name.trim().toLowerCase())
        .toList();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => context.pageNumber == 1
            ? _pdfHeader(
                '${schoolClass.name} ${schoolClass.stream} - Class List',
                'Student register for ${schoolClass.name} ${schoolClass.stream}.',
              )
            : pw.SizedBox(),
        build: (context) => [_pdfClassTable(classStudents)],
      ),
    );
  }
  return doc;
}

pw.Document _buildSchedulePdf(SchoolStore store) {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => context.pageNumber == 1
          ? _pdfHeader(
              'Term Schedule', 'Planned events from the schedule section.')
          : pw.SizedBox(),
      build: (context) => [
        if (store.events.isEmpty)
          pw.Text('No term events have been scheduled.',
              style: const pw.TextStyle(color: PdfColors.grey600))
        else
          for (final event in store.events)
            _pdfRow(
              DateFormat('EEE').format(event.eventDate.toLocal()),
              event.title,
              DateFormat('d MMM, h:mm a').format(event.eventDate.toLocal()),
            ),
      ],
    ),
  );
  return doc;
}

pw.Document _buildFeeStructurePdf(SchoolStore store,
    {SchoolClass? selectedClass}) {
  final classes = selectedClass == null ? store.classes : [selectedClass];
  final doc = pw.Document();

  // Default fees from image - used as fallback if class fee is 0
  final defaultFees = {
    'PLAYGROUP': ['6,000', '6,000', '5,000'],
    'PRE-PRIMARY 1': ['7,000', '7,000', '6,000'],
    'PRE-PRIMARY 2': ['8,000', '8,000', '7,000'],
    'GRADE 1': ['9,000', '9,000', '8,000'],
    'GRADE 2': ['9,000', '9,000', '8,000'],
    'GRADE 3': ['10,000', '10,000', '9,000'],
  };

  String feeForClass(SchoolClass c) {
    // This is your system value - will replace the 6,000 / 7,000 etc
    if (c.feeTarget > 0) return _documentMoney.format(c.feeTarget);
    final key = c.name.toUpperCase().trim();
    return defaultFees[key]?[0] ?? _documentMoney.format(c.feeTarget);
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('PETUNIA SCHOOL',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('RUAI AND SAIKA', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text('PRE-SCHOOL/PRIMARY/JUNIOR SECONDARY',
              style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 8),
          pw.Text('TEL: 0759948550', style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 10),
          pw.Text('PETUNIA SCHOOL SAIKA FEES STRUCTURE 2026',
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(
              'NOTE THAT: SCHOOL FEES SHOULD BE PAID BEFORE OR IMMEDIETELY THE SCHOOL OPENS',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
        ],
      ),
      build: (context) => [
        // ===== 1. DYNAMIC TERM FEES - FROM SYSTEM =====
        pw.TableHelper.fromTextArray(
          headers: const ['GRADE', 'TERM 1', 'TERM 2', 'TERM 3'],
          headerStyle:
              pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          data: classes.map((c) {
            // Replace with your actual term-wise fee if you have it
            // e.g. c.term1Fee, c.term2Fee, c.term3Fee
            final systemFee = feeForClass(c);
            return [
              '${c.name} ${c.stream}'.trim(),
              '$systemFee\n(Fees, lunch and 10 o\'clock tea)',
              '$systemFee\n(Fees, lunch and 10 o\'clock tea)',
              '$systemFee\n(Fees, lunch and 10 o\'clock tea)',
            ];
          }).toList(),
        ),
        pw.SizedBox(height: 12),

        // ===== 2. STATIC TABLE =====
        pw.TableHelper.fromTextArray(
          headers: const ['DESCRIPTION', 'CHARGES', 'DURATION'],
          headerStyle:
              pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          data: const [
            ['STATIONERY', 'KSH 2500', 'ANNUALLY'],
            ['WORK BOOKS', 'KSH 2000\n(400 PER BOOK)', 'ANNUALLY'],
            ['REPORT TOOL/ DIARY', '600', 'ANNUALLY'],
            ['COMPUTER STUDIES', '1000', 'TERMLY'],
            [
              'ADMISSION FEES',
              'KSH 500 (NEW PARENT)\nKSH 300 (OLD PARENT)',
              'ONCE'
            ],
            ['TISSUE PAPER\nHANDWASH', '3 PIECES (BELLA)\n500ML', 'TERMLY'],
            ['SCRAP BOOK', '', 'ANNUALLY'],
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Center(
            child: pw.Text('SCHOOL UNIFORM',
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 6),

        // ===== 3. STATIC UNIFORM TABLE =====
        pw.TableHelper.fromTextArray(
          headers: const ['BOYS', 'GIRLS'],
          headerStyle:
              pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          data: const [
            ['Trouser-Light grey', 'Skirts-Light grey with suspenders'],
            ['Shirt-Sky blue', 'Blouse-Sky blue'],
            ['Pullover-Grey mix', 'Pullover-Grey mix'],
            ['Tie-Wine red', 'Tie-wine red'],
            ['Socks-Grey with red strips', 'Socks-Grey with red strips'],
            [
              'Tracksuit-Grey with white strips at the side',
              'Tracksuit-Grey with strips at the side'
            ],
            ['T-shirt_Red', 'T-Shirt_Red'],
            ['Fleece jacket-Normal grey', 'Fleece jacket- Normal Grey'],
            [
              'Shoes- Black leather with laces',
              'Shoes-Black leather with laces'
            ],
            ['Sport shoes- Black Bata Bullet', 'Sport shoes-Black Bata Bullet'],
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Center(
            child: pw.Text('CO-CURRICULUM ACTIVITIES',
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: const ['', ''],
          data: const [
            ['Swimming', 'Ksh.200 per session'],
            ['Cookery', 'Ksh.50 per session'],
            ['Scout', 'Ksh.20 per session'],
            ['taikwondo', 'Ksh.50 per session'],
            ['Piano', 'Ksh.50 per session'],
          ],
          cellStyle: const pw.TextStyle(fontSize: 8),
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        ),
        pw.Center(
            child: pw.Column(
          children: [
            pw.Text('FEE PAYMENT',
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Text("PAY VIA EQUITY",
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Text("BUSINESS NUMBER: 247247",
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))
          ],
        )),
      ],
    ),
  );
  return doc;
}

pw.Document _buildFeeReportPdf(
    SchoolStore store, List<Student> students, List<Payment> payments) {
  int expectedFor(Student s) {
    final matches = store.classes.where(
        (c) => c.name.trim().toLowerCase() == s.grade.trim().toLowerCase());
    return matches.isNotEmpty ? matches.first.feeTarget : 0;
  }

  final totalExpected = students.fold<int>(0, (sum, s) => sum + expectedFor(s));
  final totalCollected = payments.fold<int>(0, (sum, p) => sum + p.amount);
  final clearedStudents = students.where((s) => s.balance == 0).length;
  final overallProgress =
      totalExpected == 0 ? 0.0 : (totalCollected / totalExpected) * 100;
  final avgPayment = payments.isEmpty ? 0 : (totalCollected ~/ payments.length);

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => context.pageNumber == 1
          ? _pdfHeader(
              'Fee Collection Report',
              'Collection progress, balances and per-class breakdown for ${store.summary?.term ?? 'the current term'}.',
            )
          : pw.SizedBox(),
      build: (context) => [
        _pdfMetricGrid([
          ('Total expected', _documentMoney.format(totalExpected)),
          ('Total collected', _documentMoney.format(totalCollected)),
          ('Overall progress', '${overallProgress.toStringAsFixed(1)}%'),
          ('Avg payment', _documentMoney.format(avgPayment)),
        ]),
        pw.SizedBox(height: 16),
        pw.Text('Class summary',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const [
            '#',
            'Class',
            'Students',
            'Expected',
            'Collected',
            'Balance',
            'Progress',
          ],
          data: [
            for (int i = 0; i < store.classes.length; i++)
              () {
                final schoolClass = store.classes[i];
                final classStudents = students
                    .where((s) =>
                        s.grade.trim().toLowerCase() ==
                        schoolClass.name.trim().toLowerCase())
                    .toList();
                final classPayments = payments
                    .where((p) => classStudents.any((s) => s.id == p.studentId))
                    .toList();
                final expected = classStudents.length * schoolClass.feeTarget;
                final collected =
                    classPayments.fold<int>(0, (sum, p) => sum + p.amount);
                final balance = expected - collected;
                final progress =
                    expected == 0 ? 0.0 : (collected / expected) * 100;
                return [
                  '#${i + 1}',
                  '${schoolClass.name} ${schoolClass.stream}',
                  '${classStudents.length}',
                  _documentMoney.format(expected),
                  _documentMoney.format(collected),
                  _documentMoney.format(balance),
                  '${progress.toStringAsFixed(1)}%',
                ];
              }(),
          ],
          headerStyle:
              pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        ),
        pw.SizedBox(height: 14),
        pw.Text(
          'Total payments: ${payments.length} · $clearedStudents/${students.length} students cleared',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    ),
  );
  return doc;
}

pw.Widget _pdfReceiptLine(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(label,
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ),
        pw.Expanded(
          child: pw.Text(value,
              textAlign: pw.TextAlign.right,
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
      ]),
    );

pw.Document _buildReceiptPdf(Payment payment, Student? student) {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pdfHeader('Official Payment Receipt',
              'Payment received and recorded in the school fee register.'),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(children: [
              pw.Expanded(
                child: pw.Text(_documentMoney.format(payment.amount),
                    style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800)),
              ),
              pw.Text(
                  payment.status.isEmpty
                      ? 'PAID'
                      : payment.status.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800)),
            ]),
          ),
          pw.SizedBox(height: 14),
          _pdfReceiptLine('Receipt number', payment.receiptNo),
          _pdfReceiptLine('Student', student?.name ?? payment.studentName),
          _pdfReceiptLine('Admission number', student?.admissionNo ?? '—'),
          _pdfReceiptLine('Payment method', payment.method),
          _pdfReceiptLine(
              'Date received',
              DateFormat('d MMM yyyy, h:mm a')
                  .format(payment.paidAt.toLocal())),
        ],
      ),
    ),
  );
  return doc;
}
