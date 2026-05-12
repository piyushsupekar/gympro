# GymPro Firebase Setup

## Step 1 - Create Firebase Project

1. Go to `console.firebase.google.com`.
2. Click **Add project**.
3. Name it `GymPro`.
4. Disable Google Analytics for now to keep setup simple.

## Step 2 - Enable Services

Enable these one by one in Firebase Console:

1. **Authentication**
   - Go to **Sign-in methods**.
   - Enable **Email/Password**.
   - Enable **Google**.

2. **Firestore Database**
   - Create database.
   - Start in **production mode**.

3. **Storage**
   - Create storage bucket.
   - Start in **production mode**.

## Step 3 - Firestore Security Rules

Paste this in **Firestore Database -> Rules**:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

The same rules are saved in `firebase/firestore.rules`.

## Step 4 - Google Play Store Launch Checklist

| Step | What to do |
| --- | --- |
| 1 | Run `flutter build appbundle --release`. |
| 2 | Create keystore: `keytool -genkey -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`. |
| 3 | Pay the $25 one-time fee at `play.google.com/console`. |
| 4 | Create app and upload the `.aab` file. |
| 5 | Fill store listing with screenshots, icon, and description. |
| 6 | Set content rating to Everyone. |
| 7 | Set up in-app purchases in Play Console before going live. |
| 8 | Submit for review. Review usually takes 2-7 days. |
