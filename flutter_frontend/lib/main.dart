import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ApotekPOSApp());
}

class ApotekPOSApp extends StatelessWidget {
  const ApotekPOSApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apotek POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1FA397),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1FA397),
          primary: const Color(0xFF1FA397),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1FA397),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}