import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:dalahoo_app/features/services/update_service.dart';
import 'package:dalahoo_app/widgets/header_background.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen>
    with WidgetsBindingObserver {
  static const Color backgroundColor = Color(0xFFF2F3FA);
  static const Color primaryBlue = Color(0xFF0099F1);

  static const MethodChannel _channel = MethodChannel('sms_forwarder');

  UpdateInfo? _updateInfo;
  bool _isChecking = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _pendingApkPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingInstall();
    }
  }

  Future<void> _checkForUpdate() async {
    if (mounted) {
      setState(() {
        _isChecking = true;
      });
    }

    final updateInfo = await UpdateService.checkForUpdate();

    if (!mounted) return;

    setState(() {
      _updateInfo = updateInfo;
      _isChecking = false;
    });
  }

  Future<bool> _canInstallPackages() async {
    try {
      final result = await _channel.invokeMethod<bool>('canInstallPackages');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openInstallPermissionSettings() async {
    try {
      await _channel.invokeMethod('openInstallPermissionSettings');
    } catch (_) {}
  }

  Future<void> _installApk(String path) async {
    try {
      await _channel.invokeMethod('installApk', {'path': path});
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اجرای نصب APK با خطا مواجه شد.')),
      );
    }
  }

  Future<void> _checkPendingInstall() async {
    if (_pendingApkPath == null) {
      return;
    }

    final file = File(_pendingApkPath!);

    if (!await file.exists()) {
      _pendingApkPath = null;
      return;
    }

    final canInstall = await _canInstallPackages();

    if (!canInstall) {
      return;
    }

    final path = _pendingApkPath;
    _pendingApkPath = null;

    if (path != null) {
      await _installApk(path);
    }
  }

  Future<void> _downloadAndInstall() async {
    if (_updateInfo == null || _isDownloading) {
      return;
    }

    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      final directory = await getTemporaryDirectory();

      final filePath =
          '${directory.path}${Platform.pathSeparator}dalahoo_update.apk';

      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      final client = http.Client();

      try {
        final request = http.Request(
          'GET',
          Uri.parse(_updateInfo!.downloadUrl),
        );

        final response = await client.send(request);

        if (response.statusCode != 200) {
          throw Exception('Download failed: ${response.statusCode}');
        }

        final totalBytes = response.contentLength ?? 0;
        final sink = file.openWrite();

        int receivedBytes = 0;

        try {
          await for (final chunk in response.stream) {
            sink.add(chunk);
            receivedBytes += chunk.length;

            if (mounted && totalBytes > 0) {
              setState(() {
                _downloadProgress = receivedBytes / totalBytes;
              });
            }
          }

          await sink.flush();
          await sink.close();
        } catch (_) {
          await sink.close();

          if (await file.exists()) {
            await file.delete();
          }

          rethrow;
        }
      } finally {
        client.close();
      }

      _pendingApkPath = filePath;

      final canInstall = await _canInstallPackages();

      if (!canInstall) {
        await _openInstallPermissionSettings();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اجازه نصب برنامه را فعال کنید و به برنامه برگردید.'),
          ),
        );

        return;
      }

      final path = _pendingApkPath;
      _pendingApkPath = null;

      if (path != null) {
        await _installApk(path);
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('دانلود بروزرسانی با خطا مواجه شد.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("بروزرسانی"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          const HeaderBackground(height: 130),
          Column(
            children: [
              const SizedBox(height: 130),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: cardDecoration(),
                          child: const Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              children: [
                                Text(
                                  "بروزرسانی برنامه",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "برای بررسی و دریافت آخرین نسخه برنامه، روی دکمه زیر بزنید.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: cardDecoration(),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              children: [
                                const Text(
                                  "آخرین نسخه",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _isChecking
                                      ? "در حال بررسی نسخه جدید..."
                                      : _updateInfo != null
                                      ? "نسخه جدید ${_updateInfo!.latestVersion} آماده دریافت است."
                                      : "برنامه شما در حال حاضر به‌روز است.",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: Colors.grey.shade400,
                                      disabledForegroundColor: Colors.white,
                                    ),
                                    onPressed: _isChecking || _isDownloading
                                        ? null
                                        : _updateInfo != null
                                        ? _downloadAndInstall
                                        : null,
                                    child: _isDownloading
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                _downloadProgress > 0
                                                    ? "در حال دانلود ${(_downloadProgress * 100).toInt()}%"
                                                    : "در حال دانلود...",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            _isChecking
                                                ? "در حال بررسی..."
                                                : _updateInfo != null
                                                ? "بروزرسانی"
                                                : "بررسی بروزرسانی",
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 150),
              _NavButton(
                icon: Icons.home_rounded,
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil("/home", (route) => false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isHover ? const Color(0xFF0099F1) : const Color(0xFFF2F3FA),
          ),
          child: Icon(
            widget.icon,
            size: 24,
            color: isHover ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
