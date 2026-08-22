import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';

import {
  artifactVersion,
  betaCacheTtl,
  commitSubject,
  completeArtifactVersion,
  extractChangelogHighlights,
  handleUpdateRequest,
  setRuntimeCacheForTests,
  type VersionSummary,
} from '../src/update-api.js';

class MemoryCache {
  readonly values = new Map<string, unknown>();

  async get(key: string): Promise<unknown> {
    return this.values.get(key) ?? null;
  }

  async set(key: string, value: unknown): Promise<void> {
    this.values.set(key, value);
  }
}

const originalFetch = globalThis.fetch;

beforeEach(() => {
  setRuntimeCacheForTests(new MemoryCache());
  process.env.GITHUB_REPOSITORY = 'ttimasdf/astral-ng';
  process.env.GITHUB_WORKFLOW = 'build.yml';
  process.env.GITHUB_DEFAULT_BRANCH = 'main';
  process.env.GITHUB_TOKEN = 'test-token';
});

afterEach(() => {
  globalThis.fetch = originalFetch;
  setRuntimeCacheForTests(null);
  delete process.env.GITHUB_TOKEN;
});

function githubJson(value: unknown): Response {
  return Response.json(value, { headers: { ETag: '"fixture"' } });
}

function changelogContent(): string {
  return `# Changelog

## Unreleased

## v3.0.0 - 2026-08-14

> **Highlight:** Stable highlight.
>
> **版本亮点：** 稳定版亮点。

### Added

- Something.

## v2.9.0 - 2026-07-01

> **Highlight:** Older highlight.
>
> **版本亮点：** 较早版本亮点。
`;
}

function artifact(
  id: number,
  runId: number,
  name: string,
  expiresAt = '2026-11-12T00:00:00Z',
  expired = false,
) {
  return {
    id,
    name,
    expired,
    created_at: '2026-08-14T00:00:00Z',
    expires_at: expiresAt,
    workflow_run: {
      id: runId,
      head_branch: 'main',
      head_sha: 'abcdef0123456789',
    },
  };
}

function completeArtifacts(runId: number, version: string, startId = 1) {
  return [
    artifact(startId, runId, `astral-canary-android-debug-${version}.apk`),
    artifact(startId + 1, runId, `astral-canary-windows-x64-${version}.zip`),
    artifact(startId + 2, runId, `astral-canary-windows-x64-setup-${version}.exe`),
    artifact(startId + 3, runId, `astral-canary-linux-x64-${version}.deb`),
    artifact(startId + 4, runId, `astral-canary-linux-x64-${version}.rpm`),
    artifact(startId + 5, runId, `astral-canary-linux-x64-${version}.tar.gz`),
  ];
}

describe('normalized metadata parsing', () => {
  test('extracts the exact bilingual highlight from the requested release section', () => {
    expect(extractChangelogHighlights(changelogContent(), '3.0.0')).toEqual({
      en: 'Stable highlight.',
      zh: '稳定版亮点。',
    });
    expect(extractChangelogHighlights(changelogContent(), '9.9.9')).toBeNull();
  });

  test('uses only the first commit-message line', () => {
    expect(commitSubject('Feature title (#42)\n\nLong body')).toBe(
      'Feature title (#42)',
    );
  });

  test('recognizes canonical canary artifact versions and requires a complete platform set', () => {
    const version = '3.0.0-alpha.66+abcdef0';
    const artifacts = completeArtifacts(100, version);
    expect(artifactVersion(artifacts[0].name)).toBe(version);
    expect(completeArtifactVersion(artifacts)).toBe(version);
    expect(
      completeArtifactVersion([
        ...artifacts,
        artifact(99, 100, 'astral-canary-extra-3.0.0-alpha.67+1234567.zip'),
      ]),
    ).toBe(version);
    expect(completeArtifactVersion(artifacts.slice(1))).toBeNull();
    expect(artifactVersion('random.zip')).toBeNull();
  });

  test('clips beta cache lifetime to the earliest artifact expiration', () => {
    const now = Date.parse('2026-08-14T00:00:00Z');
    const version = {
      channel: 'beta',
      stage: 'beta',
      version: '3.0.0-beta.66+abcdef0',
      title: 'Beta build #66',
      highlights: { en: 'Highlight' },
      publishedAt: '2026-08-14T00:00:00Z',
      expiresAt: '2026-08-14T00:04:00Z',
      pageUrl: 'https://github.com/example/actions/runs/1',
      source: {
        type: 'github_actions',
        id: '1',
        runNumber: 66,
        runAttempt: 1,
        commitSha: 'abcdef0123456789',
      },
    } satisfies VersionSummary;
    expect(betaCacheTtl([version], now)).toBe(240);
  });
});

