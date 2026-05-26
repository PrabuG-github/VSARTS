# VSARTS Flutter Application

A premium, highly scalable, and beautiful Flutter Android application designed with modern engineering patterns. 

This repository leverages the industry-standard **Feature-First Architecture** combined with a robust design system to deliver state-of-the-art experiences and maintainable codebases.

---

## 🎨 Design System & Theme
* **Adaptive Palette:** Full Material 3 support with light and dark mode mappings (`lib/core/theme/app_theme.dart`).
* **Cohesive Colors:** Curated HSL/RGB colors including rich space-darks, vibrant indigo primary tones, pink highlights, and custom gradients (`lib/core/constants/app_colors.dart`).
* **Design Token Spacings:** Strict padding, durations, and border radii mapping (`lib/core/constants/app_constants.dart`) to banish magic numbers forever.

---

## 🏗️ Architecture Blueprint
The application implements a **Feature-First** structure, making it highly modular and scalable:

```
lib/
├── core/                         # Common shared foundation
│   ├── constants/                # App-wide constants (colors, spacers)
│   ├── theme/                    # Theme configurations (Light/Dark themes)
│   ├── utils/                    # Common helper utilities
│   └── widgets/                  # Reusable globally-shared UI controls (e.g., CustomButton)
│
└── features/                     # Feature-specific modules
    └── counter_preview/          # Dynamic dashboard preview feature
        ├── data/                 # Data layer: Models & local/remote data sources
        ├── domain/               # Domain layer: Core Entities & Use cases
        └── presentation/         # Presentation layer: UI, Blocs/Controllers, and widgets
            ├── pages/            # Visual Screen Layouts (e.g., CounterPage)
            └── widgets/          # Component-scoped sub-widgets
```

---

## 🚦 Strict Code Quality
Strong compile-time verification is enforced under `analysis_options.yaml`:
* **Strict Casts & Inference:** Zero type-safety risks.
* **Const Optimization:** Encouraging runtime efficiency with local `const` lints.
* **No Unawaited Futures:** Preventing floating async processes.

---

## 🚀 Getting Started

### Prerequisites
Make sure you have [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.

### Setup Instructions
1. **Clone & Navigate:**
   ```bash
   cd d:/VSARTS
   ```
2. **Fetch Dependencies:**
   ```bash
   flutter pub get
   ```
3. **Verify Lints & Analyze:**
   ```bash
   flutter analyze
   ```
4. **Run Unit Tests:**
   ```bash
   flutter test
   ```
5. **Launch Application:**
   ```bash
   flutter run
   ```

---

## 🤝 Contribution Workflow
Before committing or creating a pull request, always ensure the codebase is formatted and error-free:
```bash
flutter format .
flutter analyze
flutter test
```
