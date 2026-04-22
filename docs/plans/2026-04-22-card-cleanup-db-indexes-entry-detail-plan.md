# Card PNG Cleanup, DB Indexes, Entry Detail Screen — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix orphaned card PNG accumulation, add DB query indexes, and add a read-only entry detail screen sitting between the Moments list and edit mode.

**Architecture:** Three independent changes — (1) `CardProvider` file cleanup on delete/update, (2) additive SQLite migration v8→v9 with three indexes, (3) new `EntryDetailScreen` stateless widget with `MomentScreen` wired to navigate to it on tap. TDD order: write failing test → implement → confirm pass → commit.

**Tech Stack:** Flutter/Dart, sqflite, provider, share_plus, open_filex, flutter_test

---

## Task 1: DB Indexes — migration v8 → v9

**Files:**
- Modify: `lib/core/services/database_service.dart`

**Step 1: Write the failing test**

Create `test/core/db_version_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/core/services/database_service.dart';

void main() {
  test('DatabaseService targets schema version 9', () {
    // This test will fail until the version constant is bumped.
    // It acts as a compile-time guard so version drift is caught.
    expect(DatabaseService.kSchemaVersion, 9);
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/core/db_version_test.dart
```
Expected: FAIL — `kSchemaVersion` not defined.

**Step 3: Add version constant and indexes to DatabaseService**

In `lib/core/services/database_service.dart`:

a) Add static constant just inside the class:
```dart
static const int kSchemaVersion = 9;
```

b) Change `openDatabase` call:
```dart
version: DatabaseService.kSchemaVersion,
```
(was `version: 8`)

c) Add migration block at end of `_onUpgrade`:
```dart
if (oldVersion < 9) {
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_entries_created_at ON entries(created_at)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_entry_tags_tag_id ON entry_tags(tag_id)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_completions_routine_id ON completions(routine_id)',
  );
}
```

d) Add same three `CREATE INDEX` statements to `_onCreate`, after the `note_card_entries` table creation.

**Step 4: Run test to verify it passes**

```bash
flutter test test/core/db_version_test.dart
```
Expected: PASS

**Step 5: Commit**

```bash
git add lib/core/services/database_service.dart test/core/db_version_test.dart
git commit -m "feat: add DB indexes migration v9 for entries, entry_tags, completions"
```

---

## Task 2: Card PNG Cleanup — CardProvider

**Files:**
- Modify: `lib/providers/card_provider.dart`

**Step 1: Write the failing tests**

Create `test/providers/card_provider_cleanup_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/providers/card_provider.dart';
import 'package:blinking/core/services/storage_service.dart';
import 'package:blinking/models/note_card.dart';

/// Fake StorageService — overrides only the methods CardProvider calls.
/// Does NOT call init() so no platform channels are needed.
class _FakeStorage extends StorageService {
  @override
  Future<void> deleteNoteCard(String id) async {}

  @override
  Future<void> updateNoteCard(NoteCard card) async {}
}

NoteCard _card({String id = 'c1', String? imagePath}) => NoteCard(
      id: id,
      entryIds: const [],
      templateId: 'tmpl',
      folderId: 'folder',
      renderedImagePath: imagePath,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  group('CardProvider — PNG cleanup', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('card_cleanup_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('deleteCard deletes the rendered PNG from disk', () async {
      final pngFile = File('${tempDir.path}/card.png')..writeAsBytesSync([0, 1]);
      expect(pngFile.existsSync(), isTrue);

      final provider = CardProvider(_FakeStorage());
      // Seed internal list directly via addCard would require storage;
      // instead expose via load-like approach using the internal list.
      // We call _cards directly through the test helper below.
      provider.seedForTest([_card(imagePath: pngFile.path)]);

      await provider.deleteCard('c1');

      expect(pngFile.existsSync(), isFalse,
          reason: 'deleteCard must delete the PNG file from disk');
    });

    test('updateCard deletes old PNG when renderedImagePath changes', () async {
      final oldPng = File('${tempDir.path}/old.png')..writeAsBytesSync([0, 1]);
      final provider = CardProvider(_FakeStorage());
      provider.seedForTest([_card(imagePath: oldPng.path)]);

      final updatedCard = _card(imagePath: '${tempDir.path}/new.png');
      await provider.updateCard(updatedCard);

      expect(oldPng.existsSync(), isFalse,
          reason: 'updateCard must delete old PNG when path changes');
    });

    test('updateCard does NOT delete PNG when path is unchanged', () async {
      final png = File('${tempDir.path}/same.png')..writeAsBytesSync([0, 1]);
      final provider = CardProvider(_FakeStorage());
      provider.seedForTest([_card(imagePath: png.path)]);

      await provider.updateCard(_card(imagePath: png.path));

      expect(png.existsSync(), isTrue,
          reason: 'updateCard must not delete PNG when path is unchanged');
    });

    test('deleteCard with null renderedImagePath does not throw', () async {
      final provider = CardProvider(_FakeStorage());
      provider.seedForTest([_card()]); // no image path

      expect(() async => provider.deleteCard('c1'), returnsNormally);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/providers/card_provider_cleanup_test.dart
```
Expected: FAIL — `seedForTest` method not found.