describe('HTTP contract', () => {
  test('rejects missing, duplicate, and unknown query parameters', async () => {
    const missing = await handleUpdateRequest(
      new Request('https://updates.example/api/v1/update'),
      'latest',
    );
    expect(missing.status).toBe(400);

    const duplicate = await handleUpdateRequest(
      new Request(
        'https://updates.example/api/v1/update?channel=stable&channel=beta',
      ),
      'latest',
    );
    expect(duplicate.status).toBe(400);

    const unknown = await handleUpdateRequest(
      new Request(
        'https://updates.example/api/v1/update?channel=stable&nonce=1',
      ),
      'latest',
    );
    expect(unknown.status).toBe(400);

    const invalidLimit = await handleUpdateRequest(
      new Request(
        'https://updates.example/api/v1/versions?channel=stable&limit=31',
      ),
      'versions',
    );
    expect(invalidLimit.status).toBe(400);

    const emptyLimit = await handleUpdateRequest(
      new Request(
        'https://updates.example/api/v1/versions?channel=stable&limit=',
      ),
      'versions',
    );
    expect(emptyLimit.status).toBe(400);
  });

  test('supports HEAD and rejects state-changing methods', async () => {
    globalThis.fetch = mock(async (input: string | URL | Request) => {
      const url = new URL(input instanceof Request ? input.url : input.toString());
      if (url.pathname.endsWith('/releases')) {
        return githubJson([
          {
            id: 3,
            tag_name: 'v3.0.0',
            draft: false,
            prerelease: false,
            published_at: '2026-08-14T01:00:00Z',
            html_url: 'https://github.com/example/releases/tag/v3.0.0',
          },
        ]);
      }
      return githubJson({
        encoding: 'base64',
        content: Buffer.from(changelogContent()).toString('base64'),
      });
    }) as unknown as typeof fetch;

    const head = await handleUpdateRequest(
      new Request('https://updates.example/api/v1/update?channel=stable', {
        method: 'HEAD',
      }),
      'latest',
    );
    expect(head.status).toBe(200);
    expect(await head.text()).toBe('');

    const post = await handleUpdateRequest(
      new Request('https://updates.example/api/v1/update?channel=stable', {
        method: 'POST',
      }),
      'latest',
    );
    expect(post.status).toBe(405);
  });

  test('normalizes stable releases and ignores drafts, prereleases, noncanonical tags, and untrusted pages', async () => {
    globalThis.fetch = mock(async (input: string | URL | Request) => {
      const url = new URL(input instanceof Request ? input.url : input.toString());
      if (url.pathname.endsWith('/releases')) {
        return githubJson([
          {
            id: 3,
            tag_name: 'v3.0.0',
            draft: false,
            prerelease: false,
            published_at: '2026-08-14T01:00:00Z',
            html_url: 'https://github.com/example/releases/tag/v3.0.0',
          },
          {
            id: 4,
            tag_name: 'v3.1.0-beta.1',
            draft: false,
            prerelease: true,
            published_at: '2026-08-14T02:00:00Z',
            html_url: 'https://github.com/example/releases/tag/v3.1.0-beta.1',
          },
          {
            id: 5,
            tag_name: '3.2.0',
            draft: false,
            prerelease: false,
            published_at: '2026-08-14T03:00:00Z',
            html_url: 'https://github.com/example/releases/tag/3.2.0',
          },
          {
            id: 6,
            tag_name: 'v3.3.0',
            draft: false,
            prerelease: false,
            published_at: '2026-08-14T04:00:00Z',
            html_url: 'https://example.invalid/releases/tag/v3.3.0',
          },
        ]);
      }
      if (url.pathname.endsWith('/contents/CHANGELOG.md')) {
        return githubJson({
          encoding: 'base64',
          content: Buffer.from(changelogContent()).toString('base64'),
        });
      }
      return new Response('not found', { status: 404 });
    }) as unknown as typeof fetch;

    const response = await handleUpdateRequest(
      new Request('https://updates.example/api/v1/update?channel=stable'),
      'latest',
    );
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(response.headers.get('Vercel-CDN-Cache-Control')).toBe(
      'public, s-maxage=300, stale-while-revalidate=3600',
    );
    expect(body.data).toMatchObject({
      channel: 'stable',
      stage: 'stable',
      version: '3.0.0',
      title: 'Release v3.0.0',
      highlights: { en: 'Stable highlight.', zh: '稳定版亮点。' },
      expiresAt: null,
      source: { type: 'github_release', id: '3', ref: 'v3.0.0' },
    });
  });

  test('returns PR alpha builds with the PR title and Actions build number', async () => {
    const version = '3.0.0-alpha.70+abcdef0';
    globalThis.fetch = mock(async (input: string | URL | Request) => {
      const url = new URL(input instanceof Request ? input.url : input.toString());
      if (url.pathname.includes('/actions/workflows/')) {
        expect(url.searchParams.get('event')).toBe('pull_request');
        return githubJson({
          total_count: 1,
          workflow_runs: [
            {
              id: 201,
              run_number: 70,
              run_attempt: 1,
              status: 'completed',
              conclusion: 'success',
              event: 'pull_request',
              head_branch: 'feature/version-stages',
              head_sha: 'abcdef0123456789',
              head_commit: { message: 'Refine staged releases\n\nDetails' },
              pull_requests: [{ number: 16 }],
              html_url: 'https://github.com/example/actions/runs/201',
              created_at: '2026-08-14T00:00:00Z',
              updated_at: '2026-08-14T00:20:00Z',
            },
          ],
        });
      }
      if (url.pathname.endsWith('/actions/artifacts')) {
        return githubJson({
          total_count: 6,
          artifacts: completeArtifacts(201, version),
        });
      }
      if (url.pathname.endsWith('/pulls/16')) {
        return githubJson({
          number: 16,
          title: 'Design staged release channels',
          html_url: 'https://github.com/example/pull/16',
        });
      }
      return new Response('not found', { status: 404 });
    }) as unknown as typeof fetch;

    const response = await handleUpdateRequest(
      new Request('https://updates.example/api/v1/update?channel=alpha'),
      'latest',
    );
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.data).toMatchObject({
      channel: 'alpha',
      stage: 'alpha',
      version,
      title: 'Design staged release channels · Build #70',
      highlights: { en: 'Refine staged releases' },
      source: { type: 'github_actions', id: '201', runNumber: 70 },
    });
  });

  test('returns signed release candidates in the beta channel', async () => {
    globalThis.fetch = mock(async (input: string | URL | Request) => {
      const url = new URL(input instanceof Request ? input.url : input.toString());
      if (url.pathname.endsWith('/releases')) {
        return githubJson([
          {
            id: 301,
            tag_name: 'v3.1.0-rc.1',
            draft: false,
            prerelease: true,
            published_at: '2026-08-14T02:00:00Z',
            html_url: 'https://github.com/example/releases/tag/v3.1.0-rc.1',
            body: '> **Highlight:** Candidate highlight.\n>\n> **版本亮点：** 候选版本亮点。',
          },
        ]);
      }
      if (url.pathname.includes('/actions/workflows/')) {
        return githubJson({ total_count: 0, workflow_runs: [] });
      }
      if (url.pathname.endsWith('/actions/artifacts')) {
        return githubJson({ total_count: 0, artifacts: [] });
      }
      return new Response('not found', { status: 404 });
    }) as unknown as typeof fetch;

    const response = await handleUpdateRequest(
      new Request('https://updates.example/api/v1/update?channel=beta'),
      'latest',
    );
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.data).toMatchObject({
      channel: 'beta',
      stage: 'rc',
      version: '3.1.0-rc.1',
      title: 'Release candidate v3.1.0-rc.1',
      highlights: { en: 'Candidate highlight.', zh: '候选版本亮点。' },
      expiresAt: null,
      source: { type: 'github_release', id: '301', ref: 'v3.1.0-rc.1' },
    });
  });

  test('uses only required artifacts to determine beta expiry', async () => {
    const version = '3.0.0-beta.67+abcdef0';
    globalThis.fetch = mock(async (input: string | URL | Request) => {
      const url = new URL(input instanceof Request ? input.url : input.toString());
      if (url.pathname.endsWith('/releases')) return githubJson([]);
      if (url.pathname.includes('/actions/workflows/')) {
        expect(url.searchParams.get('page')).toBe('1');
        return githubJson({
          total_count: 1,
          workflow_runs: [
            {
              id: 101,
              run_number: 67,
              run_attempt: 1,
              status: 'completed',
              conclusion: 'success',
              event: 'push',
              head_branch: 'main',
              head_sha: 'abcdef0123456789',
              head_commit: { message: 'Keep required artifacts available' },
              html_url: 'https://github.com/example/actions/runs/101',
              created_at: '2026-08-14T00:00:00Z',
              updated_at: '2026-08-14T00:20:00Z',
            },
          ],
        });
      }
      if (url.pathname.endsWith('/actions/artifacts')) {
        expect(url.searchParams.get('page')).toBe('1');
        return githubJson({
          total_count: 7,
          artifacts: [
            ...completeArtifacts(101, version),
            artifact(
              99,
              101,
              `astral-canary-extra-${version}.zip`,
              '2026-08-14T00:01:00Z',
            ),
          ],
        });
      }
      return new Response('not found', { status: 404 });
    }) as unknown as typeof fetch;

    const response = await handleUpdateRequest(
      new Request('https://updates.example/api/v1/update?channel=beta'),
      'latest',
    );
    expect(response.status).toBe(200);
    const body = (await response.json()) as { data: { expiresAt: string } };
    expect(body.data.expiresAt).toBe('2026-11-12T00:00:00Z');
  });

  test('returns complete active beta builds, removes expired builds, and shares its index cache', async () => {
    const version = '3.0.0-beta.66+abcdef0';
    const expiredVersion = '3.0.0-beta.65+1234567';
    let githubRequests = 0;
    globalThis.fetch = mock(async (input: string | URL | Request) => {
      githubRequests += 1;
      const url = new URL(input instanceof Request ? input.url : input.toString());
      if (url.pathname.endsWith('/releases')) return githubJson([]);
      if (url.pathname.includes('/actions/workflows/')) {
        expect(url.searchParams.get('page')).toBe('1');
        return githubJson({
          total_count: 3,
          workflow_runs: [
            {
              id: 100,
              run_number: 66,
              run_attempt: 1,
              status: 'completed',
              conclusion: 'success',
              event: 'push',
              head_branch: 'main',
              head_sha: 'abcdef0123456789',
              head_commit: {
                message: 'Improve update checks (#42)\n\nDetailed body',
              },
              html_url: 'https://github.com/example/actions/runs/100',
              created_at: '2026-08-14T00:00:00Z',
              updated_at: '2026-08-14T00:20:00Z',
            },
            {
              id: 99,
              run_number: 65,
              run_attempt: 1,
              status: 'completed',
              conclusion: 'success',
              event: 'push',
              head_branch: 'main',
              head_sha: '1234567890abcdef',
              head_commit: { message: 'Expired beta' },
              html_url: 'https://github.com/example/actions/runs/99',
              created_at: '2026-07-01T00:00:00Z',
              updated_at: '2026-07-01T00:20:00Z',
            },
            {
              id: 98,
              run_number: 64,
              run_attempt: 1,
              status: 'completed',
              conclusion: 'success',
              event: 'pull_request',
              head_branch: 'feature/untrusted',
              head_sha: '9999999999999999',
              head_commit: { message: 'PR build' },
              html_url: 'https://github.com/example/actions/runs/98',
              created_at: '2026-08-14T00:00:00Z',
              updated_at: '2026-08-14T00:20:00Z',
            },
          ],
        });
      }
      if (url.pathname.endsWith('/actions/artifacts')) {
        expect(url.searchParams.get('page')).toBe('1');
        return githubJson({
          total_count: 12,
          artifacts: [
            ...completeArtifacts(100, version),
            ...completeArtifacts(99, expiredVersion, 20).map((value) => ({
              ...value,
              expired: true,
              expires_at: '2026-07-08T00:00:00Z',
            })),
          ],
        });
      }
      return new Response('not found', { status: 404 });
    }) as unknown as typeof fetch;

    const latest = await handleUpdateRequest(
      new Request('https://updates.example/api/v1/update?channel=beta'),
      'latest',
    );
    const latestBody = await latest.json();
    expect(latest.status).toBe(200);
    expect(latestBody.data).toMatchObject({
      version,
      stage: 'beta',
      title: 'Beta build #66',
      highlights: { en: 'Improve update checks (#42)' },
      source: {
        type: 'github_actions',
        id: '100',
        runNumber: 66,
        commitSha: 'abcdef0123456789',
      },
    });
    expect(latest.headers.get('Vercel-CDN-Cache-Control')).toBe(
      'public, s-maxage=600',
    );

    const list = await handleUpdateRequest(
      new Request(
        'https://updates.example/api/v1/versions?channel=beta&limit=30',
      ),
      'versions',
    );
    const listBody = await list.json();
    expect(listBody.data).toHaveLength(1);
    expect(githubRequests).toBe(3);
  });
});
