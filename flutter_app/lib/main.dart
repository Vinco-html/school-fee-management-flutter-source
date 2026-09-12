import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_client.dart';
import 'models.dart';
import 'screens.dart';
import 'store.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // add this line first
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(SchoolFeeApp(api: ApiClient()));
  });
}

class SchoolFeeApp extends StatefulWidget {
  const SchoolFeeApp({super.key, required this.api});
  final ApiClient api;

  @override
  State<SchoolFeeApp> createState() => _SchoolFeeAppState();
}

class _SchoolFeeAppState extends State<SchoolFeeApp> {
  SchoolStore? store;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Petunia',
        theme: AppTheme.light(),
        home: store == null
            ? AuthScreen(
                api: widget.api,
                onAuthenticated: (user) {
                  widget.api.setToken(user.$1);
                  final nextStore = SchoolStore(widget.api);
                  nextStore.setAuthenticatedRole(user.$2.role == 'admin'
                      ? UserRole.admin
                      : UserRole.accountant);
                  setState(() {
                    store = nextStore;
                  });
                  nextStore.load();
                })
            : AppShell(store: store!),
      );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen(
      {super.key, required this.api, required this.onAuthenticated});
  final ApiClient api;
  final void Function((String, AuthUser)) onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool signup = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (signup) {
        await widget.api.signup(
            name: _name.text, email: _email.text, password: _password.text);
        if (mounted) setState(() => signup = false);
      } else {
        final response = await widget.api
            .login(email: _email.text, password: _password.text);
        final user =
            AuthUser.fromJson(response['user'] as Map<String, dynamic>);
        widget.onAuthenticated((response['token'].toString(), user));
      }
    } catch (err) {
      if (mounted) setState(() => error = err.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.school_outlined,
                          size: 52, color: AppTheme.peach),
                      const SizedBox(height: 12),
                      Text(signup ? 'Create accountant account' : 'Sign in',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppTheme.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 20),
                      if (signup)
                        TextField(
                          controller: _name,
                          decoration:
                              const InputDecoration(labelText: 'Full name'),
                        ),
                      if (signup) const SizedBox(height: 12),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(error!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: busy ? null : _submit,
                        child: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(signup ? 'Create account' : 'Sign in'),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                  signup = !signup;
                                  error = null;
                                }),
                        child: Text(signup
                            ? 'Already have an account? Sign in'
                            : 'Create accountant account'),
                      ),
                      if (signup)
                        const Text(
                            'Admin accounts are created and controlled by the school. Public signup is accountant-only.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: AppTheme.muted, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
