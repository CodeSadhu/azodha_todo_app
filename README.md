# Task Manager - Azodha Assignment

A Flutter-based task management application with offline-first architecture, built as a technical assessment for Azodha's Senior Flutter Developer position.

**Developer:** CodeSadhu  
**Portfolio:** [https://codesadhu.in](https://codesadhu.in)  
**Timeline:** November 19-20, 2024 (2 days)  
**Flutter Version:** 3.35.5

---

## 🎯 Features

### Core Functionality
- **Authentication System** - Secure login with encrypted local storage
- **Task Management** - Create, read, update, delete tasks with real-time UI updates
- **Offline-First Architecture** - Full CRUD operations work without internet connectivity
- **Background Sync** - Automatic synchronization with remote API when connection is available
- **Search & Filter** - Real-time task search with instant results
- **Pull-to-Refresh** - Manual sync trigger for fetching latest data
- **Persistent Storage** - Local caching with Hive for instant app launches

### Technical Highlights
- **Clean Architecture** - Separation of concerns with proper layering (domain, data, presentation)
- **BLoC Pattern** - State management using flutter_bloc with proper event-driven architecture
- **Secure Storage** - Encrypted authentication token storage using flutter_secure_storage
- **Network Awareness** - Smart sync logic that only attempts server operations when online
- **Optimistic Updates** - Instant UI feedback with background sync retry mechanisms
- **Modular Widgets** - Small, reusable components following Flutter best practices

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_bloc | ^9.1.1 | State management with BLoC pattern |
| equatable | ^2.0.7 | Value equality for state comparison |
| flutter_secure_storage | ^9.2.4 | Encrypted credential storage |
| dio | ^5.9.0 | HTTP client for API requests |
| connectivity_plus | ^7.0.0 | Network connectivity detection |
| hive | ^2.2.3 | Fast local NoSQL database |
| hive_flutter | ^1.1.0 | Hive Flutter integration |
| json_annotation | ^4.9.0 | JSON serialization annotations |
| fluttertoast | ^9.0.0 | Toast notifications

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.35.5 or higher
- Android Studio / VS Code with Flutter plugins
- Physical device or emulator

### Installation

1. **Clone the repository**
```bash
   git clone https://github.com/CodeSadhu/azodha_todo_app.git
   cd azodha_todo_app
```

2. **Install dependencies**
```bash
   flutter pub get
```

3. **Run the app**
```bash
   flutter run
```

### Login Credentials
```
Username: admin
Password: admin123
```

---

## 🏗️ Architecture Overview
```
lib/
├── core/
│   └── constants/          # App-wide constants (strings, API endpoints)
├── features/
│   ├── auth/              # Authentication feature
│   │   ├── data/          # Repository & data sources
│   │   └── presentation/  # UI & BLoC
│   └── tasks/             # Task management feature
│       ├── data/          # Models, repositories, domains
│       │   ├── domain/    # Local & remote data sources
│       │   ├── models/    # Task data model
│       │   └── repositories/ # Data orchestration layer
│       └── presentation/  # UI, BLoC, widgets
└── main.dart
```

**Design Patterns:**
- Clean Architecture with feature-based modularization
- BLoC for unidirectional data flow
- Repository pattern for data source abstraction
- Singleton pattern for service instances

---

## 💡 Key Implementation Details

### Offline-First Strategy
The app uses a dual-storage approach:
1. **Local Cache (Hive)** - Primary data source for instant reads
2. **Remote API (JSONPlaceholder)** - Background sync for data consistency

### Task ID Management
- **Server tasks:** IDs 1-200 (from JSONPlaceholder API)
- **User-created tasks:** Timestamp-based IDs (> 1,000,000,000)
- Only server tasks are synced back to the API

### Sync Mechanism
- Immediate local updates for instant UI feedback
- Background sync with exponential retry (3 attempts, 3-second intervals)
- Debounced sync completion notifications
- Network-aware operations (no unnecessary API calls when offline)

---

## 🎓 What I Learned

### Technical Wins
1. **Proper BLoC separation** - Keeping business logic completely separate from UI was crucial for maintainability
2. **Offline-first complexity** - Managing dual data sources (local + remote) requires careful synchronization logic
3. **State management at scale** - Handling multiple concurrent syncs with proper debouncing and retry mechanisms
4. **Mock API constraints** - Working within JSONPlaceholder's limitations taught me creative problem-solving

### Architectural Insights
- Clean architecture pays off even in small projects - feature folders made navigation and debugging much easier
- Repository pattern is essential for abstracting data source complexity from business logic
- Equatable is a lifesaver for proper state comparison in BLoC

---

## 🐛 Known Issues & Pitfalls

### The Sync Toast Saga
Attempted to show a "Synced" toast notification when background sync completes. Hit multiple roadblocks:

1. **Initial approach:** Icon in AppBar showing sync status (syncing → synced → hidden)
   - **Problem:** State updates weren't triggering UI rebuilds despite proper Equatable props
   - **Root cause:** Timing issues with state emission and BlocBuilder refresh cycles

2. **Second approach:** Direct Fluttertoast call from BLoC
   - **Problem:** `MissingPluginException` - plugin not initialized in BLoC context
   - **Learning:** Never trigger UI actions directly from business logic layer

3. **Final approach:** BlocListener with state flag
   - **Implementation:** Added `showSyncedToast` boolean to state, listener in UI layer shows toast
   - **Status:** Still doesn't work consistently 🤷‍♂️
   - **Hypothesis:** Race condition between state emission and listener attachment, or debounce timing issues

**Takeaway:** Sometimes you gotta know when to move on. The core functionality works, and this is a nice-to-have feature that would need more debugging time.

### JSONPlaceholder API Constraints
The mock API has some limitations that made real-world sync challenging:

- **No persistence** - Created/updated tasks don't actually persist on the server
- **Limited ID range** - Only IDs 1-200 are valid for updates/deletes
- **Rate limiting** - Multiple rapid requests can fail
- **No real error handling** - API returns 200 OK even for invalid operations

**Workaround:** User-created tasks (timestamp IDs) skip server sync entirely. Only pre-existing server tasks (IDs 1-200) attempt synchronization. This keeps the app functional while acknowledging the API's constraints.

---

## ⏱️ Development Context

This was a 2-day sprint assignment for a Senior Flutter Developer role at Azodha. As a freelancer currently juggling 2 other projects, the timeline was quite tight but manageable. 

**Day 1 (Nov 19):** Architecture setup, authentication, basic CRUD  
**Day 2 & 3 (Nov 20-21):** Offline sync, retry logic, polish, debugging

The app works. It's not perfect, but it demonstrates solid Flutter fundamentals, clean architecture, and problem-solving under constraints. The sync toast issue is annoying, but honestly, I've spent enough time on it. Everything else should work.

If you're reading this and still want to go through the code, feel free to. The core architecture is sound, and most features work as expected.

---

## 📝 License

Copyright (c) 2025 CodeSadhu

---