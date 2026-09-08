import 'package:flutter/material.dart';

import 'api_client.dart';
import 'screens.dart';
import 'store.dart';
import 'theme.dart';

void main() {
  runApp(SchoolFeeApp(api: ApiClient()));
}

class SchoolFeeApp extends StatefulWidget {
  const SchoolFeeApp({super.key, required this.api});
  final ApiClient api;

  @override
  State<SchoolFeeApp> createState() => _SchoolFeeAppState();
}

class _SchoolFeeAppState extends State<SchoolFeeApp> {
  late final SchoolStore store;

  @override
  void initState() {
    super.initState();
    store = SchoolStore(widget.api)..load();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'School Fee Management',
          theme: AppTheme.light(),
          home: AppShell(store: store),
        ),
      );
}