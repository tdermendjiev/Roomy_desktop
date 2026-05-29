# Deploy landing site to Firebase Hosting

The marketing site in `landing/` is configured for [Firebase Hosting](https://firebase.google.com/docs/hosting).

## One-time setup

1. **Log in** (opens a browser):

   ```bash
   npx firebase login
   ```

2. **Link this folder to your Firebase project** (the one where GA4 / `G-Y1DDG8XTJD` is enabled):

   ```bash
   npx firebase use --add
   ```

   Select your project and accept the `default` alias. This writes your project ID to `.firebaserc`.

3. **Enable Hosting** in the [Firebase console](https://console.firebase.google.com/) if you have not already: Build → Hosting → Get started.

## Deploy

From the repo root:

```bash
npm install
npm run deploy:landing
```

Or without `npm install`:

```bash
npx firebase deploy --only hosting
```

After deploy, the CLI prints your live URLs (e.g. `https://<project-id>.web.app` and any custom domain you attach).

## Configuration

| File | Purpose |
|------|---------|
| `firebase.json` | Serves `landing/` as the site root; `cleanUrls` maps `/privacy` → `privacy.html` |
| `.firebaserc` | Firebase project ID (created by `firebase use --add`) |
| `landing/site-config.js` | GA4 measurement ID |

## Custom domain (optional)

Production domain: **https://getroomy.dev**. Custom domain is configured in Firebase Hosting; redeploy after legal or content changes.
