import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dalahoo_app/widgets/header_background.dart';
import 'package:dalahoo_app/features/permissions/permission_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color backgroundColor = Color(0xFFF2F3FA);
  static const Color primaryBlue = Color(0xFF0099F1);

  bool batteryEnabled = false;
  bool autoStartEnabled = false;
  int selectedSim = 1; // 1 = sim1, 2 = sim2

  Future<void> loadSim() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      selectedSim = prefs.getInt('selectedSim') ?? 1;
    });
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await loadStatus();
      await loadSim();
    });
  }

  Future<void> loadStatus() async {
    final results = await Future.wait([
      PermissionService.isBatteryOptimized(),
      PermissionService.isAutoStartEnabled(),
    ]);

    if (!mounted) return;

    setState(() {
      batteryEnabled = results[0];
      autoStartEnabled = results[1];
    });
  }

  Future<void> _openBatterySettings() async {
    await PermissionService.openBatterySettings();

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) loadStatus();
  }

  Future<void> _openAutoStartSettings() async {
    await PermissionService.openAutoStartSettings();

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text("مجوزها"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: Stack(
        children: [
          const HeaderBackground(height: 130),

          Column(
            children: [
              const SizedBox(height: 130),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                      Text(
                        batteryEnabled
                            ? "❌ بهینه‌سازی باتری فعال است، آن را غیرفعال کنید."
                            : "✅ بهینه‌سازی باتری غیرفعال است.",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        textDirection: TextDirection.rtl,
                      ),

                      const SizedBox(height: 15),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _openBatterySettings,
                        child: Text(
                          batteryEnabled
                              ? "غیرفعال کردن بهینه‌سازی باتری"
                              : "فعال کردن بهینه‌سازی باتری",
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        autoStartEnabled
                            ? "✅ اجرای خودکار برنامه فعال است."
                            : "❌ اجرای خودکار برنامه غیرفعال است، آن را فعال کنید.",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        textDirection: TextDirection.rtl,
                      ),

                      const SizedBox(height: 15),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _openAutoStartSettings,
                        child: Text(
                          autoStartEnabled
                              ? "غیرفعال کردن اجرای خودکار برنامه"
                              : "فعال کردن اجرای خودکار برنامه",
                        ),
                      ),

                      const SizedBox(height: 20),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "📶 دریافت پیامک مبدا از هر دو سیم‌کارت امکان‌پذیر است. سیم‌کارت ارسال‌کننده پیامک را از لیست زیر انتخاب کنید.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.justify,
                          ),

                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: DropdownButton<int>(
                              value: selectedSim,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              underline: const SizedBox(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 1,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text("سیمکارت اول - Sim 1"),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text("سیمکارت دوم - Sim 2"),
                                  ),
                                ),
                              ],
                              onChanged: (value) async {
                                if (value == null) return;

                                setState(() {
                                  selectedSim = value;
                                });

                                // ذخیره در SharedPreferences (Flutter)
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setInt('selectedSim', value);

                                // ذخیره در Native هم (برای SmsReceiver)
                                await PermissionService.setSelectedSim(value);

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      value == 1
                                          ? "سیمکارت اول انتخاب شد"
                                          : "سیمکارت دوم انتخاب شد",
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
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
