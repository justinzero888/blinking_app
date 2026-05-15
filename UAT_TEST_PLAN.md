# Blinking App — UAT Test Plan

**App Version:** 1.1.0+37  
**Test Date:** May 2026  
**Target Devices:** iPhone 12+, iPad, Android (Play Store)  
**Testers:** QA Team / Beta Users  
**Completion Goal:** 100% critical path coverage

---

## Table of Contents
1. [Test Strategy](#test-strategy)
2. [Environment Setup](#environment-setup)
3. [Critical User Journeys](#critical-user-journeys)
4. [Screen-by-Screen Test Cases](#screen-by-screen-test-cases)
5. [Feature-Specific Tests](#feature-specific-tests)
6. [Bilingual Content Verification](#bilingual-content-verification)
7. [Edge Cases & Error Scenarios](#edge-cases--error-scenarios)
8. [Regression Test Suite](#regression-test-suite)
9. [UAT Sign-Off](#uat-sign-off)

---

## Test Strategy

### Test Scope
✅ **In Scope:**
- All 5 main screens (Calendar, Moment, Routine, Insights, Settings)
- Core CRUD operations (Create, Read, Update, Delete entries/routines)
- Entitlement flow (Preview → Restricted → Paid)
- IAP purchase (RevenueCat sandbox)
- Backup/Restore
- Bilingual UI (EN ↔ ZH)
- AI features (on Preview/Paid)

❌ **Out of Scope:**
- Network simulation (WiFi loss, 4G throttling)
- Load testing (1000+ entries)
- Visual design review
- Accessibility (a11y) compliance
- Performance profiling

### Test Environment
- **iOS:** TestFlight build (v1.1.0+37)
- **Android:** Google Play internal testing (v1.1.0+37)
- **RevenueCat:** Sandbox test store
- **Debug Toggle:** Settings → About → tap version 5x to cycle entitlement state
- **Test Data:** Pre-populated with 5 sample entries + 3 routines

### Test Execution Rules
1. **Fresh Install:** Clear app data before starting UAT
2. **Bilingual Testing:** Run each test in BOTH English and Chinese
3. **Screenshot Evidence:** Capture screenshots for all critical paths
4. **Error Handling:** Document any error messages with full details
5. **Pass Criteria:** Feature works as documented in CLAUDE.md without crashes

---

## Environment Setup

### Pre-UAT Checklist

- [ ] TestFlight/Play Store build installed (v1.1.0+37)
- [ ] Fresh app install (clear all data)
- [ ] Apple ID / Google account ready for purchases
- [ ] Camera/photo library accessible
- [ ] Notifications enabled
- [ ] Device language set to English
- [ ] Network connection stable (WiFi)
- [ ] Device has 500MB+ free space
- [ ] iOS: Settings → Payments & Subscriptions → Sandbox account configured

### Reset App Between Tests
```
Settings → General → iPhone Storage → Blinking → Offload App → Reinstall
(or: App Switcher → Long press Blinking → Remove App → Reinstall from TestFlight)
```

---

## Critical User Journeys

### Journey 1: New User → Trial → Purchase

**Objective:** Verify complete onboarding and IAP flow

**Test Steps:**

| Step | Action | Expected Result | Screenshot |
|------|--------|-----------------|------------|
| 1 | Launch app fresh install | Onboarding screen 1 shows (3-screen flow) | ▢ |
| 2 | Tap language toggle (ZH) | UI switches to Chinese, text readable | ▢ |
| 3 | Tap language toggle (EN) | UI switches back to English | ▢ |
| 4 | Swipe through 3 onboarding screens | Philosophy → Features → "The Deal" visible | ▢ |
| 5 | Tap "Continue" on screen 3 | Redirected to Home/Calendar screen | ▢ |
| 6 | Go to Settings → AI section | Shows "Preview Mode - Free Trial" banner | ▢ |
| 7 | Tap floating robot (🤖) | AssistantScreen opens, can send message | ▢ |
| 8 | Type message "Hello" | Message sends, AI responds (LLM working) | ▢ |
| 9 | Settings → About → tap version 5x | Entitlement cycles: Preview → Restricted | ▢ |
| 10 | Tap floating robot again | Paywall screen appears ($19.99) | ▢ |
| 11 | Tap "Purchase" button | RevenueCat sandbox purchase dialog | ▢ |
| 12 | Complete purchase (test account) | Shows "Thank you!" confirmation | ▢ |
| 13 | Close paywall, back to home | Status changes to "Pro (Paid)" in Settings | ▢ |
| 14 | Tap floating robot again | AssistantScreen opens (no paywall) | ▢ |

**Pass Criteria:**
- ✅ Onboarding appears only once
- ✅ Language toggle switches both UI and stored preference
- ✅ Preview mode allows 3 AI messages per day
- ✅ Restricted mode shows paywall on robot tap
- ✅ Purchase completes without crashes
- ✅ Paid mode provides immediate AI access

**Bilingual Notes:**
- Test in both English and Chinese
- Verify onboarding text is accurate in both languages
- Verify paywall copy is translated

---

### Journey 2: Create Entry → Add AI Reflection → Save

**Objective:** Verify entry creation with AI reflection save

**Test Steps:**

| Step | Action | Expected Result | Screenshot |
|------|--------|-----------------|------------|
| 1 | Go to Home (Calendar) screen | Calendar grid visible, today highlighted | ▢ |
| 2 | Tap FAB (+) on Calendar | AddEntryScreen opens | ▢ |
| 3 | Select emotion: 😊 | Emotion picker shows, emoji selected | ▢ |
| 4 | Enter text: "Had a great meeting today" | Text appears in textarea | ▢ |
| 5 | Select tag: "work" | Tag badge appears in UI | ▢ |
| 6 | Tap "Save" | Entry saved, returned to Calendar | ▢ |
| 7 | Verify entry on calendar | Today's cell shows 😊 emoji + entry visible | ▢ |
| 8 | Tap entry card | EntryDetailScreen opens (read-only) | ▢ |
| 9 | Tap "Get AI Reflection" button | AssistantScreen opens with entry pre-loaded | ▢ |
| 10 | Review AI response | LLM generated thoughtful reflection | ▢ |
| 11 | Tap "Save Reflection" | Creates new entry tagged "tag_synthesis" | ▢ |
| 12 | Go to Moment screen | Both original + reflection entries visible | ▢ |
| 13 | Search for "meeting" | Original entry appears in search results | ▢ |
| 14 | Filter by tag "work" | Shows only work-tagged entries | ▢ |

**Pass Criteria:**
- ✅ Entry saves with emotion, text, and tag
- ✅ Entry visible in calendar and Moment screens
- ✅ AI reflection saved as separate entry
- ✅ Search and tag filters work correctly

**Bilingual Testing:**
- Type Chinese text: "今天开会很不错"
- Verify emoji picker works in both languages
- Verify tag names display correctly

---

### Journey 3: Create Routine → Track Completion → View Insights

**Objective:** Verify habit creation, daily tracking, and insights display

**Test Steps:**

| Step | Action | Expected Result | Screenshot |
|------|--------|-----------------|------------|
| 1 | Go to Routine screen | 3 tabs visible (Build / Do / Reflect) | ▢ |
| 2 | Tap "Build" tab | List of configured routines shows | ▢ |
| 3 | Tap FAB to add routine | AddRoutineDialog opens | ▢ |
| 4 | Enter name: "Morning Jog" | Text appears in title field | ▢ |
| 5 | Select frequency: "Daily" | Daily option selected | ▢ |
| 6 | Tap Save | Routine added to list | ▢ |
| 7 | Go to "Do" tab | Today's routines listed with checkbox | ▢ |
| 8 | Tap checkbox next to "Morning Jog" | Checkbox marked, timestamp recorded | ▢ |
| 9 | Go to Insights screen | Summary cards visible (habit completion rate) | ▢ |
| 10 | Scroll down | Heatmap, mood trend, top tags visible | ▢ |
| 11 | Scroll to habit completion chart | Shows 100% completion (today marked) | ▢ |
| 12 | Go to "Reflect" tab | Shows routine completion summary | ▢ |

**Pass Criteria:**
- ✅ Routine creates successfully
- ✅ Completion toggles immediately
- ✅ Insights reflect today's completion
- ✅ All 3 tabs accessible and render without errors

**Category Detection:**
- Create routine with name "Evening Fitness" → auto-detects "fitness" category
- Verify category emoji displays (💪 for fitness)

---

### Journey 4: Backup → Restore → Verify Data

**Objective:** Verify backup/restore workflow preserves all data

**Test Steps:**

| Step | Action | Expected Result | Screenshot |
|------|--------|-----------------|------------|
| 1 | Create 3 entries with different emotions | Calendar shows 3 entries for different dates | ▢ |
| 2 | Create 2 routines (Daily + Weekly) | Routine screen shows both | ▢ |
| 3 | Add custom tags | Settings → Tags → shows custom list | ▢ |
| 4 | Go to Settings → Export Data | Export options visible | ▢ |
| 5 | Tap "Backup" button | Progress dialog shows, zip file created | ▢ |
| 6 | Save backup file to device | File saved (on device via Files app) | ▢ |
| 7 | Delete 1 entry manually | Calendar updated, entry gone | ▢ |
| 8 | Go to Settings → Restore Data | Restore options visible | ▢ |
| 9 | Select backup file from step 6 | File loaded, restore preview shown | ▢ |
| 10 | Tap "Restore" | Progress dialog, data restored | ▢ |
| 11 | Verify all 3 entries back | Calendar shows all original entries | ▢ |
| 12 | Verify routines restored | Routine screen shows both routines | ▢ |
| 13 | Verify tags restored | Settings → Tags → shows custom tags | ▢ |
| 14 | Switch language to Chinese | All restored data readable in Chinese | ▢ |

**Pass Criteria:**
- ✅ Backup completes without errors
- ✅ Backup file is valid ZIP archive
- ✅ Restore recovers all entries, routines, tags
- ✅ Data integrity maintained post-restore
- ✅ No duplicate entries created

**File Size Note:**
- 3 entries + 2 routines ≈ 20KB backup
- 100 entries + 10 routines ≈ 500KB backup

---

### Journey 5: Theme & Locale Switching

**Objective:** Verify theme persistence and bilingual UI consistency

**Test Steps:**

| Step | Action | Expected Result | Screenshot |
|------|--------|-----------------|------------|
| 1 | Go to Settings screen | Language + Theme options visible | ▢ |
| 2 | Check current theme | Shows "System" (or Light/Dark) | ▢ |
| 3 | Toggle to Dark mode | Entire app switches to dark colors | ▢ |
| 4 | Go to Home screen | All text readable on dark background | ▢ |
| 5 | Go back to Settings | Theme still set to Dark | ▢ |
| 6 | Toggle back to Light mode | App returns to light theme | ▢ |
| 7 | Toggle language to 中文 (Chinese) | All UI text switches to Chinese | ▢ |
| 8 | Go to Home → Moment → Routine → Insights | All screens have Chinese labels | ▢ |
| 9 | Go to Settings | Settings screen in Chinese | ▢ |
| 10 | Create new entry with Chinese text | "今天很开心" | ▢ |
| 11 | Toggle language back to English | Entry text preserved, UI in English | ▢ |
| 12 | Kill app, relaunch | Theme + language persist (English/Light) | ▢ |

**Pass Criteria:**
- ✅ Theme changes apply system-wide immediately
- ✅ Language switch is instant (no reload)
- ✅ Theme and language persist across app restart
- ✅ All UI text is readable in both themes
- ✅ User data unaffected by theme/language changes

**Bilingual Content Checklist:**
- [ ] Home screen title (Calendar / 日历)
- [ ] Moment screen (Moment / 时刻)
- [ ] Routine screen (Routine / 日常)
- [ ] Insights screen (Insights / 洞察)
- [ ] Settings screen (Settings / 设置)
- [ ] Emotion picker labels
- [ ] Button text (Save / Save Reflection)
- [ ] Placeholder text in fields

---

## Screen-by-Screen Test Cases

### Screen 1: HOME (Calendar)

**Navigation:** Bottom nav first icon  
**Purpose:** View entries by date, quick add

#### Test Case 1.1: Calendar Displays Current Month
```
Preconditions:
  - App on Home screen
  - Current date: May 2026

Steps:
  1. View calendar grid
  2. Verify current day (15) is highlighted
  3. Verify month/year header shows "May 2026"
  4. Scroll down to see all days

Expected:
  ✓ Grid shows 35-42 days (previous month's trailing days included)
  ✓ Current day has distinct visual indicator (blue circle)
  ✓ Weekday headers show (S M T W T F S)
  ✓ Today emoji visible if entries exist

Evidence: Screenshot
```

#### Test Case 1.2: Emoji Shows on Date with Entry
```
Preconditions:
  - 3 entries created for different dates
  - Home screen visible

Steps:
  1. Look at calendar grid
  2. Identify dates with entries
  3. Verify emoji from latest entry of day shows

Expected:
  ✓ Dates with entries show emoji (😊 😢 😌 etc.)
  ✓ Dates without entries are blank
  ✓ Emoji matches most recent entry's emotion

Evidence: Screenshot
```

#### Test Case 1.3: Tap Date to View Day Entries
```
Preconditions:
  - 2+ entries on same date (May 15)
  - Home screen visible

Steps:
  1. Tap on May 15 (date with emoji)
  2. View entry list for that day
  3. Scroll to see all entries
  4. Tap first entry card

Expected:
  ✓ Day view shows all entries for May 15
  ✓ Entries sorted by time (latest first)
  ✓ Entry cards show emotion, text preview, tag
  ✓ Tapping entry opens EntryDetailScreen

Evidence: Screenshot
```

#### Test Case 1.4: FAB Creates Entry
```
Preconditions:
  - Home screen visible
  - Not in past date

Steps:
  1. Tap floating action button (+)
  2. AddEntryScreen opens
  3. Select emotion 😢
  4. Type: "Feeling overwhelmed"
  5. Tap Save

Expected:
  ✓ Entry saved immediately
  ✓ Returned to Home screen
  ✓ Today shows 😢 emoji
  ✓ Entry visible in day view

Evidence: Screenshot
```

#### Test Case 1.5: Navigate to Past Date (Read-Only)
```
Preconditions:
  - Entry exists on May 10
  - Current date: May 15

Steps:
  1. Tap on May 10 (past date)
  2. View entry for May 10
  3. Tap entry to see details
  4. Try to edit text

Expected:
  ✓ Entry shows in detail view
  ✓ No "Edit" button visible
  ✓ Screen shows "View Memory" header
  ✓ Cannot modify entry

Evidence: Screenshot
```

---

### Screen 2: MOMENT (Entry List)

**Navigation:** Bottom nav second icon  
**Purpose:** View all entries with search/filter

#### Test Case 2.1: Display All Entries
```
Preconditions:
  - 5+ entries created across different dates
  - Moment screen opened

Steps:
  1. View list of all entries
  2. Scroll to see more
  3. Entries sorted by date (newest first)

Expected:
  ✓ All 5+ entries visible
  ✓ Newest entry at top
  ✓ Each card shows emotion, date, text, tags
  ✓ Smooth scrolling

Evidence: Screenshot
```

#### Test Case 2.2: Search Entries
```
Preconditions:
  - Entry 1: "Had a great meeting"
  - Entry 2: "Feeling tired"
  - Entry 3: "Great workout"

Steps:
  1. Tap search box
  2. Type "great"
  3. View results

Expected:
  ✓ Shows Entry 1 + Entry 3 (contains "great")
  ✓ Entry 2 not shown
  ✓ Search is case-insensitive
  ✓ Results update as typing

Evidence: Screenshot
```

#### Test Case 2.3: Filter by Tag
```
Preconditions:
  - 5 entries with various tags
  - "work" tag on 2 entries
  - "fitness" tag on 1 entry

Steps:
  1. Go to tag filter dropdown
  2. Select "work"
  3. View filtered results

Expected:
  ✓ Only 2 "work" entries show
  ✓ Other entries hidden
  ✓ Entry count shows "2"
  ✓ Can select multiple tags

Evidence: Screenshot
```

#### Test Case 2.4: Combine Search + Filter
```
Preconditions:
  - Entry 1: "Team meeting" + tag:work
  - Entry 2: "Solo work" + tag:work
  - Entry 3: "Great meeting" + tag:fitness

Steps:
  1. Type "meeting" in search
  2. Select filter tag:work
  3. View results

Expected:
  ✓ Shows only Entry 1 (has "meeting" AND tag:work)
  ✓ Entry 3 hidden (doesn't have work tag)
  ✓ Entry 2 hidden (doesn't have "meeting")

Evidence: Screenshot
```

#### Test Case 2.5: Share Entry
```
Preconditions:
  - Entry exists: "Great day at work"
  - Moment screen visible

Steps:
  1. Tap entry card
  2. EntryDetailScreen opens
  3. Tap "Share" button
  4. Choose "Messages" or "Copy"

Expected:
  ✓ Share sheet appears
  ✓ Can share via Messages, Mail, etc.
  ✓ Shared entry includes emotion + text + date
  ✓ No data loss on share

Evidence: Screenshot
```

---

### Screen 3: ROUTINE (Habit Tracker)

**Navigation:** Bottom nav third icon  
**Purpose:** Create and track daily routines

#### Test Case 3.1: View Build Tab (All Routines)
```
Preconditions:
  - 3 routines created: Daily, Weekly, Scheduled
  - Routine screen opened

Steps:
  1. Tap "Build" tab
  2. View all routines list
  3. Scroll to see all

Expected:
  ✓ All 3 routines visible
  ✓ Each shows: name, frequency, last completion
  ✓ Icons visible (⭐ or category emoji)
  ✓ No crashes on render

Evidence: Screenshot
```

#### Test Case 3.2: View Do Tab (Today's Routines)
```
Preconditions:
  - Daily routine: "Morning Jog"
  - Weekly routine (Mon/Wed/Fri): "Gym"
  - Today is Wednesday

Steps:
  1. Tap "Do" tab
  2. View today's routines

Expected:
  ✓ Shows "Morning Jog" (daily)
  ✓ Shows "Gym" (today is Wed)
  ✓ Does NOT show other weekly routines
  ✓ Checkboxes unchecked

Evidence: Screenshot
```

#### Test Case 3.3: Mark Routine Complete
```
Preconditions:
  - "Morning Jog" in Do tab, unchecked

Steps:
  1. Tap checkbox next to "Morning Jog"
  2. Observe immediate feedback

Expected:
  ✓ Checkbox marked immediately
  ✓ Visual indicator (strikethrough or color change)
  ✓ Timestamp recorded (verify in DB)
  ✓ Completion appears in Insights

Evidence: Screenshot
```

#### Test Case 3.4: Create New Routine
```
Preconditions:
  - Routine screen visible
  - Tap FAB to add

Steps:
  1. Enter name: "Evening Yoga"
  2. Select frequency: "Daily"
  3. Tap Save

Expected:
  ✓ Routine added to Build tab
  ✓ Appears in Do tab (for today)
  ✓ Can toggle completion
  ✓ Data persists after app restart

Evidence: Screenshot
```

#### Test Case 3.5: Routine Category Auto-Detection
```
Preconditions:
  - Create routine: "Morning Fitness"

Steps:
  1. Check routine icon in Build tab
  2. Routine name contains "fitness" keyword

Expected:
  ✓ Icon shows fitness category emoji (💪)
  ✓ Or auto-detected category displays
  ✓ Fallback to ⭐ if no match

Evidence: Screenshot
```

#### Test Case 3.6: View Reflect Tab
```
Preconditions:
  - Completed routines exist
  - Reflect tab accessible

Steps:
  1. Tap "Reflect" tab
  2. View routine completion summary
  3. Scroll to see charts

Expected:
  ✓ Shows completion rate (%)
  ✓ Charts render without errors
  ✓ Statistics match completed entries
  ✓ Data up-to-date for today

Evidence: Screenshot
```

---

### Screen 4: INSIGHTS (Analytics & Charts)

**Navigation:** Bottom nav fourth icon  
**Purpose:** View yearly trends and AI insights

#### Test Case 4.1: Emoji Jar Carousel
```
Preconditions:
  - Entries from 2024, 2025, 2026
  - Insights screen opened

Steps:
  1. View emoji jar section
  2. Scroll left/right to change years
  3. View 2026 jar
  4. Scroll to 2025

Expected:
  ✓ Jar displays emojis from selected year
  ✓ Year indicator shows (2026)
  ✓ Smooth carousel scrolling
  ✓ Overflow badge shows "+5" if >30 emojis

Evidence: Screenshot
```

#### Test Case 4.2: Summary Cards (Hero Stats)
```
Preconditions:
  - 10+ entries in 2026
  - 3+ completed routines
  - Insights screen visible

Steps:
  1. View top summary cards
  2. Check displayed metrics
  3. Scroll down for more

Expected:
  ✓ Shows: Total Entries, Entries This Week, Routines Completed
  ✓ Numbers accurate
  ✓ Cards readable and visually distinct
  ✓ No missing data

Evidence: Screenshot
```

#### Test Case 4.3: Heatmap (Mood Distribution)
```
Preconditions:
  - Mixed emotions across month
  - Insights screen visible

Steps:
  1. Scroll to heatmap section
  2. View color-coded mood grid
  3. Tap individual cell

Expected:
  ✓ Grid shows May 2026
  ✓ Colors represent moods (red=sad, green=happy)
  ✓ Cells with no entry are blank
  ✓ No crashes on interaction

Evidence: Screenshot
```

#### Test Case 4.4: Mood Trend Line Chart
```
Preconditions:
  - 30+ entries across 4 weeks
  - Various emotions logged
  - Insights screen visible

Steps:
  1. Scroll to mood trend section
  2. View line chart
  3. Tap legend to filter

Expected:
  ✓ Chart shows mood trend over time
  ✓ Line smooth and readable
  ✓ X-axis shows dates, Y-axis shows mood score
  ✓ Legend shows emotion colors

Evidence: Screenshot
```

#### Test Case 4.5: AI-Generated Insights
```
Preconditions:
  - Paid entitlement active
  - 20+ entries from past month
  - Insights screen visible

Steps:
  1. Scroll to AI Insights section
  2. View generated insight text
  3. Tap to read full reflection

Expected:
  ✓ AI insight displays (not "Insights generating...")
  ✓ Text is thoughtful and relevant
  ✓ References actual data (mood, routines, tags)
  ✓ No errors or truncation

Evidence: Screenshot
```

#### Test Case 4.6: Writing Stats Card
```
Preconditions:
  - 15+ entries with varying text length
  - Insights screen visible

Steps:
  1. Scroll to Writing Stats section
  2. View cards: Avg Words, Active Days, Peak Hour

Expected:
  ✓ Avg Words shows accurate count
  ✓ Active Days shows # days with entries
  ✓ Peak Hour shows time of most entries
  ✓ Data matches actual entries

Evidence: Screenshot
```

---

### Screen 5: SETTINGS

**Navigation:** Bottom nav fifth icon  
**Purpose:** Configure app, export/import, legal

#### Test Case 5.1: Language Toggle
```
Preconditions:
  - Settings screen opened
  - Language currently English

Steps:
  1. Find language toggle
  2. Switch to 中文 (Chinese)
  3. Settings screen updates
  4. Go back to Home screen

Expected:
  ✓ All Settings labels in Chinese
  ✓ Home screen also in Chinese
  ✓ Toggle back to English works
  ✓ Change persists after restart

Evidence: Screenshot
```

#### Test Case 5.2: Theme Selection
```
Preconditions:
  - Settings screen opened
  - Currently on Light theme

Steps:
  1. Find theme selector
  2. Switch to Dark mode
  3. Observe entire app
  4. Switch to Light mode

Expected:
  ✓ App background color changes
  ✓ Text color inverts
  ✓ Cards and buttons adjust colors
  ✓ Theme persists after restart

Evidence: Screenshot
```

#### Test Case 5.3: View Entitlement Status
```
Preconditions:
  - Settings screen opened
  - In different entitlement states

Steps:
  1. Scroll to AI section
  2. View entitlement banner
  3. Check status text

Expected:
  ✓ Preview state: "Free Trial - 3 AI per day"
  ✓ Restricted state: "Upgrade to unlock AI"
  ✓ Paid state: "Pro - Unlimited AI"
  ✓ Status matches actual state

Evidence: Screenshot
```

#### Test Case 5.4: Export Data (Backup)
```
Preconditions:
  - 5+ entries exist
  - Settings screen opened

Steps:
  1. Tap "Backup" button
  2. Choose location (iCloud / Files)
  3. Wait for completion
  4. Verify file created

Expected:
  ✓ Progress dialog shows during export
  ✓ File saved as ZIP archive
  ✓ File includes all entries + routines + tags
  ✓ No data corruption

Evidence: Screenshot
```

#### Test Case 5.5: Restore Data
```
Preconditions:
  - Backup file exists
  - Settings screen opened

Steps:
  1. Tap "Restore" button
  2. Select backup file
  3. Confirm restore
  4. Wait for completion

Expected:
  ✓ Preview shows # entries to restore
  ✓ Progress dialog during restore
  ✓ All data recovered
  ✓ No duplicate entries

Evidence: Screenshot
```

#### Test Case 5.6: View Legal Documents
```
Preconditions:
  - Settings screen opened

Steps:
  1. Tap "Privacy Policy"
  2. Read content
  3. Scroll to bottom
  4. Go back, tap "Terms of Service"

Expected:
  ✓ Legal docs display in scrollable view
  ✓ Text is fully readable
  ✓ Both languages available (EN/ZH)
  ✓ No missing sections

Evidence: Screenshot
```

#### Test Case 5.7: About Section
```
Preconditions:
  - Settings screen opened
  - App version: 1.1.0+37

Steps:
  1. Scroll to About section
  2. View version number
  3. Tap version 5 times quickly

Expected:
  ✓ Shows "Version 1.1.0 (Build 37)"
  ✓ Tapping version 5x cycles entitlement state
  ✓ Toast shows current state: "Preview" / "Restricted" / "Paid"
  ✓ Debug menu doesn't appear in production

Evidence: Screenshot
```

---

## Feature-Specific Tests

### Feature A: AI Reflection (LLM Integration)

#### Test A.1: Get AI Reflection on Entry
```
Preconditions:
  - Paid entitlement active
  - Entry exists: "Had a difficult conversation with my manager"
  - EntryDetailScreen open

Steps:
  1. Tap "Get AI Reflection" button
  2. AssistantScreen opens
  3. Entry text pre-loaded in context
  4. Send message or wait for auto-response
  5. Review generated reflection

Expected:
  ✓ AI generates thoughtful reflection
  ✓ Response references entry content
  ✓ No hallucinations or irrelevant text
  ✓ Response arrives within 10 seconds
  ✓ Can scroll to read full response

Evidence: Screenshot
```

#### Test A.2: Save Reflection as New Entry
```
Preconditions:
  - AI reflection generated
  - AssistantScreen showing response

Steps:
  1. Tap "Save Reflection" button
  2. Reflection saved as new entry
  3. Go to Moment screen
  4. Search for reflection content

Expected:
  ✓ New entry created with reflection text
  ✓ Tagged with "tag_synthesis" automatically
  ✓ Visible in Moment list and Calendar
  ✓ Original entry unchanged

Evidence: Screenshot
```

#### Test A.3: Multi-Turn Conversation
```
Preconditions:
  - AssistantScreen open
  - In Paid entitlement

Steps:
  1. Send message: "I'm feeling overwhelmed"
  2. Wait for response
  3. Send follow-up: "How can I manage this?"
  4. AI responds contextually
  5. Send 3rd message

Expected:
  ✓ AI remembers previous messages
  ✓ Responses are contextually relevant
  ✓ Conversation history visible in thread
  ✓ No context loss between turns

Evidence: Screenshot
```

#### Test A.4: AI Disabled in Preview Mode
```
Preconditions:
  - Entitlement state: Preview
  - 1 AI message used today

Steps:
  1. Try to send 4th message in AssistantScreen
  2. Observe error/quota message

Expected:
  ✓ Message: "3 AI messages per day limit reached"
  ✓ Can't send more until tomorrow
  ✓ Quota resets at midnight

Evidence: Screenshot
```

---

### Feature B: Backup & Restore

#### Test B.1: Export Creates Valid ZIP
```
Preconditions:
  - 5 entries, 2 routines, 3 custom tags
  - Settings → Export → Backup tapped

Steps:
  1. Backup completes
  2. Open Files app (iOS) or Downloads (Android)
  3. Verify ZIP file exists
  4. Extract ZIP on computer
  5. Open JSON files

Expected:
  ✓ ZIP file created (name: blinking_backup_YYYY_MM_DD.zip)
  ✓ Contains: entries.json, routines.json, tags.json
  ✓ JSON is valid and readable
  ✓ File size ~100KB for 5 entries

Evidence: Screenshot (file manager)
```

#### Test B.2: Restore Large Backup (100+ Entries)
```
Preconditions:
  - Backup with 100+ entries exists
  - Settings → Restore → file selected

Steps:
  1. Tap "Restore"
  2. Preview shows "~100 entries to restore"
  3. Wait for progress to complete
  4. Check no OOM error

Expected:
  ✓ Restore completes without crash
  ✓ All 100+ entries recovered
  ✓ Progress dialog smooth
  ✓ Time: <60 seconds for 100 entries

Evidence: Screenshot
```

#### Test B.3: Restore Doesn't Create Duplicates
```
Preconditions:
  - Entry exists: "Test entry"
  - Backup includes same entry
  - Restore in progress

Steps:
  1. Complete restore
  2. Go to Moment screen
  3. Search for "Test entry"
  4. Count results

Expected:
  ✓ Only 1 "Test entry" visible
  ✓ No duplicates created
  ✓ Timestamps match original

Evidence: Screenshot
```

---

### Feature C: Bilingual Support (EN ↔ ZH)

#### Test C.1: Onboarding in Chinese
```
Preconditions:
  - Fresh install
  - Device language: 中文

Steps:
  1. Launch app
  2. Onboarding appears
  3. Read screen 1, 2, 3
  4. All text in Chinese

Expected:
  ✓ Onboarding fully translated
  ✓ No English text visible
  ✓ Terminology accurate (e.g., "日常" for Routine)
  ✓ "Continue" button label in Chinese

Evidence: Screenshot
```

#### Test C.2: Switch Language Mid-Session
```
Preconditions:
  - App in English
  - Created entry: "Good day"
  - 5 routines configured

Steps:
  1. Settings → Language → Switch to Chinese
  2. Home screen reloads
  3. Entry text preserved
  4. Labels all in Chinese
  5. Go through all 5 screens

Expected:
  ✓ All UI labels in Chinese
  ✓ User data unchanged
  ✓ Tags display in Chinese
  ✓ Emotion labels in Chinese
  ✓ Switch back to English works

Evidence: Screenshot (all 5 screens in both languages)
```

#### Test C.3: Locale-Specific Content
```
Preconditions:
  - Language: English

Steps:
  1. Settings → Tags
  2. Verify tag names (work, fitness, health)
  3. Switch language to Chinese
  4. Tags display in Chinese

Expected:
  ✓ Tags auto-translated or native
  ✓ Category keywords work in both languages
  ✓ Routine names searchable in both languages

Evidence: Screenshot
```

#### Test C.4: Date/Time Formatting
```
Preconditions:
  - Language: English
  - Entry date: May 15, 2026, 2:30 PM

Steps:
  1. View entry in Moment
  2. Check date format (MM/DD/YYYY)
  3. Switch language to Chinese
  4. Entry date now shown as (2026年5月15日)

Expected:
  ✓ English: "May 15, 2026 at 2:30 PM"
  ✓ Chinese: "2026年5月15日 下午2:30"
  ✓ Time zone preserved

Evidence: Screenshot
```

---

## Edge Cases & Error Scenarios

### Edge Case E.1: Very Long Entry Text
```
Preconditions:
  - Prepare 1000+ character text

Steps:
  1. Create entry with very long text
  2. Save entry
  3. View in Moment
  4. Tap to see full text

Expected:
  ✓ Text saves without truncation
  ✓ Full text visible in detail view
  ✓ Preview in list shows first 200 chars + "..."
  ✓ No layout issues (text doesn't overflow)

Evidence: Screenshot
```

### Edge Case E.2: Unicode Characters (Emoji, Chinese)
```
Preconditions:
  - Create entry with mix of content

Steps:
  1. Type: "今天很开心 😊 Had great weather! 🌞"
  2. Save entry
  3. Search for "今天"
  4. Verify emoji preserved

Expected:
  ✓ All characters save correctly
  ✓ No corruption of unicode
  ✓ Search works with Chinese characters
  ✓ Emoji renders correctly

Evidence: Screenshot
```

### Edge Case E.3: Empty Search Query
```
Preconditions:
  - Moment screen with 10 entries
  - Search box focused

Steps:
  1. Tap search box
  2. Type space, then clear
  3. Observe behavior

Expected:
  ✓ Shows all entries (no filtering)
  ✓ Whitespace-only queries treated as empty
  ✓ Clear search instantly shows all

Evidence: Screenshot
```

### Edge Case E.4: Concurrent Operations
```
Preconditions:
  - Create entry + mark routine complete simultaneously

Steps:
  1. Add entry in AddEntryScreen
  2. Don't close screen, go to Routine
  3. Mark routine complete
  4. Return to AddEntry, save

Expected:
  ✓ Both operations succeed
  ✓ No data loss
  ✓ No race conditions
  ✓ Data consistent

Evidence: Screenshot
```

### Edge Case E.5: Create Entry on Deleted Date
```
Preconditions:
  - Try to create entry with future date (May 31, when max date is May 30)

Steps:
  1. Attempt to manually enter date beyond today + limit
  2. Observe validation

Expected:
  ✓ Date picker limits future dates
  ✓ Cannot select beyond "today"
  ✓ Error message if attempted

Evidence: Screenshot
```

### Error Scenario E.6: Network Timeout During AI Request
```
Preconditions:
  - Turn off WiFi/network
  - AssistantScreen open, paid entitlement

Steps:
  1. Send message
  2. Observe error handling
  3. Turn network back on
  4. Retry

Expected:
  ✓ Shows "Network error" message
  ✓ Retry button available
  ✓ No crash
  ✓ Retry succeeds after network restored

Evidence: Screenshot
```

### Error Scenario E.7: Invalid Backup File
```
Preconditions:
  - Create corrupt ZIP file
  - Settings → Restore → select bad file

Steps:
  1. Tap Restore
  2. Select invalid ZIP
  3. Attempt to restore

Expected:
  ✓ Shows error: "Invalid backup file"
  ✓ No data loss
  ✓ Can try different file
  ✓ No app crash

Evidence: Screenshot
```

---

## Regression Test Suite

### Post-Release: Run These Tests Weekly

Use this subset to verify no regressions:

#### Quick Smoke Test (15 minutes)
- [ ] Launch app, complete onboarding
- [ ] Create entry with emotion + tag
- [ ] Mark routine complete
- [ ] View Insights heatmap
- [ ] Switch language to Chinese and back
- [ ] Search entry by keyword
- [ ] Share entry
- [ ] No crashes

#### IAP Test (10 minutes)
- [ ] Debug toggle to cycle entitlement states
- [ ] Paywall appears in Restricted mode
- [ ] AI reflection unavailable in Preview (3 message limit)
- [ ] AI reflection works in Paid mode
- [ ] Entitlement state persists after app close

#### Backup/Restore Test (15 minutes)
- [ ] Backup 5 entries
- [ ] Delete 2 entries
- [ ] Restore backup
- [ ] Verify all entries recovered
- [ ] No duplicates created

#### Bilingual Test (10 minutes)
- [ ] All UI text visible in English
- [ ] Switch to Chinese, all text visible
- [ ] Entry data preserved during language switch
- [ ] Search works in both languages
- [ ] Date formatting changes by locale

#### Data Integrity Test (10 minutes)
- [ ] Create entry with multiple tags
- [ ] Verify tags persist
- [ ] Create routine, mark complete
- [ ] Verify completion in Insights
- [ ] App restart preserves all data

---

## Bilingual Content Verification

### Screen-by-Screen Checklist

#### HOME (Calendar)
- [ ] "Calendar" / "日历"
- [ ] Day names (Sun-Sat) / (日-土)
- [ ] Month/year header displays correctly
- [ ] Add button accessible

#### MOMENT (Entry List)
- [ ] "Moment" / "时刻"
- [ ] "Search" placeholder / "搜索"
- [ ] Tag filter dropdown
- [ ] "Share" option visible

#### ROUTINE
- [ ] "Routine" / "日常"
- [ ] Tab labels: "Build / Do / Reflect" / "构建 / 今日 / 反思"
- [ ] Add routine button
- [ ] Frequency options (Daily/Weekly/etc)
- [ ] Category emoji displays correctly

#### INSIGHTS
- [ ] "Insights" / "洞察"
- [ ] "Yearly Reflection" / "年度反思"
- [ ] Chart legends in current language
- [ ] "AI Insights" section title
- [ ] Card titles readable

#### SETTINGS
- [ ] "Settings" / "设置"
- [ ] Language toggle
- [ ] Theme selector
- [ ] Backup/Restore buttons
- [ ] Privacy Policy / Terms visible
- [ ] About section

---

## UAT Sign-Off

### Critical Pass/Fail Criteria

#### Must Pass (Blocker Issues)
- [ ] App launches without crash
- [ ] Core CRUD works (create/read/update entries)
- [ ] Routines track daily completion
- [ ] Backup/Restore preserves data
- [ ] IAP purchase completes
- [ ] AI features work on Paid tier
- [ ] Bilingual UI switches correctly
- [ ] No data loss on app restart

#### Should Pass (High Priority)
- [ ] Calendar displays current month
- [ ] Insights charts render without errors
- [ ] Search filters entries correctly
- [ ] Tags persist and display
- [ ] Entitlement state machine works
- [ ] Emoji jar shows correct emotions
- [ ] Share functionality works

#### Nice to Have (Low Priority)
- [ ] Smooth animations
- [ ] Fast loading times
- [ ] Intuitive UI flow
- [ ] Beautiful dark mode
- [ ] Responsive on iPad

### Test Results Summary Template

```
═══════════════════════════════════════════════════════════════
                    UAT TEST RESULTS SUMMARY
═══════════════════════════════════════════════════════════════

App Version: 1.1.0+37
Test Date: _____________
Tested By: _____________
Device(s): _____________
iOS Version: _____________

CRITICAL PATHS
──────────────
Onboarding → Trial → Purchase    [PASS] [FAIL]
Entry Creation + AI Reflection   [PASS] [FAIL]
Routine Creation + Tracking      [PASS] [FAIL]
Backup + Restore                 [PASS] [FAIL]
Bilingual Switching              [PASS] [FAIL]

SCREEN RENDERING
────────────────
Home (Calendar)                  [PASS] [FAIL]
Moment (Entry List)              [PASS] [FAIL]
Routine (Habit Tracker)          [PASS] [FAIL]
Insights (Analytics)             [PASS] [FAIL]
Settings                         [PASS] [FAIL]

FEATURES
────────
AI Reflection (LLM)              [PASS] [FAIL]
RevenueCat IAP                   [PASS] [FAIL]
Backup/Restore                   [PASS] [FAIL]
Search + Filter                  [PASS] [FAIL]
Theme Switching                  [PASS] [FAIL]

CRASHES
───────
Critical Crashes: _____
Minor Issues: _____
Data Loss: [YES] [NO]

SIGN-OFF
────────
Ready for Production? [YES] [NO]

Issues Blocking Release:
  1. _______________
  2. _______________
  3. _______________

Additional Notes:
  _______________________________________________
  _______________________________________________

Tester Signature: ________________  Date: _______
Product Lead: ________________  Date: _______
```

---

## Test Case Template (For Additional Tests)

```
╔═════════════════════════════════════════════════════════════╗
║                    TEST CASE TEMPLATE                       ║
╚═════════════════════════════════════════════════════════════╝

TEST CASE ID: TC_[Screen]_[Feature]_[Number]
SCREEN: [Home / Moment / Routine / Insights / Settings]
FEATURE: [Feature Name]
PRIORITY: [Critical / High / Medium / Low]
AUTHOR: [Your Name]
DATE: [Date Created]

────────────────────────────────────────────────────────────

PRECONDITIONS:
  - ________________________________
  - ________________________________

TEST STEPS:
┌─────┬──────────────────────────────┬──────────────────────┐
│ #   │ Action                       │ Expected Result      │
├─────┼──────────────────────────────┼──────────────────────┤
│ 1   │                              │                      │
│ 2   │                              │                      │
│ 3   │                              │                      │
└─────┴──────────────────────────────┴──────────────────────┘

EXPECTED OUTCOME:
  ✓ ___________________
  ✓ ___________________
  ✓ ___________________

PASS CRITERIA:
  - All expected results achieved
  - No crashes
  - Data persists

BILINGUAL NOTES:
  - Test in English: ______
  - Test in Chinese: ______

EVIDENCE REQUIRED:
  - [ ] Screenshot 1: ___________
  - [ ] Screenshot 2: ___________
  - [ ] Screenshot 3: ___________

ACTUAL RESULT:
  [ ] PASS
  [ ] FAIL (reason: _______________)

NOTES:
  _______________________________________________
  _______________________________________________

TESTER: ________________  DATE: _______
```

---

## End of UAT Test Plan

**Total Test Cases:** 50+  
**Estimated Execution Time:** 8-10 hours (first run)  
**Estimated Time Per Week:** 2 hours (regression tests)

**Next Steps:**
1. Print this document or open on tablet
2. Create test results spreadsheet
3. Assign testers to screens
4. Execute tests sequentially
5. Document all findings
6. Track blockers vs. nice-to-haves
7. Generate sign-off report

---

*UAT Plan Version: 1.0*  
*Created: May 2026*  
*Last Updated: May 15, 2026*
