#!/usr/bin/env bash
# Local + CI security gate for the Relay app (OWASP A02 Misconfiguration,
# A03 Supply-chain, A04 Cryptographic failures, A09 Logging).
#
#   tool/security_check.sh
#
# Exits non-zero on the first class of problem it finds. Heuristic checks are
# deliberately strict; add a narrow allow-list entry below rather than
# loosening a rule.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
say()  { printf '\n\033[1m== %s\033[0m\n' "$1"; }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=1; }
ok()   { printf '  \033[32mok\033[0m   %s\n' "$1"; }

say "1. Dependencies come only from pub.dev (no git/path overrides)"
if grep -nE '^\s+(git|path):|dependency_overrides' pubspec.yaml; then
  bad "pubspec.yaml uses git/path dependencies or overrides"
else
  ok "hosted dependencies only"
fi

say "2. Lockfile is committed and consistent with pubspec.yaml"
if [ ! -f pubspec.lock ]; then
  bad "pubspec.lock is missing"
elif flutter pub get --enforce-lockfile >/dev/null 2>&1; then
  ok "pubspec.lock matches pubspec.yaml"
else
  bad "pubspec.lock is out of date (run: flutter pub get)"
fi

say "3. Direct dependencies are current (stale packages miss security fixes)"
outdated="$(flutter pub outdated --no-dev-dependencies --no-transitive 2>&1)"
echo "$outdated" | sed -n '1,12p'
if echo "$outdated" | grep -q 'direct dependencies: all up-to-date'; then
  ok "no outdated direct dependencies"
else
  bad "outdated direct dependencies (see table above)"
fi

say "4. Known-vulnerability scan of pubspec.lock (OSV database)"
if command -v osv-scanner >/dev/null 2>&1; then
  if osv-scanner scan source --lockfile pubspec.lock; then
    ok "no known vulnerabilities"
  else
    bad "osv-scanner reported vulnerabilities"
  fi
else
  printf '  skipped: osv-scanner not installed (CI runs it). Install: brew install osv-scanner\n'
fi

say "5. No cleartext http:// URLs in shipped code or config"
# Comment lines may *mention* http:// (e.g. "http:// is refused"); string literals may not.
if grep -rnE "http://" lib config android/app/src/main ios/Runner/Info.plist 2>/dev/null \
    | grep -vE 'schemas\.android\.com|www\.apple\.com/DTDs|www\.w3\.org' \
    | grep -vE '^[^:]+:[0-9]+:\s*(//|\*|<!--)'; then
  bad "cleartext http:// found"
else
  ok "HTTPS only"
fi

say "6. No hard-coded secrets in source or config"
# Fake tokens in the offline mock backend are allowed; nothing else is.
# Dart: `apiKey: 'value'` / `secret = "value"` (key directly followed by : or =).
dart_pattern="(api[_-]?key|secret|passwd|password|private[_-]?key|access[_-]?token|refresh[_-]?token|bearer)\s*[:=]\s*[\"'][^\"']{8,}[\"']"
# JSON config: "SOME_KEY": "value" where the key name looks sensitive.
json_pattern="\"[A-Za-z_]*(KEY|SECRET|TOKEN|PASSWORD|PASSWD)[A-Za-z_]*\"\s*:\s*\"[^\"]{8,}\""
hits="$( { grep -rniE "$dart_pattern" lib | grep -v '_mock_data_source.dart'; grep -rnE "$json_pattern" config; } 2>/dev/null || true)"
if [ -n "$hits" ]; then echo "$hits"; bad "possible hard-coded secret"; else ok "none found"; fi
if grep -rnE -- '-----BEGIN [A-Z ]*PRIVATE KEY|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}' . \
     --include='*.dart' --include='*.json' --include='*.yaml' --include='*.plist' --include='*.xml' \
     --exclude-dir=build --exclude-dir=.dart_tool --exclude-dir=.git 2>/dev/null; then
  bad "key material found in repository"
else
  ok "no private keys / cloud key patterns"
fi

say "7. No print()/debugPrint() in app code (logs must go through AppLogger)"
if grep -rnE '(^|[^a-zA-Z_.])(print|debugPrint)\(' lib; then
  bad "raw print/debugPrint in lib/"
else
  ok "logging goes through AppLogger"
fi

say "8. Platform hardening is in place"
grep -q 'usesCleartextTraffic="false"' android/app/src/main/AndroidManifest.xml \
  && ok "Android: cleartext traffic disabled" || bad "Android: usesCleartextTraffic=false missing"
grep -q 'allowBackup="false"' android/app/src/main/AndroidManifest.xml \
  && ok "Android: backups disabled" || bad "Android: allowBackup=false missing"
grep -q 'cleartextTrafficPermitted="false"' android/app/src/main/res/xml/network_security_config.xml \
  && ok "Android: network security config forbids cleartext" || bad "Android: network_security_config.xml missing"
! grep -q 'NSAllowsArbitraryLoads' ios/Runner/Info.plist \
  && ok "iOS: App Transport Security not weakened" || bad "iOS: NSAllowsArbitraryLoads present"

say "9. Production config is safe"
if grep -q '"USE_MOCK_BACKEND": "true"' config/prod.json config/staging.json 2>/dev/null; then
  bad "mock backend enabled in staging/prod config"
else
  ok "mock backend only in dev"
fi

echo
if [ "$fail" -ne 0 ]; then printf '\033[31mSecurity check FAILED\033[0m\n'; exit 1; fi
printf '\033[32mSecurity check passed\033[0m\n'
