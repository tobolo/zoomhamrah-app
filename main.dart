import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const ZoomHamrahApp());

class ZoomHamrahApp extends StatelessWidget {
  const ZoomHamrahApp({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1677FF);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'زوم همراه',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        useMaterial3: true,
        fontFamily: 'Roboto',
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
  static const homeUrl = 'https://zoomhamrah.ir';

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => loading = true),
        onPageFinished: (_) => setState(() => loading = false),
        onWebResourceError: (_) => setState(() => loading = false),
      ))
      ..loadRequest(Uri.parse(homeUrl));
  }

  Future<bool> handleBack() async {
    if (await controller.canGoBack()) {
      await controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await controller.canGoBack()) {
          await controller.goBack();
        } else if (!didPop && mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1677FF),
          foregroundColor: Colors.white,
          title: const Text('زوم همراه'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'بارگذاری مجدد',
              onPressed: () => controller.reload(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: controller),
            if (loading)
              const LinearProgressIndicator(
                minHeight: 3,
                color: Color(0xFF1677FF),
              ),
          ],
        ),
      ),
    );
  }
}
