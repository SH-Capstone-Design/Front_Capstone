import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';

class CoupleManageScreen extends StatelessWidget {
  const CoupleManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SizedBox(
              height: size.height * 0.15,
              child: Image.asset(
                AppConstants.logoPath,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

