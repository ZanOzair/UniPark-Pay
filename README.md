# UniParkPay - University Parking App

## What This App Does

This is a parking management app for universities that helps students, lecturers, guests, and admins manage parking with GPS tracking.

## 📱 App Pages & Screens

### Login/Register Pages
- *Login Page*: Where everyone starts - enter your phone number and ID
- *Register Page*: New users create accounts here

### Main App Pages (After Login)
- *Parking Page*: Shows your GPS location and lets you start parking
- *Profile Page*: View your account details and logout
- *Settings Page*: App settings and preferences

### Admin-Only Pages
- *User Management Page*: Add, edit, or remove users
- *QR Upload Page*: Update the payment QR code
- *Parking Sessions Page*: Review and approve guest parking payments

## 📁 How the Code is Organized

Think of the code like organized folders in an office:

### Main Folders (Like Departments)

*📁 lib/pages/* - All the screens you see in the app
- *auth/* - Login and register screens
  - login_page.dart (Login screen)
  - register_page.dart (Registration screen)
- *app/* - Main app screens
  - parking_page.dart (GPS parking screen)
  - profile_page.dart (Your profile)
  - settings_page.dart (Settings)
  - admin/ - Admin-only screens
    - user_page.dart (Manage users)
    - qr_upload_page.dart (Update QR codes)
    - parking_sessions_page.dart (Review payments)

*📁 lib/app/* - The brain of the app (business logic)
- route_manager.dart (Controls where you go in the app)
- user_manager.dart (Manages all users)
- location_service.dart (GPS and location stuff)
- parking_session_manager.dart (Handles parking sessions)
- qr_manager.dart (QR code operations)

*📁 lib/auth/* - Login and security
- auth_manager.dart (Handles all login/logout)
- auth_provider.dart (Keeps track of who's logged in)

*📁 lib/database/* - Where data is stored
- db_manager.dart (Talks to the database)
- gist_config.dart (Secure configuration)

*📁 lib/widgets/* - Reusable app parts
- app/ - Special app components
  - content_page.dart (Base for all pages)
  - identity_card.dart (User ID display)
- navigation/ - Navigation parts
  - navigation_scaffold.dart (Main app layout)
  - app_drawer.dart (Side menu for admins)
  - bottom_nav_bar.dart (Bottom tabs)

*📁 lib/utils/* - Helper tools
- validation_utils.dart (Checks if inputs are correct)
- date_time_utils.dart (Date/time formatting)
- image_data_converter.dart (Image handling)
- session_filter_utils.dart (Session organization)

## 👥 Who Uses What

### Students & Lecturers Use:
- Login/Register pages
- Parking page (GPS parking)
- Profile page (view account)

### Guests Use:
- Login/Register pages
- Parking page (GPS parking + payment)
- Profile page (view account)

### Admins Use:
- Login page
- All main pages PLUS:
  - User management page (manage other users)
  - QR upload page (update payment codes)
  - Parking sessions page (approve guest payments)

## 🚀 Getting Started

### For Users:
1. Download and install the app
2. Open the app
3. Choose your user type when registering
4. Login with your details
5. Start using the parking features

### For Developers:
1. Install Flutter and Android Studio
2. Clone the project
3. Run flutter pub get to get all tools
4. Start the database with docker-compose up -d
5. Run flutter run to start the app

## 🔍 Finding Specific Features

- *Want to change how login works?* → Look in lib/auth/
- *Need to modify parking features?* → Check lib/pages/app/parking_page.dart
- *Admin features not working?* → Look in lib/pages/app/admin/
- *GPS issues?* → Check lib/app/location_service.dart
- *Database problems?* → Look in lib/database/db_manager.dart

## 📞 Need Help?

1. *Login Issues*: Check you're using the right login type (student/lecturer/guest/admin)
2. *GPS Not Working*: Make sure location permissions are enabled
3. *Payment Problems*: Ensure you uploaded a clear payment proof image
4. *Account Expired*: Contact admin if you're a student/lecturer with expired account