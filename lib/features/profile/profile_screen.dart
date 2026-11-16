import 'package:flutter/material.dart';
import 'package:dalahoo_app/widgets/header_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color backgroundColor = Color(0xFFF2F3FA);
  static const Color primaryBlue = Color(0xFF0099F1);

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    usernameFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    );
  }

  InputDecoration inputDecoration({required String hintText}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade100,

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),

      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black26,
      ),
      counterText: "",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text("ورود به حساب کاربری"),
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
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "نام کاربری",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                TextField(
                                  controller: usernameController,
                                  focusNode: usernameFocusNode,
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                  decoration: inputDecoration(
                                    hintText: "نام کاربری",
                                  ),
                                ),

                                const SizedBox(height: 20),

                                const Text(
                                  "رمز عبور",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                TextField(
                                  controller: passwordController,
                                  focusNode: passwordFocusNode,
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.left,
                                  obscureText: true,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                  decoration: inputDecoration(
                                    hintText: "رمز عبور",
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
                                    ),
                                    onPressed: () {
                                      // فعلا فقط ظاهر صفحه است.
                                    },
                                    child: const Text("ورود"),
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
                          child: const Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              children: [
                                Text(
                                  "پروفایل",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 12),

                                Text(
                                  "امکانات پروفایل در بروزرسانی‌های آینده به این بخش اضافه خواهد شد.",
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
