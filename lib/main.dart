import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hurrey_app/Auth/SignUpScreen.dart';
import 'package:hurrey_app/Auth/login_screen.dart'; // Hubi in AuthWrapper uu faylkan ku dhex jiro ama soo dhoweyso meeshii aad ku qortay
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hurey App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      // Halkii ay ahaan lahayd LoginScreenModern(), waxaan u bedelnay AuthWrapper()
      // Kani wuxuu hubinayaa haddii qofku horey u login ahaa in toos loogu gudbiyo Dashboard-ka
      home: const AuthWrapper(),
    );
  }
}
