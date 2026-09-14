import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'models.dart';

enum UserRole { admin, accountant }

/// How often we quietly retry reaching the API while it's unreachable.
const _retryInterval = Duration(seconds: 6);

class SchoolStore extends ChangeNotifier {
  SchoolStore(this.api);

  final ApiClient api;
  Timer? _retryTimer;

  UserRole role = UserRole.admin;
  UserRole? authenticatedRole;
  bool loading = true;
  // True once we've had at least one real (non-error) response from the API.
  bool hasLoadedOnce = false;
  String? error;
  DashboardSummary? summary;
  List<Student> students = [];
  List<SchoolClass> classes = [];
  List<Payment> payments = [];
  List<PendingPayment> pendingPayments = [];
  List<Activity> activities = [];
  List<SchoolNotification> notifications = [];
  List<Campaign> campaigns = [];
  List<CalendarEvent> events = [];

  bool get isAccountant => role == UserRole.accountant;
  bool get canPreviewRoles => authenticatedRole == UserRole.admin;
  int get unreadCount => notifications.where((item) => !item.read).length;
  // The UI should show skeleton placeholders instead of empty states
  // whenever we don't yet have real data to show.
  bool get isOffline => error != null;

  /// User-triggered load: shows the loading/skeleton state immediately.
  Future<void> load() async {
    _retryTimer?.cancel();
    loading = true;
    error = null;
    notifyListeners();
    await _fetch();
  }

  /// Shared fetch used by both the initial load and silent background
  /// retries. Silent retries don't flip `loading` back to true so the UI
  /// (already showing skeletons) doesn't flicker.
  Future<void> _fetch() async {
    try {
      final results = await Future.wait<dynamic>([
        api.dashboard(),
        api.students(),
        api.classes(),
        api.payments(),
        api.activity(),
        api.notifications(),
        api.messages(),
        api.events(),
      ]);
      summary = results[0] as DashboardSummary;
      students = results[1] as List<Student>;
      classes = results[2] as List<SchoolClass>;
      payments = results[3] as List<Payment>;
      activities = results[4] as List<Activity>;
      notifications = results[5] as List<SchoolNotification>;
      campaigns = results[6] as List<Campaign>;
      events = results[7] as List<CalendarEvent>;
      error = null;
      hasLoadedOnce = true;
    } catch (err) {
      error = err.toString();
      _scheduleRetry();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryInterval, _fetch);
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void setRole(UserRole next) {
    if (!canPreviewRoles && next != authenticatedRole) return;
    role = next;
    notifyListeners();
  }

  void setAuthenticatedRole(UserRole next) {
    authenticatedRole = next;
    role = next;
    notifyListeners();
  }

  Future<void> addStudent(Map<String, dynamic> body) async {
    await api.addStudent(body);
    await load();
  }

  Future<void> deleteStudent(int id) async {
    await api.deleteStudent(id);
    await load();
  }

  Future<void> addClass(Map<String, dynamic> body) async {
    await api.addClass(body);
    await load();
  }

  Future<void> deleteClass(int id) async {
    await api.deleteClass(id);
    await load();
  }

  Future<Payment> addPayment(Map<String, dynamic> body) async {
    final payment = await api.addManualPayment(body);
    await load();
    return payment;
  }

  Future<void> resolvePendingPayment(int pendingId, int studentId) async {
    await api.resolvePendingPayment(pendingId, studentId);
    await load();
  }

  Future<void> loadPendingPayments() async {
    pendingPayments = await api.pendingPayments();
    notifyListeners();
  }

  Future<void> syncEquity() async {
    await api.syncEquity();
    await load();
  }

  Future<void> markRead() async {
    await api.markNotificationsRead();
    await load();
  }

  Future<void> createCampaign(Map<String, dynamic> body) async {
    await api.createMessage(body);
    await load();
  }

  Future<void> addEvent(Map<String, dynamic> body) async {
    await api.addEvent(body);
    await loadEvents();
  }

  Future<void> deleteEvent(int id) async {
    await api.deleteEvent(id);
    await loadEvents();
  }

  Future<void> loadEvents() async {
    events = await api.events();
    notifyListeners();
  }
}
