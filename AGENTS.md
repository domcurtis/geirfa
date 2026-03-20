# Geirfa — Agent Notes

## What this project is

A personal PWA (Progressive Web App) flashcard app for learning Welsh vocabulary. The sole user is a single person attending a Welsh language course based in Swansea, currently at intermediate level.

**There is no need to consider:**
- Marketing or onboarding flows
- New user acquisition
- Making features general or configurable to suit different user types
- Accessibility beyond basic usability

Changes should be optimised for one person's learning workflow, not for a general audience.

## Tech stack

- Single-file vanilla JS/HTML/CSS app (`index.html`, ~1000 lines, no build step, no frameworks)
- `vocabulary.json` — 908 Welsh vocabulary entries (fields: `word_english`, `word_welsh`, `category`, `level`, `unit`)
- `sw.js` — service worker for offline PWA support (cache-first strategy)
- `localStorage` for all persistence (ratings, progress, mastered units, session state)

## Testing and pull requests

The user tests all changes via a GitHub Pages preview site that is automatically generated when a pull request is opened against `main`.

**Always open a pull request to `main` after making code changes** — do not just commit and push to a branch. The PR is how the user reviews and tests the work.

## Service worker cache version

**Bump the cache version in `sw.js` every time a feature is added or a bug is fixed.**

The app uses a cache-first service worker strategy, so iOS (and other platforms) will keep serving stale cached files until the cache name changes. The version is on line 1:

```js
const CACHE = 'geirfa-v3';
```

Increment the number (e.g. `v3` → `v4`) with every deployment. Failure to do this means the user's installed web app will not receive the update.

## Vocabulary data

Units are numbered sequentially. The vocabulary follows the progression of the Swansea-area intermediate Welsh course. Do not restructure or rename units arbitrarily — the user's progress is stored by unit number in `localStorage`.

## Spaced repetition model

Cards are rated 0 (Hard), 1 (Okay), or 2 (Got it) and sorted into piles accordingly. Review sessions pull from these piles. Keep this simple — no need to implement a full SRS algorithm.
