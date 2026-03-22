import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/theme.dart';
import 'core/services/storage_service.dart';
import 'repositories/repositories.dart';
import 'providers/routine_provider.dart';
import 'providers/entry_provider.dart';
import 'providers/tag_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/jar_provider.dart';
import 'providers/card_provider.dart';
import 'providers/summary_provider.dart';
import 'providers/ai_persona_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/moment/moment_screen.dart';
import 'screens/routine/routine_screen.dart';
import 'screens/cherished/cherished_memory_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/add_entry_screen.dart';
import 'widgets/floating_robot.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'l10n/app_localizations.dart';

import 'core/services/export_service.dart';

class BlinkingApp extends StatelessWidget {
  final StorageService storageService;

  const BlinkingApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    // Create repositories
    final entryRepository = EntryRepository(storageService);
    final routineRepository = RoutineRepository(storageService);
    final tagRepository = TagRepository(storageService);

    return MultiProvider(
      providers: [
        // Services
        Provider<StorageService>.value(value: storageService),
        Provider<ExportService>(
          create: (context) => ExportService(storageService),
        ),

        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),

        // Locale provider
        ChangeNotifierProvider(create: (_) {
          final provider = LocaleProvider();
          provider.loadLocale();
          return provider;
        }),

        // Repository providers
        Provider<EntryRepository>.value(value: entryRepository),
        Provider<RoutineRepository>.value(value: routineRepository),
        Provider<TagRepository>.value(value: tagRepository),

        // Main data providers
        ChangeNotifierProvider(
          create: (_) => EntryProvider(entryRepository)..loadEntries(),
        ),
        ChangeNotifierProvider(
          create: (_) => RoutineProvider(routineRepository)
            ..loadRoutines(),
        ),
        ChangeNotifierProvider(
          create: (_) => TagProvider(tagRepository)..loadTags(),
        ),

        // JarProvider — depends on EntryProvider
        ChangeNotifierProxyProvider<EntryProvider, JarProvider>(
          create: (context) => JarProvider(context.read<EntryProvider>()),
          update: (context, entryProvider, jar) =>
              jar!..update(entryProvider),
        ),

        // CardProvider — standalone, loads from storage
        ChangeNotifierProvider(
          create: (context) =>
              CardProvider(context.read<StorageService>())..load(),
        ),

        // AiPersonaProvider — avatar, name, personality
        ChangeNotifierProvider(create: (_) => AiPersonaProvider()),

        // SummaryProvider — depends on EntryProvider + RoutineProvider
        ChangeNotifierProxyProvider2<EntryProvider, RoutineProvider,
            SummaryProvider>(
          create: (context) => SummaryProvider(
            context.read<EntryProvider>(),
            context.read<RoutineProvider>(),
          ),
          update: (context, ep, rp, summary) => summary!..update(ep, rp),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'Blinking',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              ...AppLocalizations.localizationsDelegates,
              FlutterQuillLocalizations.delegate,
            ],
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MomentScreen(),
    const RoutineScreen(),
    const CherishedMemoryScreen(),
    const SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Floating AI robot — overlaid above all content
          const FloatingRobotWidget(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: l10n.calendar,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.access_time),
            label: l10n.moment,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.check_circle_outline),
            label: l10n.routine,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_awesome),
            label: isZh ? '珍藏' : 'Keepsakes',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEntryScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
