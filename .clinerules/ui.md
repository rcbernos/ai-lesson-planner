---
paths:
  - "lib/features/**"
  - "lib/main.dart"
---

# UI rules (Flutter, Riverpod)

- Riverpod 2.x with `flutter_riverpod`. State that holds the user's work (such as the plan editor) must not auto-dispose, so it survives tab switches.
- Text fields keep the hybrid controller pattern: controllers synced from Riverpod state, never recreated inside `build`.
- Use theme colors (`Theme.of(context).colorScheme`), never hard-coded colors, so light and dark mode both work.
- Layouts must work at 1024×600. Wide tables get explicit column widths and scroll horizontally.
- Widgets that edit take an optional change callback. `null` means read-only.
- Widget tests wrap the widget in `ProviderScope` and must show no overflow errors.
