import 'package:flutter/material.dart';

void main() {
  runApp(const CanvasChatApp());
}

class CanvasChatApp extends StatelessWidget {
  const CanvasChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canvas Chat',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const Scaffold(
        body: Center(
          // M1 ships the import + data layer only; the conversation list and
          // import UI arrive in M2.
          child: Text('Canvas Chat — UI coming in M2'),
        ),
      ),
    );
  }
}
