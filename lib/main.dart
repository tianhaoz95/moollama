import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF232629),
      ),
      home: const GeminiHome(),
    );
  }
}

class GeminiHome extends StatelessWidget {
  const GeminiHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  // Hamburger menu
                  Icon(Icons.menu, color: Colors.white70),
                  const SizedBox(width: 16),
                  // App name
                  Text(
                    'Secret Agent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Spacer(),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Hello!',
                  style: TextStyle(
                    color: Colors.blue[400],
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Bottom bar
            Padding(
              padding: const EdgeInsets.only(
                bottom: 16.0,
                left: 12.0,
                right: 12.0,
                top: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      minLines: 2,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Ask Secret Agent',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 0,
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [_BottomBarButton(icon: Icons.send)],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  const _BottomBarButton({this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(18),
          ),
          child: label != null
              ? Text(
                  label!,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                )
              : Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
