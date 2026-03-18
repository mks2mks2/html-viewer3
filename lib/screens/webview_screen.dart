import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/url_service.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _loadingProgress = 0;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() {
            _isLoading = true;
            _hasError = false;
            _currentUrl = url;
          }),
          onProgress: (progress) =>
              setState(() => _loadingProgress = progress / 100),
          onPageFinished: (url) => setState(() {
            _isLoading = false;
            _currentUrl = url;
          }),
          onWebResourceError: (error) => setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Erro ao carregar a página.\n${error.description}';
          }),
          onNavigationRequest: (_) => NavigationDecision.navigate,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  String get _displayUrl {
    try {
      final uri = Uri.parse(_currentUrl);
      return uri.host.isNotEmpty ? uri.host : _currentUrl;
    } catch (_) {
      return _currentUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          if (_hasError) _buildErrorView() else WebViewWidget(controller: _controller),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isLocal = UrlService.isLocal(_currentUrl);
    return AppBar(
      backgroundColor: AppTheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () async {
          if (await _controller.canGoBack()) {
            _controller.goBack();
          } else {
            if (mounted) Navigator.pop(context);
          }
        },
      ),
      title: Row(
        children: [
          Icon(
            isLocal ? Icons.router_rounded : Icons.lock_rounded,
            color: isLocal ? AppTheme.accentSecondary : AppTheme.accent,
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _displayUrl,
              style: GoogleFonts.spaceMono(
                color: AppTheme.textPrimary, fontSize: 12, letterSpacing: 0.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: () => _controller.reload(),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          color: AppTheme.card,
          onSelected: (value) async {
            switch (value) {
              case 'forward':
                if (await _controller.canGoForward()) _controller.goForward();
                break;
              case 'home':
