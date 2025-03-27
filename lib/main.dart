import 'package:routefly/routefly.dart';
import 'package:flutter/material.dart';

import 'main.route.dart'; // <- GENERATED

part 'main.g.dart'; // <- GENERATED

void main() {
  runApp(const App());
}

@Main()
class App extends StatelessWidget {
  const App({super.key});

  ThemeData createTheme(BuildContext context, Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ),
      brightness: brightness,
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
        title: 'Counter example',
        debugShowCheckedModeBanner: false,
        theme: createTheme(context, Brightness.light),
        darkTheme: createTheme(context, Brightness.dark),
        themeMode: ThemeMode.system,
        routerConfig: Routefly.routerConfig(
          routes: routes,
          initialPath: routePaths.lib.app,
          notFoundPath: '/notfound',
        ));
  }
}

