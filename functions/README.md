# Cloud Functions for Equipment Translation

## Required secrets

Set Gemini API key in Functions runtime:

```bash
firebase functions:config:set gemini.key="YOUR_GEMINI_API_KEY"
```

Or set `GEMINI_API_KEY` as environment variable in your deployment pipeline.

## Deploy

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

## Callable functions

- `translateEquipmentFields`: translates title/description/category to en/ta/hi.
- `translateEquipmentData`: migrates old equipment docs where text fields are plain strings.
  - Requires authenticated user with custom claim `admin=true`.
