# Localization Guide

This app supports 12 languages. All user-facing text is stored in JSON files under `Capybara_Rescue_App/Localizable/`.

## Supported Languages

| Code   | Language              |
|--------|-----------------------|
| en     | English               |
| zh-Hant| 繁體中文 (Traditional Chinese) |
| ja     | 日本語 (Japanese)      |
| ko     | 한국어 (Korean)        |
| pt-BR  | Português (Brasil)     |
| es-MX  | Español (México)      |
| tr     | Türkçe (Turkish)      |
| hi     | हिन्दी (Hindi)         |
| fr     | Français (French)     |
| de     | Deutsch (German)      |
| it     | Italiano (Italian)    |

## Adding New Text

**When you add any new user-facing text in English, you MUST add the translation key to ALL language files.**

1. **Choose a key** – Use dot notation: `section.name` (e.g. `settings.title`, `menu.food`).

2. **Add to `en.json`** – Add the key with the English value:
   ```json
   "myNew.key": "My New Text"
   ```

3. **Add to every other language file** – Add the same key with the translated value in:
   - `zh-Hant.json`
   - `ja.json`
   - `ko.json`
   - `pt-BR.json`
   - `es-MX.json`
   - `tr.json`
   - `hi.json`
   - `fr.json`
   - `de.json`
   - `it.json`

4. **Use in code** – Use the `L()` helper:
   ```swift
   Text(L("myNew.key"))
   ```

5. **Views that show localized text** – Add `@ObservedObject private var localizationManager = LocalizationManager.shared` so the UI updates when the user changes language.

## Adding a New Language

1. Create `Capybara_Rescue_App/Localizable/{code}.json` (e.g. `ar.json` for Arabic).
2. Copy all keys from `en.json` and translate the values.
3. Add the language to `LocalizationManager.supportedLanguages` in `LocalizationManager.swift`:
   ```swift
   ("ar", "العربية"),
   ```

## Key Naming Conventions

- `settings.*` – Settings screen
- `menu.*` – Bottom menu tabs
- `common.*` – Shared UI strings
- `panel.*` – Panel headers and content
- `rename.*` – Rename sheet
- `tutorial.*` – Tutorial overlay
- `hat.*` – Hat/accessory messages
- `item.*` – Item names (hats, etc.)
- `food.*` – Food item names
- `drink.*` – Drink item names

## Fallback

If a key is missing in the current language, the app falls back to the English value from `en.json`.
