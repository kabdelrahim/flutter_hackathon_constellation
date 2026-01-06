import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class ConstellationApp extends StatelessWidget {
  const ConstellationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Constellation',
      theme: appTheme,
      initialRoute: '/',
      routes: appRoutes,
      debugShowCheckedModeBanner: false,
    );
  }
}
