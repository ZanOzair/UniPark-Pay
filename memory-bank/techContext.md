# Technical Context - UPDATED & CLARIFIED

## Core Dependencies

### Authentication & State Management
- **provider**: ^6.1.1 - State management with ChangeNotifier
- **shared_preferences**: ^2.2.2 - Session persistence

### GPS & Mapping
- **flutter_map**: ^6.0.0 - OpenStreetMap integration
- **location**: ^5.0.0 - GPS location and permissions

### Database
- **mysql_client**: ^0.0.27 - MySQL database client

## Development Environment

### Database Setup
- **MySQL 8.0** via Docker
- **Pre-populated schema**: `database/uniparkpay_schema.sql`
- **Configuration**: Gist-based credential management (HTTPS transport security only)
- **Connection**: Pooling with retry logic
- **Security**: Plain text storage, MySQL user-level permissions

### Build Configuration
- **Flutter SDK**: Latest stable
- **Target Platform**: Android (primary)
- **Minimum SDK**: 21
- **Compile SDK**: 34

## Database Security Requirements - CRITICAL

### Query Method Usage Rules
- **executePrepared**: **MANDATORY** for all queries with user input
  - **File**: `lib/database/db_manager.dart:49-60`
  - **Signature**: `executePrepared(String sql, List<dynamic> params)`
  - **Purpose**: Parameterized queries prevent SQL injection
  - **Required for**: INSERT, UPDATE, DELETE with user data
  - **Examples**:
    ```dart
    // ✅ CORRECT - User registration
    await DatabaseManager().executePrepared(
      'INSERT INTO USER (university_id, name, phone_number, role) VALUES (?, ?, ?, ?)',
      [universityId, name, phoneNumber, role]
    );
    
    // ✅ CORRECT - User update
    await DatabaseManager().executePrepared(
      'UPDATE USER SET name = ?, phone_number = ? WHERE id = ?',
      [newName, newPhone, userId]
    );
    ```

- **execute**: **RESTRICTED** to safe SELECT statements only
  - **File**: `lib/database/db_manager.dart:37-47`
  - **Signature**: `execute(String sql, Map<String, dynamic>? params)`
  - **Purpose**: Safe for read-only queries without user input
  - **Allowed for**: Static queries, system lookups
  - **Examples**:
    ```dart
    // ✅ CORRECT - Static query
    await DatabaseManager().execute('SELECT * FROM PARKING_AREA');
    
    // ❌ INCORRECT - User input
    await DatabaseManager().execute(
      'SELECT * FROM USER WHERE university_id = $userId'  // SQL injection risk
    );
    ```

### Security Enforcement
- **Rule 1**: Any query with user input MUST use `executePrepared`
- **Rule 2**: `execute` is only for hardcoded/static SQL statements
- **Rule 3**: User authentication operations MUST use `executePrepared`
- **Rule 4**: Admin user management MUST use `executePrepared`
- **Rule 5**: Payment proof uploads MUST use `executePrepared`

### Parameter Binding
- **Automatic**: mysql_client handles parameter escaping
- **Format**: Positional parameters with `?` placeholders
- **Type Safety**: Dynamic parameter list with proper type checking
- **Validation**: All inputs validated before database operations

## App Routing Architecture - COMPLETE

### Entry Point Routing (lib/main.dart)
- **Initial Route Logic**: 
  - Checks `AuthProvider.isLoggedIn` to determine initial route
  - Logged in: `AppPage(title: 'UniParkPay')` (main app)
  - Not logged in: `LoginPage()` (authentication flow)
- **Route Registration**: 
  - `/register` route mapped to `RegisterPage()`
  - `onUnknownRoute` handler for 404-style routing

### AppPage Routing Setup (lib/pages/app/app_page.dart)
- **Purpose**: Main application container after authentication
- **RouteManager Initialization**: 
  - Creates `RouteManager` with `AuthProvider` and `NavigatorKey`
  - Passes `RouteManager` to `NavigationScaffold`
- **Navigation State**: Single `GlobalKey<NavigatorState>` for all navigation

### NavigationScaffold Architecture (lib/widgets/navigation/navigation_scaffold.dart)
- **Persistent Navigation**: Single scaffold for entire app
- **Components**:
  - **AppBar**: Dynamic title from `RouteManager.currentPage.title`
  - **Drawer**: `AppDrawer` with role-based menu items
  - **Body**: `Navigator` widget with `RouteManager.onGenerateRoute`
  - **BottomNavBar**: `BottomNavBar` with tab navigation
- **State Management**: `ValueListenableBuilder` for route changes

