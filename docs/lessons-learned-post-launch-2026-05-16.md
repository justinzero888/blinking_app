# Lessons Learned — Production Launch May 16, 2026

## Issue Summary

Post-launch audit revealed 3 uncommitted server changes and stale KV secrets that were assumed deployed but never were. AI features worked due to compile-time fallback keys masking the missing server endpoint. The entitlement fingerprinting (preview abuse prevention) was also blocked behind an undiscovered env gate.

---

## 1. Session Summaries ≠ Ground Truth

**What happened:** Multiple session summaries (May 9-11) documented server endpoints as "✅ Live" and "Deployed." Git showed the files were never committed. The last `wrangler deploy` was April 28 — 2 weeks before the code was written.

**Root cause:** The app worked because of a fallback chain (dart-define keys). When testing showed AI working, the natural assumption was "server must be deployed." Nobody verified with `curl` against production.

**Fix going forward:** Add a post-deploy smoke test to the deployment workflow:
```bash
# After every wrangler deploy
curl -s https://blinkingchorus.com/api/config | python3 -c "
import json, sys; d=json.load(sys.stdin)
assert 'trial_keys' in d or 'pro_keys' in d, 'No AI keys returned'
print('OK')
"
```

Never trust "the app works" as proof the server is deployed. Verify each endpoint independently with HTTP calls.

---

## 2. Compile-Time Fallbacks Mask Deployment Gaps

**What happened:** The AI key loading chain is `server → cache → dart-define`. The dart-define keys (`TRIAL_API_KEY`/`PRO_API_KEY`) were baked into every build. This meant AI always worked regardless of server state — the fallback became the only path without anyone noticing.

**Root cause:** The fallback was designed to be a safety net, but it was so reliable that it hid the absence of the primary path. No telemetry or logging distinguished "server config loaded" from "using fallback."

**Fix going forward:** Add observability to fallback activation:
```dart
// In ConfigService.fetch()
if (config == null) {
  debugPrint('[ConfigService] WARNING: Using fallback keys — server unreachable');
  // Optional: send a metric/counter to track how often this happens
}
```

This way, if fallback is always active, it's visible in logs instead of silent.

---

## 3. KV Secrets Can Drift Without Detection

**What happened:** The `BLINKING_TRIAL_KEYS` secret was set to `meta-llama/llama-4-maverick` during an intermediate model switch (May 10) and never updated after the final decision (May 11 — DeepSeek primary, Gemini failover). The `BLINKING_PRO_KEYS` was correctly updated. Nobody noticed because both models respond to API calls.

**Root cause:** KV secrets are opaque blobs with no schema validation. There's no automated check that "the current secrets match the intended configuration." The only source of truth was a session summary that said "both trial + pro keys" use the same config.

**Fix going forward:** Add a contract test or validation script:
```bash
# validate-config.sh — run periodically or in CI
EXPECTED_MODELS="deepseek/deepseek-chat-v3-0324 google/gemini-2.0-flash-001"
ACTUAL=$(curl -s https://blinkingchorus.com/api/config | python3 -c "
import json,sys
d=json.load(sys.stdin)
models=set()
for k in d.get('trial_keys',[])+d.get('pro_keys',[]): models.add(k['model'])
print(' '.join(sorted(models)))
")
for m in $EXPECTED_MODELS; do
  echo "$ACTUAL" | grep -q "$m" || echo "MISSING: $m not in active config"
done
```

---

## 4. Feature Gates Can Block Unrelated Features

**What happened:** Device fingerprinting was added to `entitlement.ts:handleInit()` behind `ENTITLEMENT_ENABLED !== 'true'`. The entitlement server was intentionally deferred (local entitlement + RevenueCat is sufficient), but nobody realized this also blocked fingerprinting — a much simpler feature that was supposed to be live.

**Root cause:** Two features of vastly different complexity shared the same gate. Fingerprinting (a simple DB lookup) was tied to the full server entitlement (JWT, quotas, receipt validation, cross-device sync). The gate was named `ENTITLEMENT_ENABLED` but controlled both.

**Fix going forward:** Use feature-specific gates:
```typescript
// ❌ One gate for everything
if (env.ENTITLEMENT_ENABLED !== 'true') return disabled;

// ✅ Separate gates per feature
if (env.ENTITLEMENT_FINGERPRINT_ENABLED === 'true') {
  checkFingerprint();
}
```

Or better: put lightweight checks (fingerprinting) in a separate route/middleware that doesn't depend on the heavy entitlement infrastructure.

---

## 5. Git Status Is Free — Check It Before Claiming "Deployed"

**What happened:** Multiple status docs marked server changes as "Live" and "Deployed." A 5-second `git status` would have shown the files were uncommitted. A 1-second `curl` would have shown the endpoint returned HTML, not JSON.

**Root cause:** Deploying directly from the working tree (`wrangler deploy` pushes whatever is in the filesystem) creates a gap between what's deployed and what's committed. If a subsequent deploy from committed code overwrites it, the uncommitted changes vanish without a trace.

**Fix going forward:** Add to the deployment checklist:
```
[ ] git status — no uncommitted changes in src/ or migrations/
[ ] git log -1 — verify the commit being deployed
[ ] curl endpoint — verify each new route returns expected response
[ ] git push — push before deploy, not after
```

Or enforce in CI: only deploy from tagged commits, never from a dirty working tree.

---

## 6. Testing Against Staging Found Nothing Because There Was No Staging

**What happened:** The client was tested against the production server. The server wasn't deployed. The test passed because the fallback compensated. This is a classic "tested the wrong environment" problem.

**Root cause:** No staging environment for the server. The client and server were tested together, but the client's fallback behavior made it impossible to distinguish "server working" from "server down, fallback active."

**Fix going forward:** At minimum, add an assertion to the client that fails loudly when server is unreachable:
```dart
// In debug builds only
if (kDebugMode && config == null) {
  throw StateError('Server config unavailable — is the Worker deployed?');
}
```

Longer term: deploy a staging Worker (`staging.blinkingchorus.com`) and configure debug builds to point there. This makes the failure visible instead of silently falling back.

---

## Prevention Checklist for Future Deployments

```
[ ] git status — clean working tree, all changes committed
[ ] git log -1 — verify the right commit is being deployed
[ ] curl each new endpoint — verify HTTP 200 + correct content type
[ ] curl each modified endpoint — verify behavior hasn't regressed
[ ] Check KV secrets match intended config (run validate-config.sh)
[ ] Run full test suite (client + server) — must be 0 failures
[ ] Document deployed commit hash in session summary
[ ] Verify feature gates are correctly configured
```

---

## What Worked Well

1. **Fallback design saved the launch.** Without the dart-define compile-time keys, AI would have been dead on day one. The defense-in-depth approach (server → cache → compile-time) was correct — it just needed observability.
2. **RevenueCat handled IAP independently.** The purchase flow didn't depend on any server endpoint. This was the right call.
3. **Local entitlement was sufficient.** Deferring the full server entitlement was the right decision. The app works without it.
4. **The audit caught the gaps within hours of launch.** No user impact — the fixes were deployed before anyone noticed.
