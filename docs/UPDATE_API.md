# Serverless update API

Astral-ng checks for updates through the standalone Vercel project in
`update-server/`. The functions expose normalized metadata only; they never
proxy or install release artifacts.

## Project layout

```text
update-server/
├── api/v1/            # Public Vercel Function entrypoints
├── src/               # Shared GitHub/cache implementation and local server
├── test/              # API contract tests
├── package.json
├── tsconfig.json
└── vercel.json
```

Vercel reserves `api/` for function entrypoints. Keeping the substantial shared
implementation in `src/` prevents it from becoming another public endpoint.
Both directories are contained by `update-server/`, so the Flutter repository
root is not itself a Node/Vercel project.

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

## Local development

Install and run commands from the project subdirectory:

```sh
cd update-server
bun install --frozen-lockfile
bun run typecheck
bun test
bun run dev
```

The local endpoint is `http://127.0.0.1:3100/api/v1`.

## Vercel deployment

Create a separate Vercel project for this repository and set its **Root
Directory** to `update-server`. Vercel then sees `update-server/vercel.json`,
installs `update-server/package.json`, and maps `update-server/api/` to `/api/`.
The functions cannot access files outside that root, so all runtime code and
dependencies stay inside the subproject.

For a manual CLI deployment, either enter the directory or use Vercel's `--cwd`
option:

```sh
vercel --cwd update-server
vercel --cwd update-server --prod

# Equivalent:
(cd update-server && vercel --prod)
```

Set these Vercel environment variables for Production and Preview as needed:

- `GITHUB_TOKEN`: fine-grained read-only token for the repository. It needs
  repository Contents read access and Actions read access. Do not expose this
  value to the client.
- `GITHUB_REPOSITORY`: optional `OWNER/REPOSITORY`; defaults to
  `ttimasdf/astral-ng`.
- `GITHUB_WORKFLOW`: optional workflow filename; defaults to
  `build-and-release.yml`.
- `GITHUB_DEFAULT_BRANCH`: optional branch; defaults to `main`.

The functions are pinned to Vercel region `iad1` in
`update-server/vercel.json`. Runtime Cache keeps GitHub source results and the
normalized channel indexes in that region. The GitHub cache uses ETags and
conditional requests.

After the production deployment succeeds, attach the chosen custom domain and
verify both routes before compiling that URL into a release build.

## Cache policy

Stable responses use a five-minute Vercel CDN TTL with one hour of
stale-while-revalidate. Beta responses use a ten-minute TTL and no stale period;
the TTL is clipped to the earliest artifact expiration in the response. Empty
channels and errors are short-lived.

## Configuring the Flutter base URL

`UPDATE_API_BASE_URL` is a **compile-time** Dart define, not an in-app setting.
It must include the API prefix but not the final `/update` or `/versions` path:

```text
https://updates.example.com/api/v1
```

The default API base is
`https://update.astral-ng.rabit.pw/api/v1`. `UPDATE_API_BASE_URL` is an optional
compile-time override for a local, preview, or alternate deployment.

### GitHub Actions builds

Optionally set the repository or environment Actions variable
`UPDATE_API_BASE_URL`:

```sh
gh variable set UPDATE_API_BASE_URL \
  --body 'https://updates.example.com/api/v1'
```

The build workflow uses the default when the variable is absent and passes an
override to every Linux, Windows, and Android Flutter build when configured.

### Local Linux/desktop builds

The Nix Flutter wrapper forwards either the environment variable or an
explicit Dart define when supplied:

```sh
UPDATE_API_BASE_URL=http://127.0.0.1:3100/api/v1 \
  nix develop -c flutter run -d linux

nix develop -c flutter run -d linux \
  --dart-define=UPDATE_API_BASE_URL=https://updates.example.com/api/v1
```

An explicit `--dart-define` wins over the wrapper environment variable.

### Local Android builds

Use the Android wrapper option or its environment variable. For the Android
emulator, `10.0.2.2` reaches the development host:

```sh
nix develop -c flutter-android \
  --astral-update-api http://10.0.2.2:3100/api/v1 \
  run -d emulator-5554

UPDATE_API_BASE_URL=https://updates.example.com/api/v1 \
  nix develop -c flutter-android build apk --debug
```

Because `String.fromEnvironment` is compiled into the application, changing the
URL requires rebuilding the app; setting an environment variable only when an
already-built app starts has no effect.