### RouteManager - Central Navigation Controller (lib/app/route_manager.dart)
- **Core Responsibilities**:
  - Route generation via `onGenerateRoute`
  - Current route tracking with `ValueNotifier<String>`
  - Role-based route permissions
  - Navigation state management

- **Route Definitions**:
  ```dart
  static const Map<String, ContentPage> routeMap = {
    '/parking': ParkingPage(),
    '/profile': ProfilePage(),
    '/settings': SettingsPage(),
    '/admin/users': UserPage(),
  };
  ```

- **Access Control**:
  ```dart
  final routePermissions = {
    '/dashboard': [UserRole.admin, UserRole.lecturer, UserRole.student],
    '/parking': UserRole.values,
    '/admin/users': [UserRole.admin],
    '/profile': UserRole.values,
    '/settings': UserRole.values,
  };
  ```

- **Navigation Methods**:
  - `canAccess(String? route)`: Checks role-based permissions
  - `navigateTo(String route)`: Safe navigation with permission check
  - `onGenerateRoute`: Route factory with fallback to default

## Component Usage Requirements - ENFORCED

### ContentPage Usage - MANDATORY
- **Requirement**: ALL pages under `@app_page` MUST extend `ContentPage`
- **File**: `lib/widgets/app/content_page.dart`
- **Purpose**: Standardized page structure with title property
- **Usage Pattern**:
  ```dart
  class ParkingPage extends ContentPage {
    const ParkingPage({super.key}) : super(title: 'Parking');
    
    @override
    State<ParkingPage> createState() => _ParkingPageState();
  }
  ```

### App Page Structure - ENFORCED
- **Location**: All app pages MUST be in `lib/pages/app/`
- **Required Structure**:
  ```
  lib/pages/app/
  ├── app_page.dart          # Main app container (uses NavigationScaffold)
  ├── parking_page.dart      # Parking functionality (extends ContentPage)
  ├── profile_page.dart      # User profile (extends ContentPage)
  ├── settings_page.dart     # App settings (extends ContentPage)
  └── admin/
      └── user_page.dart     # Admin user management (extends ContentPage)
  ```

### Navigation Widgets - CENTRALIZED USAGE
- **NavigationScaffold**: `lib/widgets/navigation/navigation_scaffold.dart`
  - **Usage**: Used exclusively by AppPage as root scaffold
  - **Provides**: Persistent navigation shell for all app pages
  - **Integration**: Manages AppDrawer, BottomNavBar, and content navigation
  
- **AppDrawer**: `lib/widgets/navigation/app_drawer.dart`
  - **Usage**: Managed by NavigationScaffold
  - **Features**: Role-based menu items, route highlighting
  
- **BottomNavBar**: `lib/widgets/navigation/bottom_nav_bar.dart`
  - **Usage**: Managed by NavigationScaffold
  - **Tabs**: Parking (index 0) and Profile (index 1)

## Key Technical Components

### 1. DatabaseManager (Singleton)
```dart
// Usage pattern - SECURITY ENFORCED
final result = await DatabaseManager().executePrepared(
  'SELECT * FROM USER WHERE id = ?',
  [userId]
);
// Returns: List<Map<String, dynamic>> (no model classes)

// Safe static query
final areas = await DatabaseManager().execute('SELECT * FROM PARKING_AREA');
```

### 2. LocationService (Singleton)
```dart
// GPS operations
final location = await LocationService().getCurrentLocation();
final formatted = LocationService().formatCoordinates(location);
// Distance calculation: meters using Haversine formula
```

### 3. AuthManager (Singleton)
```dart
// Authentication flow - SECURITY ENFORCED
final authProvider = await AuthManager().initializeAuth();
await AuthManager().login(universityId, phoneNumber);
// Plain text comparison with database using executePrepared
```

### 4. UserManager (Singleton)
```dart
// User operations - SECURITY ENFORCED
await UserManager().create(userData); // Uses executePrepared
await UserManager().update(userId, updatedData); // Uses executePrepared
await UserManager().delete(userId); // Uses executePrepared, cascades to parking sessions
```

## File Structure Requirements

### Core Directories
```
lib/
├── app/           # Business logic services
├── auth/          # Authentication system
├── database/      # Database configuration
├── pages/         # UI pages by role
│   ├── app/       # App pages (MUST use ContentPage)
│   └── auth/      # Auth pages (Login/Register)
├── utils/         # Shared utilities
└── widgets/       # Reusable UI components
    ├── app/       # App-specific widgets (ContentPage, IdentityCard)
    └── navigation/ # Navigation widgets (NavigationScaffold, AppDrawer, BottomNavBar)
```

