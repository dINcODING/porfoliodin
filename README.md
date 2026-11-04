# Nuruddin Mahmud — Portfolio

An interactive Flutter portfolio presenting Nuruddin's projects, experience,
skills, and contact information. The interface adapts to mobile and desktop,
supports reduced motion, and uses hash-based routes so deep links work on
GitHub Pages.

## Local development

```sh
flutter pub get
flutter run -d chrome
```

## Quality checks

```sh
flutter analyze
flutter test
flutter build web --release
```

## Deployment

Pushes to `main` are analyzed, tested, built with the `/porfoliodin/` base
path, and deployed through the GitHub Pages workflow.
