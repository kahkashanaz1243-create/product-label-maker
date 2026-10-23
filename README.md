# Product Label Maker

A Flutter starter app for creating simple product labels in Hindi and English.

## Current starter features
- Offline label editor
- Product name, category, net quantity, MRP, batch, manufacturing/expiry dates, manufacturer and ingredients
- Preview card
- Save labels locally using SharedPreferences
- Export/share as PDF and PNG
- GitHub Actions workflow for APK and AAB builds

## Create the Android project locally
Install Flutter, then run:
```bash
flutter create --platforms=android .
flutter pub get
flutter run
```

## GitHub Actions
Push this repository to GitHub. The workflow `.github/workflows/build-apk-aab.yml` builds APK and AAB on push to `main` or when manually started from Actions.

## Important
This is a starter implementation and has not been build-tested in this environment. Review and test the generated Android project on a computer or CI before publishing. Packaging and label declarations must comply with the laws applicable to the product category; do not assume a generated label is legally compliant.
