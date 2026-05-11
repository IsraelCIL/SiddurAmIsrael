import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SmartSiddurApp extends ConsumerWidget {
  const SmartSiddurApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MaterialApp(
      title: 'סידור חכם',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('סידור חכם')),
      ),
    );
  }
}