**Step 3: Implement PNG cleanup in CardProvider**

In `lib/providers/card_provider.dart`:

a) Add import at top:
```dart
import 'dart:io';
```

b) Add test-only seed helper at end of class (before closing `}`):
```dart
/// Test-only: seeds the internal card list without touching storage.
/// Must NOT be called in production code.
@visibleForTesting
void seedForTest(List<NoteCard> cards) {
  _cards = List.of(cards);
}
```

c) Replace `deleteCard`:
```dart
Future<void> deleteCard(String id) async {
  final card = _cards.where((c) => c.id == id).firstOrNull;
  final imagePath = card?.renderedImagePath;
  await _storage.deleteNoteCard(id);
  _cards.removeWhere((c) => c.id == id);
  if (imagePath != null) {
    final file = File(imagePath);
    if (await file.exists()) await file.delete();
  }
  notifyListeners();
}
```

d) Replace `updateCard`:
```dart
Future<void> updateCard(NoteCard card) async {
  final index = _cards.indexWhere((c) => c.id == card.id);
  if (index != -1) {
    final oldPath = _cards[index].renderedImagePath;
    final newPath = card.renderedImagePath;
    if (oldPath != null && oldPath != newPath) {
      final file = File(oldPath);
      if (await file.exists()) await file.delete();
    }
  }
  await _storage.updateNoteCard(card);
  if (index != -1) {
    _cards[index] = card;
    notifyListeners();
  }
}
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/providers/card_provider_cleanup_test.dart
```
Expected: all 4 PASS

**Step 5: Commit**

```bash
git add lib/providers/card_provider.dart test/providers/card_provider_cleanup_test.dart
git commit -m "fix(cards): delete orphaned PNG files on card delete and update"
```

---

## Task 3: EntryDetailScreen — new read-only view

**Files:**
- Create: `lib/screens/moment/entry_detail_screen.dart`

**Step 1: Write the failing widget test**

Create `test/screens/entry_detail_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:blinking/models/entry.dart';
import 'package:blinking/providers/locale_provider.dart';
import 'package:blinking/providers/tag_provider.dart';
import 'package:blinking/core/services/storage_service.dart';
import 'package:blinking/screens/moment/entry_detail_screen.dart';

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(
        create: (_) => TagProvider(StorageService())..loadTagsForTest([]),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

Entry _entry({String content = 'Hello memory', String? emotion}) => Entry(
      id: 'e1',
      type: EntryType.freeform,
      content: content,
      createdAt: DateTime(2026, 4, 22, 9, 30),
      updatedAt: DateTime(2026, 4, 22, 9, 30),
      emotion: emotion,
    );

void main() {
  group('EntryDetailScreen', () {
    testWidgets('displays entry content', (tester) async {
      await tester.pumpWidget(_wrap(EntryDetailScreen(entry: _entry())));
      await tester.pump();
      expect(find.text('Hello memory'), findsOneWidget);
    });

    testWidgets('displays emotion emoji when present', (tester) async {
      await tester.pumpWidget(
          _wrap(EntryDetailScreen(entry: _entry(emotion: '😊'))));
      await tester.pump();
      expect(find.text('😊'), findsOneWidget);
    });

    testWidgets('no emotion widget when emotion is null', (tester) async {
      await tester.pumpWidget(_wrap(EntryDetailScreen(entry: _entry())));
      await tester.pump();
      // Only the content text — no stray emoji
      expect(find.text('😊'), findsNothing);
    });

    testWidgets('Edit button is present in AppBar', (tester) async {
      await tester.pumpWidget(_wrap(EntryDetailScreen(entry: _entry())));
      await tester.pump();
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('Share button is present in AppBar', (tester) async {
      await tester.pumpWidget(_wrap(EntryDetailScreen(entry: _entry())));
      await tester.pump();
      expect(find.byIcon(Icons.share), findsOneWidget);
    });
  });
}
```

Note: This test requires `TagProvider.loadTagsForTest([])` — a test-only method to be added in Step 3b.

**Step 2: Run test to verify it fails**

```bash
flutter test test/screens/entry_detail_screen_test.dart
```
Expected: FAIL — `EntryDetailScreen` not found.

**Step 3: Create EntryDetailScreen**

