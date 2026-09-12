class Student {
  const Student({
    required this.id,
    required this.admissionNo,
    required this.name,
    required this.grade,
    required this.guardian,
    required this.guardianPhone,
    required this.balance,
    required this.status,
    this.avatarUrl,
  });

  final int id;
  final String admissionNo;
  final String name;
  final String grade;
  final String guardian;
  final String guardianPhone;
  final int balance;
  final String status;
  final String? avatarUrl;

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: _toInt(json['id']),
        admissionNo: json['admissionNo']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        grade: json['grade']?.toString() ?? '',
        guardian: json['guardian']?.toString() ?? '',
        guardianPhone: json['guardianPhone']?.toString() ?? '',
        balance: _toInt(json['balance']),
        status: json['status']?.toString() ?? 'Active',
        avatarUrl: json['avatarUrl']?.toString(),
      );
}

class SchoolClass {
  const SchoolClass(
      {required this.id,
      required this.feePaid,
      required this.name,
      required this.stream,
      required this.studentsCount,
      required this.teacher,
      required this.feeTarget,
      required this.term,
      required this.feeBalance});

  final int id;
  final int feePaid;
  final String name;
  final String stream;
  final int studentsCount;
  final String teacher;
  final int feeTarget;
  final String term;
  final int feeBalance;

  factory SchoolClass.fromJson(Map<String, dynamic> json) => SchoolClass(
        id: _toInt(json['id']),
        name: json['name']?.toString() ?? '',
        stream: json['stream']?.toString() ?? '',
        studentsCount: _toInt(json['studentsCount']),
        teacher: json['teacher']?.toString() ?? '',
        feeTarget: _toInt(json['feeTarget']),
        feePaid: _toInt(json['feePaid']),
        term: json['term']?.toString() ?? 'Term 1',
        feeBalance: _toInt(json['feeBalance']),
      );
}

class Payment {
  const Payment({
    required this.id,
    required this.receiptNo,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.method,
    required this.status,
    required this.channel,
    required this.paidAt,
  });

  final int id;
  final String receiptNo;
  final int studentId;
  final String studentName;
  final int amount;
  final String method;
  final String status;
  final String channel;
  final DateTime paidAt;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: _toInt(json['id']),
        receiptNo: json['receiptNo']?.toString() ?? '',
        studentId: _toInt(json['studentId']),
        studentName: json['studentName']?.toString() ?? '',
        amount: _toInt(json['amount']),
        method: json['method']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        channel: json['channel']?.toString() ?? '',
        paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class PendingPayment {
  const PendingPayment({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.accountReference,
    required this.payerName,
    required this.candidateIds,
    required this.createdAt,
  });

  final int id;
  final String transactionId;
  final int amount;
  final String accountReference;
  final String payerName;
  final List<int> candidateIds;
  final DateTime createdAt;

  factory PendingPayment.fromJson(Map<String, dynamic> json) => PendingPayment(
        id: _toInt(json['id']),
        transactionId: json['transactionId']?.toString() ?? '',
        amount: _toInt(json['amount']),
        accountReference: json['accountReference']?.toString() ?? '',
        payerName: json['payerName']?.toString() ?? '',
        candidateIds:
            (json['candidateIds'] as List<dynamic>? ?? []).map(_toInt).toList(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class Activity {
  const Activity({
    required this.id,
    required this.actor,
    required this.role,
    required this.action,
    required this.detail,
    required this.createdAt,
  });

  final int id;
  final String actor;
  final String role;
  final String action;
  final String detail;
  final DateTime createdAt;

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: _toInt(json['id']),
        actor: json['actor']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
        action: json['action']?.toString() ?? '',
        detail: json['detail']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class SchoolNotification {
  const SchoolNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime createdAt;

  factory SchoolNotification.fromJson(Map<String, dynamic> json) =>
      SchoolNotification(
        id: _toInt(json['id']),
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        type: json['type']?.toString() ?? 'activity',
        read: json['read'] == true,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class Campaign {
  const Campaign({
    required this.id,
    required this.campaign,
    required this.channel,
    required this.audience,
    required this.status,
    required this.recipientCount,
    this.sentAt,
  });

  final int id;
  final String campaign;
  final String channel;
  final String audience;
  final String status;
  final int recipientCount;
  final DateTime? sentAt;

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        id: _toInt(json['id']),
        campaign: json['campaign']?.toString() ?? '',
        channel: json['channel']?.toString() ?? '',
        audience: json['audience']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        recipientCount: _toInt(json['recipientCount']),
        sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? ''),
      );
}

class DashboardSummary {
  const DashboardSummary({
    required this.students,
    required this.outstanding,
    required this.collected,
    required this.paymentCount,
    required this.unreadNotifications,
    required this.term,
    required this.recentActivity,
  });

  final int students;
  final int outstanding;
  final int collected;
  final int paymentCount;
  final int unreadNotifications;
  final String term;
  final List<Activity> recentActivity;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        students: _toInt(json['students']),
        outstanding: _toInt(json['outstanding']),
        collected: _toInt(json['collected']),
        paymentCount: _toInt(json['paymentCount']),
        unreadNotifications: _toInt(json['unreadNotifications']),
        term: json['term']?.toString() ?? '',
        recentActivity: (json['recentActivity'] as List<dynamic>? ?? [])
            .map((item) => Activity.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

int _toInt(dynamic value) =>
    value is num ? value.round() : int.tryParse('$value') ?? 0;
