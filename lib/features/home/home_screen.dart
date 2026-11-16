import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dalahoo_app/widgets/header_background.dart';
import 'package:dalahoo_app/features/settings/settings_screen.dart';
import 'package:dalahoo_app/features/profile/profile_screen.dart';
import 'package:dalahoo_app/features/update/update_screen.dart';
import 'package:dalahoo_app/features/services/update_service.dart';
import 'package:dalahoo_app/features/history/history_screen.dart';
import 'package:dalahoo_app/features/config/remote_config_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const Color backgroundColor = Color(0xFFF2F3FA);
  bool hasUpdate = false;
  late AnimationController controller;
  late Animation<double> card1;
  late Animation<double> card2;
  late Animation<double> card3;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();

  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode nationalIdFocusNode = FocusNode();

  String _senderText = RemoteConfigService.defaultSenders.join(' · ');

  bool isEditingPhone = false;
  bool isPhoneSaved = false;

  bool isEditingNationalId = false;
  bool isNationalIdSaved = false;

  @override
  void initState() {
    super.initState();

    loadSenderNumbers();

    controller = AnimationController(
      vsync: this,
      // انیمیشن کوتاه‌تر برای گوشی‌های ضعیف
      duration: const Duration(milliseconds: 450),
    );

    card1 = Tween(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    card2 = Tween(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
      ),
    );

    card3 = Tween(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    checkForUpdate();
    loadPhoneNumber();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.forward();
      }
    });
  }

  Future<void> checkForUpdate() async {
    final updateInfo = await UpdateService.checkForUpdate();

    if (!mounted) return;

    if (updateInfo != null) {
      setState(() {
        hasUpdate = true;
      });
    } else {
      setState(() {
        hasUpdate = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    phoneFocusNode.dispose();
    nationalIdFocusNode.dispose();
    phoneController.dispose();
    nationalIdController.dispose();
    super.dispose();
  }

  Widget animatedCard(Animation<double> animation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, animation.value),
          child: child,
        );
      },
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    );
  }

  Future<void> loadSenderNumbers() async {
    final senders = await RemoteConfigService.loadSenders();
    if (!mounted) return;
    setState(() {
      _senderText = senders.join(' · ');
    });
  }

  Future<void> loadPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();

    // Prefer new key, fallback to old for compatibility
    final savedName = prefs.getString('driver_name') ??
        prefs.getString('user_phone_number');
    final savedNationalId = prefs.getString('driver_national_id');

    if (!mounted) return;

    setState(() {
      if (savedName != null && savedName.isNotEmpty) {
        phoneController.text = savedName;
        isPhoneSaved = true;
      }

      if (savedNationalId != null && savedNationalId.isNotEmpty) {
        nationalIdController.text = savedNationalId;
        isNationalIdSaved = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text("هدایت‌کننده پیامک دالاهو"),
        centerTitle: true,
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
                        animatedCard(
                          card1,
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: cardDecoration(),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "شماره‌های مقصد توسط سیستم تعیین شده‌اند",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),

                                  const Text(
                                    "شماره‌های فرستنده:",
                                    style: TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _senderText,
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(fontSize: 15),
                                  ),

                                  const SizedBox(height: 12),

                                  const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("مقصد اول"),
                                      Text(
                                        "5000200050",
                                        textDirection: TextDirection.ltr,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("مقصد دوم"),
                                      Text(
                                        "09172466295",
                                        textDirection: TextDirection.ltr,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),

                                  

                                  ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        animatedCard(
                          card2,
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: cardDecoration(),
                            child: Column(
                              children: [
                                const Text("نام و نام خانوادگی راننده"),

                                const SizedBox(height: 12),

                                TextField(
                                  controller: phoneController,
                                  focusNode: phoneFocusNode,
                                  enabled: isEditingPhone,
                                  keyboardType: TextInputType.name,
                                  textCapitalization: TextCapitalization.words,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0099F1),
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey.shade100,

                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),

                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF0099F1),
                                        width: 2,
                                      ),
                                    ),

                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),

                                    hintText: "مثال: علی رضایی",
                                  ),
                                ),

                                const SizedBox(height: 12),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0099F1),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      if (!isEditingPhone) {
                                        setState(() {
                                          isEditingPhone = true;
                                        });

                                        Future.delayed(
                                          const Duration(milliseconds: 100),
                                          () {
                                            phoneFocusNode.requestFocus();
                                          },
                                        );

                                        return;
                                      }

                                      final name = phoneController.text.trim();


                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );

                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setString(
                                        "driver_name",
                                        name,
                                      );

                                      if (!mounted) return;

                                      setState(() {
                                        isEditingPhone = false;
                                        isPhoneSaved = true;
                                      });

                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text("نام راننده ذخیره شد"),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      isPhoneSaved
                                          ? "ویرایش نام راننده"
                                          : "ثبت نام راننده",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // کدملی راننده
                        animatedCard(
                          card2,
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: cardDecoration(),
                            child: Column(
                              children: [
                                const Text("کدملی راننده"),

                                const SizedBox(height: 12),

                                TextField(
                                  controller: nationalIdController,
                                  focusNode: nationalIdFocusNode,
                                  enabled: isEditingNationalId,
                                  keyboardType: TextInputType.number,
                                  maxLength: 10,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0099F1),
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF0099F1),
                                        width: 2,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    counterText: "",
                                    hintText: "کدملی ۱۰ رقمی",
                                  ),
                                ),

                                const SizedBox(height: 12),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0099F1),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      if (!isEditingNationalId) {
                                        setState(() {
                                          isEditingNationalId = true;
                                        });

                                        Future.delayed(
                                          const Duration(milliseconds: 100),
                                          () {
                                            nationalIdFocusNode.requestFocus();
                                          },
                                        );

                                        return;
                                      }

                                      final nationalId =
                                          nationalIdController.text.trim();


                                      final messenger =
                                          ScaffoldMessenger.of(context);

                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setString(
                                        "driver_national_id",
                                        nationalId,
                                      );

                                      if (!mounted) return;

                                      setState(() {
                                        isEditingNationalId = false;
                                        isNationalIdSaved = true;
                                      });

                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text("کدملی ذخیره شد"),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      isNationalIdSaved
                                          ? "ویرایش کدملی"
                                          : "ثبت کدملی",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        animatedCard(
                          card3,
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: cardDecoration(),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF0099F1),
                                      side: const BorderSide(
                                        color: Color(0xFF0099F1),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        _softTransition(const HistoryScreen()),
                                      );
                                    },
                                    icon: const Icon(Icons.history_rounded),
                                    label: const Text("تاریخچه فوروارد"),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "برای عملکرد صحیح برنامه «تنظیمات دسترسی» ضروری است",
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0099F1),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        _softTransition(const SettingsScreen()),
                                      );
                                    },
                                    child: const Text("تنظیمات دسترسی"),
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavButton(
                icon: Icons.login_rounded,
                iconColor: Colors.black,
                onTap: () {
                  Navigator.of(context).push(
                    _softTransition(const ProfileScreen()),
                  );
                },
              ),

              _NavButton(
                icon: Icons.history_rounded,
                iconColor: Colors.black,
                onTap: () {
                  Navigator.of(context).push(
                    _softTransition(const HistoryScreen()),
                  );
                },
              ),

              _NavButton(
                icon: Icons.home_rounded,
                iconColor: const Color(0xFF0099F1),
                onTap: () {
                  controller.reset();
                  controller.forward();
                },
              ),

              Stack(
                clipBehavior: Clip.none,
                children: [
                  _NavButton(
                    icon: Icons.download_rounded,
                    iconColor: hasUpdate ? Colors.red : Colors.black,
                    onTap: () {
                      Navigator.of(context).push(
                        _softTransition(const UpdateScreen()),
                      );
                    },
                  ),

                  if (hasUpdate)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _NavButton({required this.icon, required this.onTap, this.iconColor});

  static const Color backgroundColor = Color(0xFFF2F3FA);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: Icon(icon, size: 24, color: iconColor ?? Colors.black),
      ),
    );
  }
}

PageRouteBuilder _softTransition(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, animation, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final slide = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

      final fade = Tween(begin: 0.0, end: 1.0).animate(animation);

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
