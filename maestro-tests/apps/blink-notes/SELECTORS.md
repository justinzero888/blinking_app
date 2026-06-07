# Blinking Notes — Semantic Identifiers

**Bundle ID:** `com.blinking.blinking`
**Flutter version:** 3.11+ (confirm upgrade to 3.19+ for `Semantics.identifier` support)
**Platform:** iOS + Android (shared YAML flows)

---

## Current Status

> ⚠️ The app currently uses **no `Semantics.identifier`** on interactive widgets.
> All flows below use **visible text selectors** (Strategy 2/3) as a workaround.
> Developers should add `Semantics.identifier` to all widgets listed below before
> writing the next round of flows. See [Playbook §2.3](../../maestro-testing-playbook.md).

---

## Recommended Identifiers to Add (Developer Task)

| Recommended Identifier       | Widget                  | Screen         | Notes                                       |
|------------------------------|-------------------------|----------------|---------------------------------------------|
| `btn_fab_add_entry`          | FloatingActionButton    | Home/Moments   | Opens AddEntryScreen; add to FAB in app.dart |
| `input_entry_body`           | TextField               | Add Memory     | Main note text field (hint: "What's on your mind?") |
| `btn_entry_save`             | IconButton (check icon) | Add Memory     | Saves entry; add Semantics wrapper in add_entry_screen.dart |
| `nav_my_day`                 | BottomNavItem           | Global         | "My Day" tab                                |
| `nav_moments`                | BottomNavItem           | Global         | "Moments" tab                               |
| `nav_routine`                | BottomNavItem           | Global         | "Routine" tab                               |
| `nav_insights`               | BottomNavItem           | Global         | "Insights" tab                              |
| `nav_settings`               | BottomNavItem           | Global         | "Settings" tab                              |
| `list_entries`               | ListView                | Moments        | Entries list container                      |
| `input_moments_search`       | TextField               | Moments        | Search bar (hint: "Search entries...")      |
| `btn_entry_delete_confirm`   | TextButton              | Delete dialog  | "Delete" confirm button                     |
| `label_empty_home`           | Text                    | Home           | "No entries today" empty state              |
| `label_empty_moments`        | Text                    | Moments        | "No entries yet" empty state                |
| `btn_onboarding_continue`    | FilledButton            | Onboarding     | "Continue" on page 1                        |
| `btn_onboarding_skip`        | TextButton              | Onboarding     | "Skip" on page 2                            |

---

## Current Text-Based Selectors in Use

| Visible Text / hintText         | Used In                        | Fragility  |
|---------------------------------|--------------------------------|------------|
| `"My Day"`                      | AppBar title, bottom nav label | Medium     |
| `"Moments"`                     | AppBar title, bottom nav label | Medium     |
| `"Routine"`                     | Bottom nav label               | Medium     |
| `"Insights"`                    | Bottom nav label               | Medium     |
| `"Settings"`                    | Bottom nav label               | Medium     |
| `"Add Memory"`                  | AppBar title in AddEntryScreen | Low        |
| `"What's on your mind?"`        | TextField hintText             | Low        |
| `"Memory saved!"`               | Snackbar after save            | Low        |
| `"Continue"`                    | Onboarding page 1 button       | Low        |
| `"Skip"`                        | Onboarding page 2 button       | Low        |
| `"No entries today"`            | Home empty state               | Low        |
| `"No entries yet"`              | Moments empty state            | Low        |
| `"Search entries..."`           | Moments search hintText        | Low        |
| `"Delete Entry"`                | Delete confirmation dialog     | Low        |
| `"Delete"`                      | Delete confirm button          | Low        |

---

## Dart Snippets — Add These to the App

```dart
// lib/app.dart — FAB
FloatingActionButton(
  heroTag: 'main_add_entry_fab',
  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEntryScreen())),
  child: Semantics(
    identifier: 'btn_fab_add_entry',
    child: const Icon(Icons.add),
  ),
)

// lib/screens/add_entry_screen.dart — Save button
Semantics(
  identifier: 'btn_entry_save',
  child: IconButton(icon: const Icon(Icons.check, size: 28), onPressed: _saveEntry, tooltip: 'Save'),
)

// lib/screens/add_entry_screen.dart — Note text field
Semantics(
  identifier: 'input_entry_body',
  child: TextField(controller: _textController, ...),
)

// lib/screens/moment/moment_screen.dart — Search field
Semantics(
  identifier: 'input_moments_search',
  child: TextField(controller: _searchController, ...),
)

// lib/screens/moment/moment_screen.dart — Entry list
Semantics(
  identifier: 'list_entries',
  child: ListView.builder(...),
)
```