Create `lib/screens/moment/entry_detail_screen.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/file_service.dart';
import '../../models/entry.dart';
import '../../providers/locale_provider.dart';
import '../../providers/tag_provider.dart';
import '../../widgets/tag_chip.dart';
import '../add_entry_screen.dart';

class EntryDetailScreen extends StatelessWidget {
  final Entry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final tagProvider = context.watch<TagProvider>();
    final tags = tagProvider.tags.where((t) => entry.tagIds.contains(t.id)).toList();

    final dateStr = isZh
        ? DateFormat('yyyy年M月d日 HH:mm').format(entry.createdAt)
        : DateFormat('MMM d, y  HH:mm').format(entry.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(dateStr),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: isZh ? '编辑' : 'Edit',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEntryScreen(existingEntry: entry),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: isZh ? '分享' : 'Share',
            onPressed: () => Share.share(
              entry.content,
              subject: isZh ? '来自 Blinking' : 'From Blinking',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.emotion != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(entry.emotion!, style: const TextStyle(fontSize: 32)),
              ),
            SelectableText(
              entry.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tags.map((t) => TagChip(tag: t, small: true)).toList(),
              ),
            ],
            if (entry.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _MediaGrid(mediaUrls: entry.mediaUrls),
            ],
          ],
        ),
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<String> mediaUrls;
  const _MediaGrid({required this.mediaUrls});

  @override
  Widget build(BuildContext context) {
    final fileService = FileService();
    return Column(
      children: mediaUrls.map((url) {
        final isImage = url.toLowerCase().endsWith('.jpg') ||
            url.toLowerCase().endsWith('.jpeg') ||
            url.toLowerCase().endsWith('.png');
        return FutureBuilder<String>(
          future: url.startsWith('/') ? Future.value(url) : fileService.getFullPath(url),
          builder: (context, snapshot) {
            final fullPath = snapshot.data;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: fullPath != null ? () => OpenFilex.open(fullPath) : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (fullPath != null && isImage && File(fullPath).existsSync())
                      ? Image.file(File(fullPath), fit: BoxFit.contain, width: double.infinity)
                      : Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.insert_drive_file, size: 48),
                        ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
```

Also add `loadTagsForTest` to `TagProvider` (`lib/providers/tag_provider.dart`):

```dart
/// Test-only: seeds the tag list without touching storage.
@visibleForTesting
void loadTagsForTest(List<Tag> tags) {
  _tags = List.of(tags);
}
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/screens/entry_detail_screen_test.dart
```
Expected: all 5 PASS

**Step 5: Commit**

```bash
git add lib/screens/moment/entry_detail_screen.dart \
        lib/providers/tag_provider.dart \
        test/screens/entry_detail_screen_test.dart
git commit -m "feat: add EntryDetailScreen — read-only entry view with Edit and Share"
```

---

## Task 4: Wire MomentScreen to EntryDetailScreen

**Files:**
- Modify: `lib/screens/moment/moment_screen.dart`

**Step 1: Update the import and onTap**

In `lib/screens/moment/moment_screen.dart`:

a) Add import (alongside existing imports):
```dart
import 'entry_detail_screen.dart';
```

b) In `_buildEntryCard`, replace the `onTap` handler:
```dart
// BEFORE:
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddEntryScreen(existingEntry: entry),
    ),
  );
},

// AFTER:
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EntryDetailScreen(entry: entry),
    ),
  );
},
```

Do NOT remove the `AddEntryScreen` import — it is still used by the FAB and other parts of the app.

**Step 2: Run full test suite**

```bash
flutter test
```
Expected: all 44+ tests PASS (exact count grows with new tests added above)

**Step 3: Commit**

```bash
git add lib/screens/moment/moment_screen.dart
git commit -m "feat: moment list tap opens EntryDetailScreen instead of edit"
```

---

## Task 5: Full regression suite + build

**Step 1: Run all tests**

```bash
flutter test
```
Expected: all tests PASS, 0 failures.

**Step 2: Analyze**

```bash
flutter analyze --no-pub
```
Expected: 0 errors (existing warnings/infos are pre-existing and acceptable).

**Step 3: Build release APK**

```bash
flutter build apk --release
```
Expected: `✓ Built build/app/outputs/flutter-apk/app-release.apk`

**Step 4: Install and run on Android emulator**

```bash
flutter install --release
```
Or manually install the APK on the emulator/device.

**Manual regression checklist:**
- [ ] Moments list: tap entry → opens EntryDetailScreen (read-only), NOT edit
- [ ] Detail screen: content shown in full (no truncation)
- [ ] Detail screen: emotion emoji shown at 32px
- [ ] Detail screen: Edit button → opens AddEntryScreen, changes saved, returns to detail
- [ ] Detail screen: Share button → system share sheet opens with entry text
- [ ] Detail screen: back arrow → returns to Moments list
- [ ] Long-press on entry in Moments list → delete dialog still works
- [ ] Cards: delete a card with a saved PNG → PNG file is gone from storage
- [ ] Cards: edit a card, save → old PNG cleaned up, new PNG saved
- [ ] Cards: edit a card, save without changing anything → PNG not deleted
- [ ] Settings → Full Backup → completes without OOM on large media library
- [ ] Settings → Export to JSON → works
- [ ] Settings → Export to CSV → works
- [ ] Existing 44+ tests pass (`flutter test`)

**Step 5: Commit version bump after validation**

Once testing passes, commit the uncommitted changes from this session:

```bash
git add pubspec.yaml lib/core/services/export_service.dart
git commit -m "fix(export): stream ZIP encoding to prevent OOM on large media libraries

Replaces in-memory Archive buffer with ZipFileEncoder streaming.
Peak RAM reduced from ~3GB to ~one photo at a time.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```