### Required Files
- **lib/widgets/app/content_page.dart**: Abstract base class for all app pages
- **lib/pages/app/app_page.dart**: Main app container using NavigationScaffold
- **lib/widgets/navigation/navigation_scaffold.dart**: Central navigation scaffold
- **lib/widgets/navigation/app_drawer.dart**: Role-based drawer navigation
- **lib/widgets/navigation/bottom_nav_bar.dart**: Tab navigation bar
- **lib/database/db_manager.dart**: Database manager with security patterns

## Security Implementation

### Authentication
- **Method**: University ID + phone number (plain text)
- **Storage**: Plain text in database
- **Session Persistence**: SharedPreferences for auto-login
- **Role-based Access**: Route-level permission checking
- **Transport Security**: HTTPS for Gist configuration only
- **Database Security**: executePrepared for all user input queries

### Data Storage
- **Plain Text Storage**: All data unencrypted in database
- **Database Security**: MySQL user-level permissions
- **SQL Injection Prevention**: executePrepared for all user inputs
- **File Upload**: PNG/JPEG/WebP for payment proof
- **No API Tokens**: Direct database connections
- **File Storage**: MySQL BLOB for payment proof images

### SQL Injection Prevention
- **executePrepared**: **MANDATORY** for user input queries
- **execute**: **RESTRICTED** to safe, static queries only
- **Parameter Binding**: Automatic via mysql_client prepared statements
- **Input Validation**: Centralized validation before database operations

## Coordinate Storage Details

### Database Schema Changes
- **PARKING_AREA table**: latitude DECIMAL(10,8), longitude DECIMAL(11,8)
- **PARKING_SESSION table**: latitude DECIMAL(10,8), longitude DECIMAL(11,8)
- **Rationale**: mysql_client compatibility with spatial data types

### Distance Calculation
- **Formula**: Haversine formula for great-circle distance
- **Units**: Meters
- **Precision**: 8 decimal places for sub-meter accuracy
- **Implementation**: Direct SQL calculation using trigonometric functions

## Payment System Details

### Guest Payment Flow
- **Rate**: RM1 per hour
- **Currency**: Malaysian Ringgit (RM)
- **QR Code**: Single static QR code (latest admin upload)
- **Payment Method**: Bank transfer via displayed QR code
- **Proof Storage**: PNG/JPEG/WebP in MySQL BLOB
- **Security**: executePrepared for all payment-related queries

### Session Status Management
- **Status Values**: approved, unverified, rejected
- **Status Changes**: Admin-only via session review interface
- **Approval Criteria**: Valid payment proof image
- **Rejection Criteria**: Invalid/missing payment proof
- **Security**: executePrepared for all status updates

## GPS & Mapping Implementation

### Location Validation
- **Map Provider**: OpenStreetMap via flutter_map
- **Distance Unit**: Meters
- **Area Matching**: First matching area (no overlap handling)
- **GPS Accuracy**: No minimum threshold
- **Offline Capability**: Available via flutter_map caching

### Coordinate System
- **Format**: Latitude, Longitude (decimal degrees)
- **Distance Formula**: Haversine for great-circle distance
- **Radius Calculation**: Circular boundary in meters
- **Storage**: Separate latitude/longitude columns for compatibility

## Error Handling

### Logging Strategy
- **Console Output**: All errors logged for debugging
- **SQL States**: Database errors include context
- **Network Errors**: Timeout and connection details

### User Feedback
- **Form Validation**: Clear, consistent error messages
- **Loading States**: All async operations show progress
- **Error Boundaries**: Widget-level error handling
- **Success Confirmations**: Action completion feedback
- **Retry Logic**: Manual retry for all network operations

## Development Commands

### Database Setup
```bash
# Start MySQL via Docker
docker-compose up -d

# Test database connection
dart scripts/test_db.dart
```

### Flutter Commands
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Build release
flutter build apk
```

## Current Implementation Status

### ✅ COMPLETED
- Database setup and connection
- Authentication system (plain text)
- User management (CRUD operations with expiry)
- GPS location services
- Navigation architecture with complete routing
- Profile system
- Form validation
- **MySQL client compatibility**: Replaced POINT with latitude/longitude columns
- **Complete routing architecture**: Role-based navigation with persistent scaffold
- **ContentPage pattern**: All app pages extend ContentPage
- **Centralized navigation**: AppPage uses NavigationScaffold
- **Database security patterns**: executePrepared/execute distinction documented

### 🔄 PENDING
- Map integration with flutter_map (OpenStreetMap)
- Parking area GPS validation (meter calculations)
- QR payment system (RM1/hour, single QR)
- User expiry handling (auto-delete on login/startup)
- Admin session review interface (split view: guests vs lecturer/student)
- Security audit: Ensure all user inputs use executePrepared