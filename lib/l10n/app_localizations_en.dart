// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Blinking';

  @override
  String get home => 'Home';

  @override
  String get calendar => 'Calendar';

  @override
  String get moment => 'Moments';

  @override
  String get timeline => 'Timeline';

  @override
  String get add => 'Add';

  @override
  String get routine => 'Routine';

  @override
  String get settings => 'Settings';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get all => 'All';

  @override
  String get search => 'Search';

  @override
  String get tags => 'Tags';

  @override
  String get tagManagement => 'Tag Management';

  @override
  String get addTag => 'Add Tag';

  @override
  String get editTag => 'Edit Tag';

  @override
  String get deleteTag => 'Delete Tag';

  @override
  String get addEntry => 'Add Entry';

  @override
  String get editEntry => 'Edit Entry';

  @override
  String get deleteEntry => 'Delete Entry';

  @override
  String get content => 'Content';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get complete => 'Complete';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get addRoutine => 'Add Routine';

  @override
  String get editRoutine => 'Edit Routine';

  @override
  String get deleteRoutine => 'Delete Routine';

  @override
  String get routineName => 'Routine Name';

  @override
  String get frequency => 'Frequency';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get target => 'Target';

  @override
  String get completed => 'Completed';

  @override
  String get notCompleted => 'Not Completed';

  @override
  String get language => 'Language';

  @override
  String get chinese => 'Chinese';

  @override
  String get english => 'English';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get noEntries => 'No entries yet';

  @override
  String get noRoutines => 'No routines yet';

  @override
  String get noTags => 'No tags yet';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get reflection => 'Reflection';

  @override
  String get dailySummary => 'Daily Summary';

  @override
  String get weeklySummary => 'Weekly Summary';

  @override
  String get monthlySummary => 'Monthly Summary';

  @override
  String get goodMorning => 'Good morning!';

  @override
  String get goodAfternoon => 'Good afternoon!';

  @override
  String get goodEvening => 'Good evening!';

  @override
  String get howAreYou => 'How are you today?';

  @override
  String get text => 'Text';

  @override
  String get audio => 'Audio';

  @override
  String get video => 'Video';

  @override
  String get image => 'Image';

  @override
  String get attachment => 'Attachment';

  @override
  String get selectTags => 'Select Tags';

  @override
  String get createdAt => 'Created';

  @override
  String get updatedAt => 'Updated';

  @override
  String get summaryNoteCount => '📝 Notes';

  @override
  String get summaryHabitCompletion => '✅ Habit Completion';

  @override
  String get summaryMoodTrend => '😊 Mood Trend';

  @override
  String get summaryTopTags => '🏷️ Top Tags';

  @override
  String get summaryScopeDay => 'Day';

  @override
  String get summaryScopeWeek => 'Week';

  @override
  String get summaryScopeMonth => 'Month';

  @override
  String get summaryNoNotes => 'No note data yet';

  @override
  String get summaryNoHabits => 'No habit data yet';

  @override
  String get summaryNoMood => 'No mood data yet (add emotions to entries)';

  @override
  String get summaryNoTags => 'No tag data yet';

  @override
  String get moodHappy => 'Joyful';

  @override
  String get moodSad => 'Sad';

  @override
  String get moodAngry => 'Angry';

  @override
  String get moodAnxious => 'Anxious';

  @override
  String get moodTired => 'Tired';

  @override
  String get moodExcited => 'Excited';

  @override
  String get moodCalm => 'Calm';

  @override
  String get moodFrustrated => 'Frustrated';

  @override
  String get moodLoving => 'Loving';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get aiSecretsTagName => 'Secrets';

  @override
  String get trialBannerStartTitle => 'Try AI for Free — 7 Days';

  @override
  String get trialBannerStartSubtitle => 'No setup needed. Start chatting now.';

  @override
  String get trialBannerStartButton => 'Start Free Trial →';

  @override
  String get trialBannerActiveTitle => 'Trial Active';

  @override
  String get trialBannerActiveSubtitle =>
      'You can add your own key anytime in the provider list.';

  @override
  String get trialBannerExpiredTitle => 'Trial Expired';

  @override
  String get trialBannerExpiredSubtitle =>
      'Add your own API key below to continue using the AI assistant.';

  @override
  String get trialBannerExpiredButton => 'Get a free key →';

  @override
  String get trialProviderName => '7-Day Trial';

  @override
  String trialProviderSubtitleDays(Object daysLeft) {
    return '$daysLeft days remaining · 20 requests/day';
  }

  @override
  String get trialProviderSubtitleDay => '1 day remaining · 20 requests/day';

  @override
  String get trialProviderChip => 'Trial';

  @override
  String get trialProviderExpiredChip => 'Expired';

  @override
  String get trialStartError => 'Failed to start trial. Please try again.';

  @override
  String get trialAlreadyUsed =>
      'You have already used your free trial on this device.';

  @override
  String get trialInfoDialogTitle => 'Trial Details';

  @override
  String get trialInfoModel => 'Model: qwen/qwen3.5-flash';

  @override
  String get trialInfoUrl => 'Proxied by Blinking trial backend';

  @override
  String get trialInfoCannotEdit => 'Trial provider cannot be edited.';

  @override
  String get noteFormat => 'Note';

  @override
  String get listFormat => 'List';

  @override
  String get listTitleHint => 'List title';

  @override
  String get listItemHint => 'Add item';

  @override
  String itemsDone(Object done, Object total) {
    return '$done / $total done';
  }

  @override
  String carriedOverBanner(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items carried over from yesterday',
      one: '$count item carried over from yesterday',
    );
    return '$_temp0';
  }

  @override
  String get listsSectionHeader => 'Lists';

  @override
  String get notesSectionHeader => 'Notes';

  @override
  String get listSaveDisabledHint => 'Add at least one item';
}
