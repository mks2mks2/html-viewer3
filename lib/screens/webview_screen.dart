import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/connectivity_service.dart';
import '../services/local_server.dart';
import '../screens/password_screen.dart';

class WebViewScreen extends StatefulWidget {
  final String localPath;
  const WebViewScreen({super.key, required this.localPath});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _loadingProgress = 0;
  bool _serverReady = false;

  StreamSubscription<bool>? _connectivitySub;
  bool _showingPasswordScreen = false;
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startServerAndLoad();
    _startConnectivityMonitor();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App foi para segundo plano
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      // App voltou do segundo plano
      _wasInBackground = false;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_showingPasswordScreen) {
          _showPasswordOverlay();
        }
      });
    }
  }

  Future<void> _startServerAndLoad() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _serverReady = false;
    });

    try {
      final contentDir = File(widget.localPath).parent.path;
      final baseUrl = await LocalServer.start(contentDir);
      final fileName = widget.localPath.split('/').last;
      final url = '$baseUrl$fileName';

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setMediaPlaybackRequiresUserGesture(false)
        ..enableZoom(false)
        ..setBackgroundColor(AppTheme.background)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) => setState(() {
              _isLoading = true;
              _hasError = false;
            }),
            onProgress: (p) => setState(() => _loadingProgress = p / 100),
            onPageFinished: (_) => setState(() => _isLoading = false),
            onWebResourceError: (error) {
              if (error.isForMainFrame ?? true) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage =
                      'Erro ao carregar.\n${error.description}';
                });
              }
            },
            onNavigationRequest: (_) => NavigationDecision.navigate,
          ),
        )
        ..loadRequest(Uri.parse(url));

      if (mounted) setState(() => _serverReady = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Erro ao iniciar servidor local.\n$e';
        });
      }
    }
  }

  void _startConnectivityMonitor() {
    final stream = ConnectivityService.startMonitoring();
    _connectivitySub = stream.listen((connected) {
      if (connected && !_showingPasswordScreen && mounted && !_wasInBackground) {
        _showPasswordOverlay();
      }
    });
  }

  void _showPasswordOverlay() {
    if (_showingPasswordScreen || !mounted) return;
    setState(() => _showingPasswordScreen = true);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PasswordScreen(
          internetReconnected: true,
          onSuccess: (passwordContext) {
            Navigator.pop(passwordContext);
            if (mounted) setState(() => _showingPasswordScreen = false);
          },
        ),
      ),
    ).then((_) {
      if (mounted && _showingPasswordScreen) {
        Future.delayed(
            const Duration(milliseconds: 100), _showPasswordOverlay);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    ConnectivityService.stopMonitoring();
    LocalServer.stop();
    super.dispose();
  }

  void _goToSync() {
    ConnectivityService.stopMonitoring();
    LocalServer.stop();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () async {
            if (_serverReady && await _controller.canGoBack()) {
              _controller.goBack();
            }
          },
        ),
        title: Row(
          children: [
            const Icon(Icons.folder_rounded,
                color: AppTheme.accentSecondary, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.localPath.split('/').last,
                style: GoogleFonts.spaceMono(
                    color: AppTheme.textPrimary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => _startServerAndLoad(),
            tooltip: 'Recarregar',
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded, size: 20),
            onPressed: _goToSync,
            tooltip: 'Verificar atualizações',
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: AppTheme.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                ),
              )
            : null,
      ),
      body: _hasError
          ? _buildError()
          : _serverReady
              ? WebViewWidget(controller: _controller)
              : const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.broken_image_rounded,
                  color: AppTheme.error, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Não foi possível carregar',
              style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _startServerAndLoad(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Tentar novamente',
                  style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
