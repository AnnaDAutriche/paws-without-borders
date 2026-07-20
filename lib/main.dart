import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:paws_without_borders/theme.dart';
import 'package:paws_without_borders/nav.dart';
import 'package:paws_without_borders/providers/language_provider.dart';
import 'package:paws_without_borders/firebase_options.dart';
import 'package:paws_without_borders/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) => MaterialApp.router(
          title: 'Paws New Home',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: AppRouter.createRouter(auth),
        ),
      ),
    );
  }
}
