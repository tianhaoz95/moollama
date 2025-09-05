# Moollama - Your Personal AI Agent

Moollama is a Flutter-based personal AI agent application that allows you to interact with various AI models and tools.

## Features

*   **AI Chat:** Engage in conversations with different AI models.
*   **Customizable Agents:** Create and manage multiple AI agents with distinct personalities and model configurations.
*   **Model Management:** Select from available AI models and configure their creativity and context window size.
*   **Tool Integration:** Utilize various tools (e.g., web fetching, email sending, current time) to enhance AI capabilities.
*   **Attachment Support:** Attach files (e.g., photos from camera or gallery) to your conversations.
*   **Feedback Mechanism:** Provide feedback easily (debug mode only).
*   **First-time User Experience:** Prompts user to download AI model on first launch.
*   **Bring Your Own Model:** Option to integrate custom AI models.

## Getting Started

This project is a starting point for a Flutter application.

### Running the Application

To get the Moollama application up and running on your device or emulator, follow these steps:

1.  **Ensure Flutter is installed:** If you haven't already, install Flutter by following the official guide: [Flutter Installation Guide](https://flutter.dev/docs/get-started/install)
2.  **Clone the repository:**
    ```bash
    git clone https://github.com/tianhaoz95/moollama.git
    cd moollama
    ```
3.  **Get dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Run the application:**
    ```bash
    flutter run
    ```
    This command will launch the app on your connected device or emulator.

### Building the APK

To build a release APK for Android:

```bash
flutter build apk --release
```
The generated APK will be located in `build/app/outputs/flutter-apk/app-release.apk`.

### Running Unit Tests

To execute the unit tests for the project:

```bash
flutter test
```

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.