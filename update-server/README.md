# EasyTier Enmesh update server

Repository-specific Vercel Functions that normalize EasyTier Enmesh stable and beta
metadata from GitHub. They never proxy release artifacts.

## Develop

```sh
bun install --frozen-lockfile
bun run typecheck
bun test
bun run dev
```

The local API listens on `http://127.0.0.1:3100/api/v1`.

## Deploy

Use this directory as the Vercel project's **Root Directory**, or deploy it from
the repository root with:

```sh
vercel --cwd update-server
vercel --cwd update-server --prod
```

Configure the read-only `GITHUB_TOKEN` plus the optional
`GITHUB_REPOSITORY`, `GITHUB_WORKFLOW`, and `GITHUB_DEFAULT_BRANCH` variables.
The full deployment and app configuration guide is in the repository's
`docs/UPDATE_API.md`.
