/// Legal document content embedded as Dart string constants.
/// Source documents: docs/Blinking_Notes_Privacy_Policy.md
///                   docs/Blinking_Notes_Terms_of_Service.md

const String kPrivacyPolicyContent = '''
Privacy Policy — Blinking (记忆闪烁)

Effective Date: March 21, 2026
App Name: Blinking (记忆闪烁)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. OVERVIEW

Blinking (记忆闪烁) is a personal memory and habit-tracking application designed to work entirely on your device. We are committed to protecting your privacy.

The short version: Blinking does not collect, transmit, or share any personal data. All your data stays on your device.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2. INFORMATION WE DO NOT COLLECT

We do not collect, store, or transmit:
• Your name, email address, phone number, or any identity information
• Location data
• Device identifiers or advertising IDs
• Usage analytics or crash reports
• Any content you create in the app (journal entries, habits, notes, or media)

There are no accounts, no sign-in, and no registration required.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3. DATA STORAGE — LOCAL ONLY

All data you create in Blinking is stored exclusively on your device:

• Journal entries, habits, and cards are stored in a local SQLite database on your device.
• Media files (photos attached to entries) are stored in the app's private document directory.
• App preferences (theme, language, settings) are stored in your device's local storage.

No data is uploaded to any server operated by us.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

4. INTERNET CONNECTIVITY

Blinking is designed to be fully functional without an internet connection. All core features — journaling, habit tracking, card creation, memory jars, and statistics — work entirely offline.

The app does not require internet access to function.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5. AI ASSISTANT FEATURE (OPTIONAL)

Blinking includes an optional AI Assistant. This feature is disabled by default and only becomes active if you choose to configure it.

To use the AI Assistant, you must provide your own API key from a supported third-party AI provider (such as OpenAI, Anthropic, Google, or OpenRouter).

Important disclosures:

• When you send a message to the AI Assistant, that message (and any journal entries you have chosen to include as context) is transmitted to the third-party AI provider using the API key you supplied.
• Your data is sent directly from your device to the AI provider's servers. Blinking does not act as an intermediary and does not see or store this data.
• The third-party AI provider may collect, process, and store the data you send according to their own privacy policies and terms of service. Please review the privacy policy of your chosen AI provider before using this feature.
• You are solely responsible for the API key you provide. Keep your API key confidential.
• You can disable the AI feature at any time by removing your API key in Settings.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

6. PERMISSIONS

Blinking may request the following device permissions:

Camera — To take photos and attach them to journal entries
Photo Library / Media Images — To select existing photos and attach them to entries

These permissions are requested only when you attempt to use the relevant feature. Blinking does not access your camera or photo library in the background.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

7. DATA EXPORT AND BACKUP

Blinking provides built-in tools to export your data (ZIP backup, JSON, CSV). These exports are generated locally on your device and shared using your device's native sharing mechanism. We do not receive copies of your exported data.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

8. CHILDREN'S PRIVACY

Blinking is not directed at children under the age of 13. We do not knowingly collect any information from children.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

9. CHANGES TO THIS POLICY

We may update this Privacy Policy from time to time. We will notify you of material changes by updating the effective date. Continued use of the app after any changes constitutes your acceptance of the updated policy.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

10. CONTACT

If you have questions about this Privacy Policy, please contact us through the app store listing or the project's public repository.
''';

const String kTermsOfServiceContent = '''
Terms of Service — Blinking (记忆闪烁)

Effective Date: March 21, 2026
App Name: Blinking (记忆闪烁)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. ACCEPTANCE OF TERMS

By downloading, installing, or using Blinking (记忆闪烁) ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these Terms, do not use the App.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2. DESCRIPTION OF SERVICE

Blinking is a personal memory and habit-tracking application that runs entirely on your device. The App allows you to:
• Record journal entries, emotions, and memories
• Track personal habits and routines
• Create and manage memory cards
• View personal statistics and summaries
• Optionally interact with a third-party AI assistant using your own API key

The App is fully functional without an internet connection. No account or registration is required.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3. LICENSE

We grant you a limited, non-exclusive, non-transferable, revocable license to use the App for your personal, non-commercial purposes.

You may not:
• Copy, modify, or distribute the App or its content
• Reverse engineer or attempt to extract the source code of the App
• Use the App for any unlawful purpose
• Use the App in any manner that could damage, disable, or impair the App

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

4. YOUR CONTENT

All content you create within the App (journal entries, habits, notes, media) belongs to you. We do not access, claim ownership of, or transmit your content.

Your content is stored locally on your device. You are responsible for maintaining backups of your own data. We are not liable for any data loss resulting from device failure, app uninstallation, or any other cause.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5. AI ASSISTANT FEATURE (OPTIONAL)

The App includes an optional AI Assistant. To use this feature, you must supply a valid API key from a supported third-party AI provider.

By using the AI Assistant feature, you acknowledge and agree that:

• You are responsible for obtaining and managing your own API key. We are not responsible for any costs, charges, or consequences arising from your use of a third-party AI provider's services.
• Content you send to the AI Assistant is transmitted to the AI provider you have configured. This transmission is governed by that provider's own terms of service and privacy policy, not ours.
• You will not use the AI Assistant to generate unlawful, harmful, or offensive content.
• We make no warranties regarding the accuracy, reliability, or appropriateness of AI-generated responses.
• You use AI-generated content at your own risk.

We are not affiliated with, endorsed by, or responsible for any third-party AI provider.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

6. PRIVACY

Your use of the App is also governed by our Privacy Policy. Key points:
• The App does not collect or transmit your personal data.
• All data is stored locally on your device.
• The App works fully offline without transmitting any information.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

7. DISCLAIMER OF WARRANTIES

THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.

We do not warrant that the App will be uninterrupted, error-free, or secure.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

8. LIMITATION OF LIABILITY

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR LOSS OF PROFITS, ARISING FROM YOUR USE OF THE APP.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

9. DATA LOSS

We are not responsible for any loss of data stored in the App. We strongly recommend using the built-in backup feature (Settings → Full Backup) regularly to protect your data.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

10. THIRD-PARTY SERVICES

The App may integrate with third-party services at your option (AI providers). These services are not operated by us, and we are not responsible for their content, availability, or practices. Your use of any third-party service is subject to that service's own terms and privacy policy.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

11. MODIFICATIONS

We reserve the right to modify or discontinue the App at any time. We may also update these Terms from time to time. Your continued use of the App after changes constitutes acceptance of the updated Terms.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

12. CONTACT

If you have questions about these Terms, please contact us through the app store listing or the project's public repository.
''';
