# Serverless update API

EasyTier Enmesh checks for updates through the standalone Vercel project in
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
GET /api/v1/update?channel=stable|beta|alpha
GET /api/v1/versions?channel=stable|beta|alpha&limit=1..30
```

`limit` defaults to `10`. The service rejects unknown, duplicate, or malformed
query parameters. `stable` contains final GitHub Releases. `beta` combines
successful `main` builds with signed `vMAJOR.MINOR.PATCH-rc.N` GitHub
prereleases. `alpha` contains successful labeled pull-request builds with a
complete set of unexpired platform artifacts.

Every result includes `stage: stable|rc|beta|alpha`. Alpha titles use the pull
request title and Actions run number; beta titles use `Beta build #N`. Their
highlights use the first commit-message line. RC and stable highlights come from
the release changelog block. Pages link to the relevant GitHub Actions run or
GitHub Release; the API never returns artifact download URLs or exposes its
GitHub token. Alpha and beta action versions disappear when their earliest
required artifact expires.

The application’s Update Settings page persists an explicit Stable/Beta/Alpha
selection and uses it for both update checks and version history. Selecting a
preview channel enables automatic checks initially, but the automatic-check
switch remains independently controllable afterward. Existing installations
with the legacy Beta boolean migrate to Beta or Stable on first load.

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

Create a separate Vercel project for this repository, set its **Root Directory**
to `update-server`, and use the **Other** framework preset. The checked-in
`update-server/vercel.json` also disables framework auto-detection. Vercel then
installs `update-server/package.json` and maps `update-server/api/` to `/api/`.
The functions cannot access files outside that root, so all runtime code and
dependencies stay inside the subproject. The dashboard ignored-build-step and
deployment-retention settings are listed in `docs/CI.md`.

Deployments run through the Vercel Git integration: every push to `main`
deploys Production, and pull requests that change `update-server/**` receive
Preview deployments. GitHub Actions does not deploy the update API; see
`docs/CI.md`.

For troubleshooting only, a manual CLI deployment is possible. Run it from the
repository root because the Vercel project applies `update-server` as its Root
Directory. Do not also pass `--cwd update-server`, which would resolve the
project as `update-server/update-server`. A CLI deployment can move the
Production alias until the next push to `main`:

```sh
vercel --project enmesh-update-server
vercel --project enmesh-update-server --prod
```

Set these Vercel environment variables for Production and Preview as needed:

- `GITHUB_TOKEN`: fine-grained read-only token for the repository. It needs
  repository Contents, Actions, and Pull requests read access. Do not expose
  this value to the client.
- `GITHUB_REPOSITORY`: optional `OWNER/REPOSITORY`; defaults to
  `ttimasdf/enmesh`.
- `GITHUB_WORKFLOW`: optional workflow filename; defaults to `build.yml`.
- `GITHUB_DEFAULT_BRANCH`: optional branch; defaults to `main`.

Functions are pinned to Vercel’s Hong Kong region (`hkg1`) in
`update-server/vercel.json`. Runtime Cache is region-local; the GitHub source
cache uses ETags and conditional requests and stays close to the function cache
in that region.

After the production deployment succeeds, attach the chosen custom domain and
verify both routes before compiling that URL into a release build.

## Cache policy

Stable responses use a five-minute Vercel CDN TTL with one hour of
stale-while-revalidate. Alpha and beta responses use a ten-minute TTL and no
stale period; their TTL is clipped to the earliest artifact expiration in the
response. Empty channels and errors are short-lived.

## Configuring the Flutter base URL

`UPDATE_API_BASE_URL` is a **compile-time** Dart define, not an in-app setting.
It must include the API prefix but not the final `/update` or `/versions` path:

```text
https://updates.example.com/api/v1
```

The default API base is
`https://enmesh.rabit.pw/api/v1`. `UPDATE_API_BASE_URL` is an optional
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
  --enmesh-update-api http://10.0.2.2:3100/api/v1 \
  run -d emulator-5554

UPDATE_API_BASE_URL=https://updates.example.com/api/v1 \
  nix develop -c flutter-android build apk --debug
```

Because `String.fromEnvironment` is compiled into the application, changing the
URL requires rebuilding the app; setting an environment variable only when an
already-built app starts has no effect.
