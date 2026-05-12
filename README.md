# GymPro

A Flutter gym tracking app with Firebase authentication, Firestore workout storage,
progress charts, and Pro monetization.

## Local Setup

1. Install Flutter 3.x and Firebase CLI.
2. From this directory, run `flutter create . --platforms=android,ios,web`.
3. Run `flutterfire configure` and select your Firebase project.
4. Enable Email/Password and Google providers in Firebase Auth.
5. Add Firestore, Storage, and app rules for authenticated users.
6. Run `flutter pub get`.
7. Run `flutter run`.

## In-App Purchases

Create products in Play Console/App Store Connect with these IDs:

- `gympro_pro_monthly_199`
- `gympro_pro_yearly_999`

The app shows fallback prices of `₹199/month` and `₹999/year` while store products
are not configured.

## GitHub

The local repository has an initial `main` commit and active development happens on
the `development` branch. Create an empty GitHub repository, then add it as `origin`
and push both branches.
