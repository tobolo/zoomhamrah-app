
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const ZoomHamrahApp());
}

class ZoomHamrahApp extends StatelessWidget {
  const ZoomHamrahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'زوم همراه',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1677FF),
        ),
        useMaterial3: true,
      ),
      home: const StorePage(),
    );
  }
}

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  late final WebViewController controller;
  bool loading = true;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() => loading = true);
          },
          onPageFinished: (_) {
            setState(() => loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://zoomhamrah.ir'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: controller),
            if (loading)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1677FF),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

