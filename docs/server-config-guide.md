# Server Config — AI Key Management

The Blinking app reads AI provider keys from a server-hosted JSON config file. This allows updating API keys and models **without deploying a new app version**.

---

## How it works

1. App starts → fetches `https://blinkingchorus.com/api/config`
2. Valid for 24 hours (cached in SharedPreferences)
3. If server unreachable → uses **dart-define** fallback keys compiled in the app
4. If no fallback → uses last cached server config (even if stale)

### Priority order

```
Server config (fresh, < 24h) → Server config (cached, stale) → dart-define compile-time keys
```

---

## Config file format

Host a JSON file at `https://blinkingchorus.com/api/config`:

### Multi-key format (recommended)

```json
{
  "trial_keys": [
    {"key": "sk-or-v1-primary-key", "model": "qwen/qwen3.5-flash"},
    {"key": "sk-or-v1-backup-key", "model": "qwen/qwen3.5-flash"}
  ],
  "pro_keys": [
    {"key": "sk-or-v1-primary-key", "model": "qwen/qwen3.5-flash"},
    {"key": "sk-or-v1-backup-key", "model": "qwen/qwen3.5-flash"}
  ]
}
```

### Legacy format (single key, still supported)

```json
{
  "trial_key": "sk-or-v1-...",
  "trial_model": "qwen/qwen3.5-flash",
  "pro_key": "sk-or-v1-...",
  "pro_model": "qwen/qwen3.5-flash"
}
```

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `trial_keys` | Array | No | dart-define | List of key+model objects for trial users |
| `trial_keys[].key` | String | Yes | — | OpenRouter API key |
| `trial_keys[].model` | String | No | `qwen/qwen3.5-flash` | Model for this key |
| `pro_keys` | Array | No | dart-define | List of key+model objects for paid users |
| `pro_keys[].key` | String | Yes | — | OpenRouter API key |
| `pro_keys[].model` | String | No | `qwen/qwen3.5-flash` | Model for this key |
| `trial_key` | String | No | — | Legacy: single trial key |
| `pro_key` | String | No | — | Legacy: single pro key |
| `trial_model` | String | No | `qwen/qwen3.5-flash` | Legacy: trial model |
| `pro_model` | String | No | `qwen/qwen3.5-flash` | Legacy: pro model |

---

## Key Failover

Keys are tried **in order** (array index 0 first). If a key fails with a retryable error, the next key is attempted automatically:

| Error | Failover? |
|-------|-----------|
| 401/403 (invalid key) | Yes → next key |
| 429 (rate limited) | Yes → next key |
| 5xx (server error) | Yes → next key |
| Timeout | Yes → next key |
| Network error | **No** — don't retry |
| Empty response | **No** — don't retry |

If all keys fail, the last error is shown to the user.

This allows you to:
- **Rotate keys** without downtime (add new key first, remove old key later)
- **Load balance** across multiple OpenRouter accounts
- **Graceful degradation** — if one key is rate-limited, next one picks up

---

## How to update keys

### Cloudflare Workers (recommended)

If your backend is on Cloudflare Workers (blinkingchorus.com):

1. Edit the worker code to return the updated config:

```js
// api/config.js
export default {
  async fetch(request) {
    if (request.method === 'GET') {
      return new Response(JSON.stringify({
        trial_key: "sk-or-v1-NEW-TRIAL-KEY",
        pro_key: "sk-or-v1-NEW-PRO-KEY",
        trial_model: "qwen/qwen3.5-flash",
        pro_model: "qwen/qwen3.5-flash"
      }), {
        headers: { 'Content-Type': 'application/json',
                   'Cache-Control': 'public, max-age=3600' }
      });
    }
    return new Response('Not found', { status: 404 });
  }
};
```

2. Deploy: `npx wrangler deploy`

### Static JSON file

If you host a static site at blinkingchorus.com:

1. Upload `api/config.json` to your web server
2. Ensure `Content-Type: application/json` header
3. Set `Cache-Control: public, max-age=3600` (1 hour CDN cache)

### Manual cache bust

To force all clients to pick up new keys immediately:

1. Update the JSON file on the server
2. Clients will pick it up within 24 hours (cache duration)
3. To test: force-close and reopen the app (config fetched on cold start)

---

## Fallback behavior

If the server config endpoint returns anything other than HTTP 200 (error, timeout, network failure), the app uses:

1. Previously cached server config (any age, even stale)
2. If no cache: dart-define compile-time keys (`--dart-define=TRIAL_API_KEY=...`)

This ensures the app never breaks if the server is down.

---

## Testing

### Verify config is being fetched

Check the app's debug logs (visible on iOS in Xcode console, Android via logcat):

```
[ConfigService] Fetched and cached config
```

If the fetch fails:
```
[ConfigService] Fetch failed: <error>
```

### Force re-fetch

Delete the app data or call `ConfigService.refresh()` programmatically:

```dart
await ConfigService.refresh();
```

### Verify key used

Add a note with emotion → "Ask AI" → the response uses the server-configured key.

---

## Security

- Config file should NOT be publicly browsable if keys are sensitive
- Consider restricting to app bundle ID via origin headers
- OpenRouter keys are bearer tokens — treat like passwords
- Regenerate immediately if a key is leaked
