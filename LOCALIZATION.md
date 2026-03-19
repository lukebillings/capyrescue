# Localization Guide

This app supports 11 languages (English + 10). All user-facing text is stored in JSON files under `Capybara_Rescue_App/Localizable/`.

## Supported Languages

| Code   | Language              |
|--------|-----------------------|
| en     | English               |
| tr     | Türkçe (Turkish)      |
| es-MX  | Español (México)      |
| pt-BR  | Português (Brasil)     |
| zh-Hant| 繁體中文 (Traditional Chinese) |
| ja     | 日本語 (Japanese)      |
| hi     | हिन्दी (Hindi)         |
| ar     | العربية (Arabic)       |
| id     | Bahasa Indonesia (Indonesian) |
| ko     | 한국어 (Korean)        |
| ms     | Bahasa Melayu (Malay)  |

## Adding New Text

**When you add any new user-facing text in English, you MUST add the translation key to ALL language files.**

1. **Choose a key** – Use dot notation: `section.name` (e.g. `settings.title`, `menu.food`).

2. **Add to `en.json`** – Add the key with the English value:
   ```json
   "myNew.key": "My New Text"
   ```

3. **Add to every other language file** – Add the same key with the translated value in:
   - `tr.json`
   - `es-MX.json`
   - `pt-BR.json`
   - `zh-Hant.json`
   - `ja.json`
   - `hi.json`
   - `ar.json`
   - `id.json`
   - `ko.json`
   - `ms.json`

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
