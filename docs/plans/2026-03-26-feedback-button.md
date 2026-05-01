# Feedback Button Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a "Send Feedback" entry to the Settings screen that opens the native mail app with a pre-filled feedback email.

**Architecture:** Single ListTile added to the existing About section in `settings_screen.dart`. Uses `url_launcher` (already a dependency) to launch a `mailto:` URI. No new packages, no new screens, no new providers.

**Tech Stack:** Flutter, `url_launcher` (already imported in settings_screen.dart)

---

### Task 1: Add the feedback ListTile to Settings

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart` — About section (~line 453)

**Step 1: Insert the ListTile**

Add this ListTile immediately after the `_buildSectionHeader(isZh ? '关于' : 'About')` line and before the Privacy Policy tile:

```dart
ListTile(
  leading: const Icon(Icons.feedback_outlined),
  title: Text(isZh ? '发送反馈' : 'Send Feedback'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => _sendFeedback(context, isZh),
),
```

**Step 2: Add the `_sendFeedback` method**

Add this private method to the `_SettingsScreenState` class (alongside the other private methods like `_exportData`):

```dart
Future<void> _sendFeedback(BuildContext context, bool isZh) async {
  const email = 'blinkingfeedback@gmail.com';
  const version = '1.1.0-beta.2';
  final subject = Uri.encodeComponent('Blinking App Feedback - v$version');
  final body = Uri.encodeComponent(
    'What happened:\n\n\nSteps to reproduce:\n\n\nExpected behavior:\n\n\nDevice & OS:\n\n',
  );
  final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isZh
              ? '无法打开邮件应用，请发送邮件至 $email'
              : 'No mail app found. Please email $email',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
```

**Step 3: Run the app and verify**

```bash
flutter run -d <android-device-or-emulator-id>
```

- Navigate to Settings → About section
- "Send Feedback" tile appears with feedback icon
- Tap it → native mail app opens with To/Subject/Body pre-filled
- Test with no mail app configured → snackbar appears with email address

**Step 4: Run analyzer**

```bash
flutter analyze --no-pub
```

Expected: 0 errors.

**Step 5: Commit**

```bash
git add lib/screens/settings/settings_screen.dart
git commit -m "feat(settings): add Send Feedback email button"
```
