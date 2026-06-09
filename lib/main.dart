import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'screens/setup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const EvoChatApp());
}

class EvoChatApp extends StatelessWidget {
  const EvoChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EvoChat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SetupScreen(),
    );
  }
}
