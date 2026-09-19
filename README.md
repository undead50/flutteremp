# Relay

Executive memo approvals for mobile. Flutter implementation of the
[Logo STA / "employee mobile"](https://www.figma.com/design/Ugx1xvZDvqOTWiakKXDbIP/Logo-STA?node-id=2176-2)
design (5 screens): Welcome, Sign-in, Memos feed, Memo detail and Settings, with
Modules/Activity tabs stubbed as empty states because the design has no frames for them.

## Run it

```bash
flutter pub get
flutter run --dart-define-from-file=config/dev.json      # offline mock backend
```

The dev config uses an **in-memory mock backend**: any valid email plus a password of
at least 8 characters signs in. Fewer characters shows the "incorrect" state; five
failures show the lock-out.

```bash
flutter analyze                                   # strict-casts / inference / raw-types
flutter test --exclude-tags screenshots           # 166 unit + widget tests
flutter test --tags screenshots                   # renders each screen to build/design_check/*.png
flutter test integration_test --dart-define-from-file=config/dev.json   # needs a device/simulator
tool/security_check.sh                            # dependency + configuration security gate

# Release (obfuscated, split debug symbols kept out of the app):
flutter build apk --release --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file=config/prod.json
```

## Architecture

Feature-first Clean Architecture. Dependencies point inwards only:
`presentation → domain ← data`; `domain` imports no Flutter, Dio or storage code.

```
lib/
  main.dart / bootstrap.dart     validate config, install safe error handlers, start app
  app/                           router (auth guards), shell (bottom nav), splash / not-found
  core/
    config/                      AppConfig: environment + HTTPS enforcement (fails closed)
    error/                       sealed Failure (user-safe messages) + Result<T>
    network/                     Dio client, auth/refresh interceptor, JsonObject (defensive parsing)
    security/                    sanitiser, validators, token store, biometrics, https-only launcher
    theme/  widgets/  assets/    tokens from Figma + reusable design-system components
    providers/                   Riverpod composition root (all DI happens here)
  features/
    auth/  onboarding/  memos/  settings/
      domain/        entities · repository interfaces · use cases (business rules)
      data/          DTOs · remote + mock data sources · repository implementations
      presentation/  Riverpod controllers · screens · widgets (no business logic)
```

* **State + DI: Riverpod** (`Notifier`/`AsyncNotifier`, no codegen). Swapping the backend
  is one provider override; mock vs. remote is chosen from config in each feature's
  `*_providers.dart`.
* **Repository + datasource pattern.** Repositories wrap every call in `guardedCall`, so
  nothing throws past the data layer and no raw error text reaches the UI.
* **Business rules live in use cases**, e.g. revision/decline require a 3-500 char note;
  the last active module can't be disabled; ids are allow-listed; input is sanitised.
* **States everywhere:** loading, empty, error (offline / timeout / server / malformed),
  success toasts, inline validation, per-button progress, double-submit protection.
* **Responsive + accessible:** content is capped at the design's 448pt column; text
  scale = OS scale × in-app preset (Standard/Large/Extra Large); semantics labels, 44pt
  targets, live-region errors, high-contrast borders.

## Configuration (`--dart-define-from-file`)

| Key | Meaning |
|---|---|
| `APP_ENV` | `dev` \| `staging` \| `prod` (required) |
| `API_BASE_URL` | Must be `https://…`, no credentials/query (required unless mock) |
| `USE_MOCK_BACKEND` | Only allowed in `dev`. Production can never use the mock. |
| `ENABLE_LOGGING` | Ignored (forced off) in `prod` |
| `PRIVACY_URL`, `HELPDESK_URL`, `TRUST_CENTER_URL` | Optional https links |

Everything compiled into the binary is extractable. **Never put secrets in these files**;
`config/*.local.json` is git-ignored for private overrides.

## Backend contract this client speaks

No API spec was provided, so these endpoints are an assumption to be aligned with the
real backend (see `core/network/api_endpoints.dart` and the DTOs):

`POST /v1/auth/login` · `/v1/auth/refresh` · `/v1/auth/logout` · `GET /v1/me` ·
`GET /v1/me/sign-off-proxy` · `GET /v1/memos/feed` · `GET /v1/memos/{id}` ·
`POST /v1/memos/{id}/decisions` (`Idempotency-Key` header; `decision`, optional `comment`).
Money is integer cents. Unknown *optional* enum values are skipped; malformed required
fields fail the payload with a safe error.

## Security (OWASP Top 10:2025)

The client is not a trust boundary: **authentication, authorization, rate limiting,
step-up and audit must be enforced by the backend.** Client controls are UX plus defence in depth.

| Risk | What this app does |
|---|---|
| A01 Broken Access Control | Route guards only choose which screens to *show*. Every call is authorised server-side; 401 triggers one refresh then sign-out, 403 is surfaced, never bypassed. Deep-link ids are allow-listed. |
| A02 Security Misconfiguration | HTTPS-only config that fails closed; prod can't use the mock; Android cleartext + backups off, network-security-config; iOS ATS untouched; no runtime font fetching. |
| A03 Supply-chain | Minimal deps, all hosted on pub.dev, lockfile enforced, `tool/security_check.sh` + OSV scan + Dependabot in CI. |
| A04 Cryptographic Failures | TLS only, redirects not followed, tokens only in Keychain/Keystore (`first_unlock_this_device`); nothing sensitive in prefs. |
| A05 Injection | Sanitiser strips control/zero-width/bidi characters; ids validated before use in paths; no HTML/WebView; no dynamic queries. |
| A06 Insecure Design | Idempotency keys stop double-approvals; confirm dialogs on sign-off; explained decline/revision; in-flight locks. |
| A07 Authentication Failures | Generic credential error, client cool-down after 5 failures, password never held in state and cleared on failure, autofill-friendly, biometric unlock only resumes an existing session. |
| A08 Integrity | All API JSON is type-checked, size-capped and sanitised; money as integer cents; total derived from lines; https-only avatars. |
| A09 Logging | `AppLogger` logs types not payloads, redacts emails/tokens, verbose off in prod, no analytics SDKs. |
| A10 Exceptional Conditions | Failures are sealed, user-safe strings; global handlers log redacted, release builds show a neutral error widget; every error path has a UI state. |

## Design fidelity

Implemented from the Figma design context for screens 1-4 and compared side by side
(`flutter test --tags screenshots`). Deliberate deviations:

* Header titles render in full ("Memos"/"Settings"); the export clipped them ("Mer"/"Set").
* Icon badges on Settings are round 36pt (the export squeezed them to ovals).
* Two-word status badges wrap on two lines like the design; feed text can differ by ±1pt
  per line because Flutter rounds 24.38pt line heights.
* Fonts (Epilogue, Plus Jakarta Sans; OFL) are bundled as variable fonts.

## Known gaps

* **Settings screen:** the Figma MCP quota ended before its design context could be
  fetched. It is built from node metadata + the overview render. Its icons are Material
  stand-ins (`SettingsIcons`) and the Marcus Brody avatar falls back to initials.
* **SSO** needs a tenant identity provider; until configured it reports "not available".
* **"Swipe to batch"** and **Search** are shown as in the design but have no specified behaviour.
* **Offline outbox** is a documented no-op (all writes are online-only today).
* No certificate pinning (needs real hostnames); no localisation; light theme only.
* Android/iOS release builds and the on-device integration test were not run in the
  authoring environment (see the hand-off notes).
