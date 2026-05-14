import 'package:flutter/material.dart';
import 'package:project/screen/card_scanner/screen/card_scanner_screen.dart';
import 'package:project/screen/home/screen/home_screen.dart';
import 'package:project/screen/passbook_scanner/screen/passbook_scanner_screen.dart';
import 'package:project/utils/app_colors.dart';
import 'package:project/utils/app_strings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appTitle,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => HomeScreen(),
        '/card-scanner': (BuildContext context) => const CardScannerScreen(),
        '/passbook-scanner': (BuildContext context) => const PassbookScannerScreen(),
      },
    );
  }
}
