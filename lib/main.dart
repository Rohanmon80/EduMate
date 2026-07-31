import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(

    options:
    DefaultFirebaseOptions
        .currentPlatform,
  );
  await Supabase.initialize(
    url: 'https://entxhlyjvgjhwmuvmtkf.supabase.co',
    anonKey: 'sb_publishable__rUfzg9o2V1eTZJJa1C9yA_DemVEaK6',
  );

  runApp(
    const EduMateApp(),
  );
}

class EduMateApp extends StatefulWidget {
  const EduMateApp({super.key});

  static _EduMateAppState? of(
      BuildContext context) {

    return context.findAncestorStateOfType<
        _EduMateAppState>();
  }

  @override
  State<EduMateApp> createState() =>
      _EduMateAppState();
}

class _EduMateAppState
    extends State<EduMateApp> {

  ThemeMode themeMode =
      ThemeMode.light;

  void toggleTheme() {

    setState(() {

      themeMode =
      themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(
      BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner:
      false,

      title: 'EduMate',

      themeMode:
      themeMode,

      theme:

      ThemeData(

        brightness:
        Brightness.light,

        fontFamily:
        'Poppins',

        useMaterial3:
        true,
      ),

      darkTheme:

      ThemeData(

        brightness:
        Brightness.dark,

        fontFamily:
        'Poppins',

        useMaterial3:
        true,
      ),

      home:
      const SplashScreen(),
    );
  }
}