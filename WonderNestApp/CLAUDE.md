# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
WonderNest is a child-safety-first Flutter application with a KTOR backend. The app defaults to Kid Mode with PIN-protected Parent Mode access, featuring audio monitoring, content filtering, and COPPA-compliant parental controls.

## Build and Development Commands

### Flutter App (WonderNestApp/)
```bash
# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run --device-id A265F109-BDBF-4F51-A86F-DE5C4A278141

# Run on Android emulator
flutter run --device-id emulator-5554

# Run on Chrome (web)
flutter run -d chrome

# Build for production
flutter build ios --release
flutter build apk --release

# Clean build artifacts
flutter clean

# Analyze code for issues
flutter analyze --no-fatal-infos

# Run tests
flutter test

# Update iOS pods (if pod issues)
cd ios && pod install && cd ..

# Format code
dart format lib/
```

### Backend (Wonder Nest Backend/)
```bash
# Start backend services (Docker)
docker-compose up -d

# Run backend locally
./gradlew run

# Build backend
./gradlew build

# Run backend tests
./gradlew test

# Database setup
./setup-database.sh

# Verify database connection
./verify-database.sh

# View logs
docker-compose logs -f backend
```

## Architecture Overview

### Frontend (Flutter)
The app uses a **kid-mode-first design** where the app always starts in kid mode and requires PIN authentication to access parent features.

**State Management**: Riverpod with StateNotifier pattern
- `AuthProvider` - Authentication state and user session
- `AppModeProvider` - Manages Kid/Parent mode switching
- All providers in `/lib/providers/`

**Navigation**: GoRouter with protected routes
- Auth routes: `/welcome`, `/signup`, `/login`, `/onboarding`
- Parent routes require PIN: `/parent-dashboard`, `/parent-controls`
- Kid routes: `/child-home`, `/game`
- Router configuration in `main.dart:74-257`

**Security Flow**:
1. App launches in Kid Mode by default
2. Parent mode requires PIN verification (`/pin-entry`)
3. Parent mode auto-locks after 15 minutes of inactivity
4. Tokens stored in FlutterSecureStorage
5. Audio processing happens on-device only

**API Integration**:
- `ApiService` (`/lib/core/services/api_service.dart`) - Main API client
- `MockApiService` - Fallback when backend unavailable
- All API calls use JWT tokens in headers
- Response structure: `{success: bool, data: {...}}`

### Backend (KTOR)
**Tech Stack**: Kotlin, KTOR 3.0, PostgreSQL, Exposed ORM

**Database Schema**:
- Schema: `core` (users, sessions, families, children)
- Schema: `content` (filters, whitelist, activity)
- Schema: `compliance` (coppa_consent, audit_logs)

**Key API Endpoints**:
- `/api/v1/auth/parent/register` - Parent signup
- `/api/v1/auth/parent/login` - Parent login  
- `/api/v1/auth/parent/verify-pin` - PIN verification for mode switching
- `/api/v1/family/children` - Child profile management
- `/api/v1/content/filters` - Content filtering rules
- `/api/v1/activity/track` - Activity monitoring

**Authentication**:
- JWT tokens with refresh mechanism
- PIN stored with bcrypt hashing
- Session management with automatic expiration

## Critical Implementation Details

### Audio Processing (Privacy-First)
- **No raw audio leaves device** - only processed transcriptions
- Edge-based speech recognition using `speech_to_text` package
- Keyword detection happens locally
- Implementation in `/lib/services/audio_processing_service.dart`

### COPPA Compliance
- Parental consent required for data collection
- Age verification during child profile creation
- Data deletion rights implementation
- Consent flow in `/lib/screens/coppa/coppa_consent_screen.dart`

### Content Filtering
- Whitelisted domains only for web content
- YouTube Kids API integration
- Age-appropriate content filtering
- Real-time subtitle/caption tracking for vocabulary exposure

### Mini-Game Framework
- WebView with injected JavaScript for monitoring
- Only whitelisted game URLs allowed
- Progress tracking and parental visibility
- Implementation in `/lib/screens/games/mini_game_framework.dart`

## Common Development Tasks

### Adding a New Screen
1. Create screen in `/lib/screens/[category]/`
2. Add route in `main.dart` router configuration
3. Update navigation logic if it's a protected route
4. Add to appropriate provider if it needs state management

### Adding a New API Endpoint
1. Define endpoint in `/lib/core/services/api_service.dart`
2. Add response model in `/lib/models/`
3. Update provider to use new endpoint
4. Add mock response in `MockApiService` for testing

### Implementing a New Provider
1. Create provider file in `/lib/providers/`
2. Use StateNotifier pattern for complex state
3. Add provider to ProviderScope in `main.dart`
4. Document state transitions

## Testing Approach

### Authentication Flow Testing
1. Backend must be running (`docker-compose up -d`)
2. Or app will use MockApiService automatically
3. Test accounts: Use any email/password in mock mode
4. Real backend: Check `API_SPECIFICATIONS.md` for test credentials

### Kid Mode Testing
- App should start in kid mode
- Test voice commands (requires microphone permission)
- Verify content filtering works
- Check that parent features are inaccessible

### Parent Mode Testing
- Enter PIN (mock mode: any 6 digits work)
- Verify dashboard shows analytics
- Test parental controls
- Check auto-lock after timeout

## Known Issues & Solutions

### Provider Not Found Errors
- App uses Riverpod, not Provider package
- All screens should use `ConsumerWidget` or `ConsumerStatefulWidget`
- Access providers with `ref.watch()` or `ref.read()`

### Navigation Not Working
- Check that route is defined in `main.dart`
- Verify redirect logic isn't blocking the route
- Ensure authentication state is properly set

### iOS Build Issues
- Run `cd ios && pod install`
- Check that all permissions are in Info.plist
- Verify Swift version compatibility

### Backend Connection Issues
- App automatically falls back to MockApiService
- Check Docker is running: `docker ps`
- Verify database is accessible: `./verify-database.sh`
- Backend runs on `http://localhost:8080`

## Environment Variables

### Flutter App
Stored in FlutterSecureStorage:
- `auth_token` - JWT access token
- `refresh_token` - JWT refresh token
- `parent_pin` - Hashed PIN
- `onboarding_completed` - Boolean flag
- `parent_account_created` - Boolean flag

### Backend (.env.local)
```
DB_HOST=localhost
DB_PORT=5433
DB_NAME=wondernest_prod
DB_USERNAME=wondernest_app
DB_PASSWORD=wondernest_secure_password_dev
JWT_SECRET=your-secret-key
```

## Deployment Considerations

1. **Security**: Never commit real API keys or secrets
2. **COPPA**: Ensure all child data handling is compliant
3. **Privacy**: Audio processing must remain on-device
4. **Performance**: Target 60fps for kid mode animations
5. **Testing**: Run full test suite before deployment
6. **Monitoring**: Set up crash reporting and analytics (parent consent required)