import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moollama/database_helper.dart';
import 'package:moollama/home_page.dart'; // Import the new home page
import 'package:feedback/feedback.dart';
import 'package:feature_flags/feature_flags.dart';
import 'package:talker_flutter/talker_flutter.dart'; // Import talker

final talker = TalkerFlutter.init(); // Global talker instance

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().init();

  final prefs = await SharedPreferences.getInstance();
  final themeModeString = prefs.getString('themeMode');
  if (themeModeString == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else if (themeModeString == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else {
    themeNotifier.value = ThemeMode.system;
  }
  runApp(
    const MyApp(),
  );

  themeNotifier.addListener(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'themeMode',
      themeNotifier.value.toString().split('.').last,
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return Features(
          flags: const [], // No features enabled by default
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: const Color(0xFF232629),
            ),
            themeMode: currentMode,
            home: BetterFeedback( // Move BetterFeedback here
              theme: FeedbackThemeData( // Pass theme data
                background: Theme.of(context).scaffoldBackgroundColor,
                drawColors: [
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                  Colors.yellow,
                  Theme.of(context).colorScheme.primary, // Use primary color from theme
                ],
                feedbackSheetColor: Theme.of(context).cardColor,
                // Add other theme properties as needed for consistency
              ),
              child: SecretAgentHome(themeNotifier: themeNotifier, talker: talker), // Pass themeNotifier and talker
            ),
          ),
        );
      },
    );
  }
}
