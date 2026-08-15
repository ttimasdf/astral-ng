# Serverless update API

Astral-ng checks for updates through the read-only Vercel Functions in `api/`.
The functions expose normalized metadata only; they never proxy or install
release artifacts.

## Endpoints

```text
GET /api/v1/update?channel=stable|beta
GET /api/v1/versions?channel=stable|beta&limit=1..30
```

`limit` defaults to `10`. The service rejects unknown, duplicate, or malformed
query parameters. `stable` is sourced from non-draft, non-prerelease GitHub
Releases. `beta` is sourced from successful `build-and-release.yml` push runs on
`main` with a complete set of unexpired canary artifacts.

Stable pages link to the GitHub Release. Beta pages link to the GitHub Actions
run. The API does not return artifact download URLs or expose the GitHub token.
Beta versions disappear after the earliest artifact in the complete build
expires.

## Environment

Set these Vercel environment variables:

- `GITHUB_TOKEN`: fine-grained read-only token for the repository. It needs
  repository Contents read access and Actions read access. Do not expose this
  value to the client.
- `GITHUB_REPOSITORY`: optional `OWNER/REPOSITORY`; defaults to
  `ttimasdf/astral-ng`.
- `GITHUB_WORKFLOW`: optional workflow filename; defaults to
  `build-and-release.yml`.
- `GITHUB_DEFAULT_BRANCH`: optional branch; defaults to `main`.

The function is pinned to Vercel region `iad1` in `vercel.json`. Runtime Cache
keeps GitHub source results and the normalized channel indexes in that region.
The GitHub cache uses ETags and conditional requests.

## Cache policy

Stable responses use a five-minute Vercel CDN TTL with one hour of
stale-while-revalidate. Beta responses use a ten-minute TTL and no stale period;
the TTL is clipped to the earliest artifact expiration in the response. Empty
channels and errors are short-lived.

The Flutter app uses the compile-time `UPDATE_API_BASE_URL` value:

```sh
flutter build windows \
  --dart-define=UPDATE_API_BASE_URL=https://your-project.vercel.app/api/v1
```

The default source value is `https://astral.fan/api/v1`, the production custom
domain for the Vercel project. Set the define to a preview deployment URL when
testing the app against an unpublished API build.
