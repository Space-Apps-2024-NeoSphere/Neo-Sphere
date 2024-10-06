// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sustainable_scholars/core/sign_in_provider.dart';
import 'package:sustainable_scholars/ui/signed.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:media_kit/media_kit.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  String apiKey = dotenv.env["GEMINI_API_KEY"]!;

  MediaKit.ensureInitialized();

  runApp(ChangeNotifierProvider(
    create: (context) => SignInProvider(),
    child: MyApp(
      apiKey: apiKey,
    ),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.apiKey});
  final String apiKey;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sustainable Scholars',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: 'Sustainable Scholars',
        apiKey: apiKey,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.apiKey});
  final String apiKey;

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SignedInView(
        apiKey: widget.apiKey,
      ),
    );
  }
}
