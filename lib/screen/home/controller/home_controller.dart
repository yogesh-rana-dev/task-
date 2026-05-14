import 'package:flutter/material.dart';

class HomeController {
  // Opens card scanner module from home screen.
  void openCardScanner(BuildContext context) {
    Navigator.pushNamed(context, '/card-scanner');
  }

  // Opens passbook scanner module from home screen.
  void openPassbookScanner(BuildContext context) {
    Navigator.pushNamed(context, '/passbook-scanner');
  }
}
