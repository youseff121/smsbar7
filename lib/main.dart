import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dalahoo_app/features/home/home_screen.dart';
import 'package:dalahoo_app/features/settings/settings_screen.dart';
import 'package:dalahoo_app/features/splash/splash_screen.dart';
import 'package:dalahoo_app/features/config/remote_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // بروزرسانی شماره‌ها در پس‌زمینه (بدون توقف اپ)
  RemoteConfigService.refresh();

  runApp(const DalahooApp());
}

class DalahooApp extends StatelessWidget {
  const DalahooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dalahoo SMS Forwarder',
      theme: ThemeData(
        fontFamily: 'Yekan',
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

      routes: {
        "/settings": (context) => const SettingsScreen(),
        "/home": (context) => const HomeScreen(),
      },

      home: const SplashScreen(),
    );
  }
}
