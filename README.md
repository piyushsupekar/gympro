# GymPro

A Flutter gym tracking app with Firebase authentication, Firestore workout storage,
progress charts, and Pro monetization.

## Local Setup

1. Install Flutter 3.x and Firebase CLI.
2. Create the app shell with `flutter create gymapp`.
3. Copy this source into the generated project if needed, or run `flutter create . --platforms=android,ios,web` from this directory.
4. Create a Firebase project at `console.firebase.google.com`.
5. Enable Email/Password and Google providers in Firebase Auth.
6. Add Firestore, Storage, and app rules for authenticated users.

## Installation Commands

Run these one by one after `flutter create gymapp`:

```bash
# 1. Add all packages
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage google_sign_in provider fl_chart in_app_purchase shared_preferences image_picker uuid intl flutter_svg lottie

# 2. Install FlutterFire CLI
dart pub global activate flutterfire_cli

# 3. Connect to Firebase after creating the project
flutterfire configure

# 4. Run the app
flutter run
```

## In-App Purchases

Create products in Play Console/App Store Connect with these IDs:

- `gympro_pro_monthly_199`
- `gympro_pro_yearly_999`

The app shows fallback prices of `₹199/month` and `₹999/year` while store products
are not configured.

See `docs/monetization.md` for the full no-ads business model, revenue streams,
and year-one estimate.

See `docs/firebase_setup.md` for Firebase project setup, Firestore rules, and the
Google Play Store launch checklist.

## GitHub

The local repository has an initial `main` commit and active development happens on
the `development` branch. Create an empty GitHub repository, then add it as `origin`
and push both branches.
