# Coeval App - Peer Assessment Mobile Application

Flutter application for peer evaluation in collaborative university projects, built with Clean Architecture and GetX.

## Prerequisites

- Flutter SDK 3.11.1 or higher
- Dart SDK 3.11.1 or higher
- Android Studio / Xcode for platform-specific builds
- Git

## Getting Started After Cloning

### 1. Clone the Repository
```bash
git clone <https://github.com/MatizS27/coeval.git>
cd coeval
```

### 2. Verify Flutter Installation
```bash
# Check Flutter is properly installed
flutter doctor

# Should show Flutter SDK, Dart SDK, and platform tools installed
# Fix any issues shown before proceeding
```

### 3. Install Project Dependencies
```bash
# This downloads all packages from pubspec.yaml
flutter pub get
```

### 4. Verify Everything Works
```bash
# Run code analysis to check for errors
flutter analyze

# Run tests to ensure everything is working
flutter test
```

### 5. Run the Application
```bash
# Development mode (hot reload enabled)
flutter run

# Specific platform
flutter run -d android
flutter run -d ios
flutter run -d chrome

# List available devices
flutter devices
```

### 6. First Time Setup (if needed)
```bash
# If you encounter any issues, clean and rebuild
flutter clean
flutter pub get
flutter run
```

### 3. Build for Production
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Project Structure (Clean Architecture)

```
lib/
├── core/                 # Shared resources across all layers
│   ├── constants/        # App-wide constants (API URLs, config values)
│   ├── network/          # HTTP client and network utilities
│   ├── theme/            # App theme and styling
│   └── utils/            # Helper functions and utilities
│
├── data/                 # Data Layer (Frameworks & Drivers)
│   ├── datasources/      # Remote/Local data sources (API calls, DB)
│   ├── models/           # Data models with JSON serialization
│   └── repositories/     # Repository implementations (bridge to domain)
│
├── domain/               # Domain Layer (Business Logic)
│   ├── entities/         # Business objects (pure Dart classes)
│   ├── repositories/     # Repository contracts (interfaces)
│   └── usecases/         # Business use cases (app actions)
│
├── presentation/         # Presentation Layer (UI)
│   ├── auth/             # Authentication module
│   │   ├── bindings/     # Dependency injection bindings
│   │   ├── controllers/  # GetX controllers (state management)
│   │   └── views/        # UI screens/widgets
│   └── home/             # Home module
│       ├── bindings/
│       ├── controllers/
│       └── views/
│
└── main.dart             # App entry point
```

## Architecture Layers

### 1. **Core Layer**
Shared utilities and resources used across the app.

**Files Overview:**
- `constants/app_constants.dart` - API endpoints, configuration values
- `network/api_client.dart` - HTTP client wrapper (REST API calls)
- `theme/app_theme.dart` - Material theme definitions
- `utils/util.dart` - Common helper functions

### 2. **Domain Layer** (Business Logic)
Pure Dart code with no framework dependencies.

**Files Overview:**
- `entities/user.dart` - User business object
- `repositories/auth_repository.dart` - Authentication contract
- `usecases/login_use_case.dart` - Login business logic

**Principles:**
- Framework-independent
- Testable in isolation
- Contains business rules

### 3. **Data Layer** (External Interfaces)
Handles data from APIs, databases, and external sources.

**Files Overview:**
- `datasources/auth_remote_datasource.dart` - API authentication calls
- `models/user_model.dart` - User data model with JSON mapping
- `repositories/auth_repository_impl.dart` - Repository implementation

**Responsibilities:**
- Data transformation (JSON ↔ Models)
- API communication
- Local storage operations

### 4. **Presentation Layer** (UI)
Flutter widgets and state management with GetX.

**Structure per Module:**
- `bindings/` - Dependency injection setup for controllers
- `controllers/` - GetX controllers managing UI state
- `views/` - Flutter widgets and screens


## Data Flow

```
User Action (View)
    ↓
Controller (Presentation)
    ↓
UseCase (Domain)
    ↓
Repository Interface (Domain)
    ↓
Repository Implementation (Data)
    ↓
DataSource (Data)
    ↓
External API/Database
```

## Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  get: ^4.7.3                    # State management & routing

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0          # Dart linting rules
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## ⚠️ Troubleshooting Common Issues

### "Flutter command not found"
```bash
# Add Flutter to your PATH
export PATH="$PATH:`pwd`/flutter/bin"
# Or follow: https://docs.flutter.dev/get-started/install
```

### "Waiting for another flutter command to release the startup lock"
```bash
# Remove the lock file
rm -rf /path/to/flutter/bin/cache/lockfile
```

### Dependency conflicts or build errors
```bash
# Clean everything and reinstall
flutter clean
flutter pub cache repair
flutter pub get
```

### Android build fails
```bash
# Update Gradle wrapper
cd android
./gradlew wrapper --gradle-version=8.0
cd ..
flutter clean
flutter build apk
```

### iOS build fails
```bash
# Clean iOS build
cd ios
rm -rf Pods/ Podfile.lock
pod install
cd ..
flutter clean
flutter build ios
```

### Hot reload not working
- Press `R` in terminal for hot reload
- Press `Shift + R` for hot restart
- Or restart the app: `flutter run`

## 🔧 Common Commands

```bash
# Clean build cache
flutter clean

# Analyze code
flutter analyze

# Format code
dart format lib/

# Check outdated packages
flutter pub outdated

# Upgrade packages
flutter pub upgrade
```

## Adding New Features

Follow Clean Architecture principles:

1. **Create Entity** (domain/entities/)
2. **Define Repository Contract** (domain/repositories/)
3. **Implement Use Case** (domain/usecases/)
4. **Create Data Model** (data/models/)
5. **Implement Repository** (data/repositories/)
6. **Create DataSource** (data/datasources/)
7. **Build UI** (presentation/feature_name/)
   - Create binding
   - Create controller
   - Create views

## Contributing

1. Follow Clean Architecture principles
2. Use GetX for state management
3. Write tests for business logic
4. Follow Dart style guide
5. Document complex logic

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [GetX Documentation](https://pub.dev/packages/get)
- [Clean Architecture Guide](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Project Documentation](../README.md)

## License

Academic project - Universidad context
