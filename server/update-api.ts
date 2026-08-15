import { getCache } from '@vercel/functions';

const API_VERSION = '2022-11-28';
const SCHEMA_VERSION = 1;
const DEFAULT_REPOSITORY = 'ttimasdf/astral-ng';
const DEFAULT_WORKFLOW = 'build-and-release.yml';
const DEFAULT_BRANCH = 'main';
const STABLE_INDEX_TTL_SECONDS = 300;
const BETA_INDEX_TTL_SECONDS = 600;
const EMPTY_CHANNEL_TTL_SECONDS = 60;
const MAX_LIMIT = 30;
const GITHUB_API = 'https://api.github.com';

export type Channel = 'stable' | 'beta';

type Highlights = {
  en: string;
  zh?: string;
};

export type VersionSummary = {
  channel: Channel;
  version: string;
  title: string;
  highlights: Highlights | null;
  publishedAt: string;
  expiresAt: string | null;
  pageUrl: string;
  source:
    | {
        type: 'github_release';
        id: string;
        ref: string;
      }
    | {
        type: 'github_actions';
        id: string;
        runNumber: number;
        runAttempt: number;
        commitSha: string;
      };
};

type GitHubRelease = {
  id: number;
  tag_name: string;
  draft: boolean;
  prerelease: boolean;
  published_at: string | null;
  html_url: string;
};

type GitHubWorkflowRun = {
  id: number;
  run_number: number;
  run_attempt: number;
  status: string;
  conclusion: string | null;
  event: string;
  head_branch: string | null;
  head_sha: string;
  head_commit?: {
    message?: string | null;
  } | null;
  html_url: string;
  created_at: string;
  updated_at: string;
};

type GitHubArtifact = {
  id: number;
  name: string;
  expired: boolean;
  created_at: string;
  expires_at: string | null;
  workflow_run?: {
    id: number;
    head_branch?: string | null;
    head_sha?: string;
  } | null;
};

type CachedGitHubValue<T> = {
  etag: string | null;
  data: T;
};

type GitHubListResponse<T> = {
  total_count: number;
  workflow_runs?: T[];
  artifacts?: T[];
};

type RuntimeCache = {
  get(key: string): Promise<unknown>;
  set(key: string, value: unknown, options: { ttl: number; tags?: string[] }): Promise<void>;
};

const localCache = new Map<string, { expiresAt: number; value: unknown }>();
let cacheOverride: RuntimeCache | null = null;

export function setRuntimeCacheForTests(cache: RuntimeCache | null): void {
  cacheOverride = cache;
  localCache.clear();
}

function runtimeCache(): RuntimeCache {
  if (cacheOverride) return cacheOverride;

  try {
    return getCache() as RuntimeCache;
  } catch {
    return {
      async get(key: string) {
        const item = localCache.get(key);
        if (!item || item.expiresAt <= Date.now()) {
          localCache.delete(key);
          return null;
        }
        return item.value;
      },
      async set(key: string, value: unknown, options: { ttl: number }) {
        localCache.set(key, {
          value,
          expiresAt: Date.now() + options.ttl * 1000,
        });
      },
    };
  }
}

function repository(): string {
  const value = process.env.GITHUB_REPOSITORY?.trim() || DEFAULT_REPOSITORY;
  if (!/^[^/]+\/[^/]+$/.test(value)) {
    throw new Error('GITHUB_REPOSITORY must use OWNER/REPOSITORY format');
  }
  return value;
}

function workflow(): string {
  return process.env.GITHUB_WORKFLOW?.trim() || DEFAULT_WORKFLOW;
}

function branch(): string {
  return process.env.GITHUB_DEFAULT_BRANCH?.trim() || DEFAULT_BRANCH;
}

function githubHeaders(etag?: string | null): Headers {
  const headers = new Headers({
    Accept: 'application/vnd.github+json',
    'X-GitHub-Api-Version': API_VERSION,
    'User-Agent': 'astral-ng-update-api',
  });
  const token = process.env.GITHUB_TOKEN?.trim();
  if (token) headers.set('Authorization', `Bearer ${token}`);
  if (etag) headers.set('If-None-Match', etag);
  return headers;
}

async function githubRequest<T>(
  path: string,
  cacheKey: string,
  ttl: number,
): Promise<T> {
  const cache = runtimeCache();
  const cached = (await cache.get(cacheKey)) as CachedGitHubValue<T> | null;
  const response = await fetch(`${GITHUB_API}${path}`, {
    headers: githubHeaders(cached?.etag),
    signal: AbortSignal.timeout(15_000),
  });

  if (response.status === 304 && cached) return cached.data;
  if (!response.ok) {
    const error = new GitHubError(response.status, path);
    throw error;
  }

  const data = (await response.json()) as T;
  await cache.set(
    cacheKey,
    {
      etag: response.headers.get('etag'),
      data,
    } satisfies CachedGitHubValue<T>,
    { ttl },
  );
  return data;
}

class GitHubError extends Error {
  constructor(
    readonly status: number,
    readonly path: string,
  ) {
    super(`GitHub request failed with HTTP ${status}`);
    this.name = 'GitHubError';
  }
}

export function parseLimit(value: string | null): number | null {
  if (value === null || value === '') return 10;
  if (!/^\d+$/.test(value)) return null;
  const limit = Number(value);
  return Number.isSafeInteger(limit) && limit >= 1 && limit <= MAX_LIMIT
    ? limit
    : null;
}

function parseChannel(value: string | null): Channel | null {
  return value === 'stable' || value === 'beta' ? value : null;
}

function validateSearchParams(
  request: Request,
  route: 'latest' | 'versions',
): { channel: Channel; limit: number } | Response {
  const url = new URL(request.url);
  const allowed = route === 'latest' ? new Set(['channel']) : new Set(['channel', 'limit']);
  for (const key of url.searchParams.keys()) {
    if (!allowed.has(key) || url.searchParams.getAll(key).length !== 1) {
      return errorResponse('invalid_query', 'The request query is invalid.', 400);
    }
  }

  const channel = parseChannel(url.searchParams.get('channel'));
  if (!channel) {
    return errorResponse(
      'invalid_channel',
      'The channel must be either stable or beta.',
      400,
    );
  }

  const limit = parseLimit(url.searchParams.get('limit'));
  if (route === 'versions' && limit === null) {
    return errorResponse(
      'invalid_limit',
      `The limit must be an integer from 1 to ${MAX_LIMIT}.`,
      400,
    );
  }

  return { channel, limit: route === 'latest' ? 1 : limit! };
}

function semverParts(value: string): {
  major: number;
  minor: number;
  patch: number;
  prerelease: string[];
} | null {
  const match = /^v?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$/.exec(
    value,
  );
  if (!match) return null;
  return {
    major: Number(match[1]),
    minor: Number(match[2]),
    patch: Number(match[3]),
    prerelease: match[4]?.split('.') ?? [],
  };
}

export function compareVersions(left: string, right: string): number {
  const a = semverParts(left);
  const b = semverParts(right);
  if (!a || !b) return left.localeCompare(right);

  for (const key of ['major', 'minor', 'patch'] as const) {
    if (a[key] !== b[key]) return a[key] - b[key];
  }
  if (a.prerelease.length === 0 && b.prerelease.length > 0) return 1;
  if (a.prerelease.length > 0 && b.prerelease.length === 0) return -1;
  for (let index = 0; index < Math.max(a.prerelease.length, b.prerelease.length); index += 1) {
    const leftPart = a.prerelease[index];
    const rightPart = b.prerelease[index];
    if (leftPart === undefined) return -1;
    if (rightPart === undefined) return 1;
    const leftNumeric = /^\d+$/.test(leftPart);
    const rightNumeric = /^\d+$/.test(rightPart);
    if (leftNumeric && rightNumeric) {
      const difference = Number(leftPart) - Number(rightPart);
      if (difference !== 0) return difference;
    } else if (leftNumeric !== rightNumeric) {
      return leftNumeric ? -1 : 1;
    } else if (leftPart !== rightPart) {
      return leftPart.localeCompare(rightPart);
    }
  }
  return 0;
}

function sortVersions(values: VersionSummary[]): VersionSummary[] {
  return [...values].sort((left, right) => {
    const versionOrder = compareVersions(right.version, left.version);
    if (versionOrder !== 0) return versionOrder;
    return right.publishedAt.localeCompare(left.publishedAt);
  });
}

function releaseVersion(tag: string): string | null {
  const value = tag.startsWith('v') ? tag.slice(1) : tag;
  const parts = semverParts(value);
  if (!parts || parts.prerelease.length > 0) return null;
  return value;
}

function extractChangelogHighlights(markdown: string, version: string): Highlights | null {
  const heading = new RegExp(`^## v${escapeRegExp(version)}(?:\\s|$)`, 'm');
  const headingMatch = heading.exec(markdown);
  if (!headingMatch) return null;
  const section = markdown.slice(headingMatch.index);
  const nextHeading = /^##\s/m.exec(section.slice(headingMatch[0].length));
  const content = nextHeading
    ? section.slice(0, headingMatch[0].length + nextHeading.index)
    : section;
  const match = /> \*\*Highlight:\*\* ([^\r\n]+)\r?\n>\r?\n> \*\*版本亮点：\*\* ([^\r\n]+)$/m.exec(
    content,
  );
  return match ? { en: match[1], zh: match[2] } : null;
}

function extractUnreleasedHighlight(markdown: string): string | null {
  const sectionMatch = /^## Unreleased\s*$/m.exec(markdown);
  if (!sectionMatch) return null;
  const section = markdown.slice(sectionMatch.index);
  const nextHeading = /^##\s/m.exec(section.slice(sectionMatch[0].length));
  const content = nextHeading ? section.slice(0, sectionMatch[0].length + nextHeading.index) : section;
  const match = /> \*\*Highlight:\*\* ([^\r\n]+)$/m.exec(content);
  return match?.[1] ?? null;
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function commitSubject(message: string | null | undefined): string {
  return (message ?? '').split(/\r?\n/, 1)[0]?.trim() ?? '';
}

const CANARY_ARTIFACT_PATTERN =
  /^astral-canary-.+-(\d+\.\d+\.\d+-alpha\.\d+\+[0-9a-f]{7})\.(?:apk|exe|zip|deb|rpm|tar\.gz)$/i;

function artifactVersion(name: string): string | null {
  const match = CANARY_ARTIFACT_PATTERN.exec(name);
  return match?.[1] ?? null;
}

const REQUIRED_CANARY_ARTIFACTS = [
  /^astral-canary-android-debug-.+\.apk$/,
  /^astral-canary-windows-x64-.+\.zip$/,
  /^astral-canary-windows-x64-setup-.+\.exe$/,
  /^astral-canary-linux-x64-.+\.deb$/,
  /^astral-canary-linux-x64-.+\.rpm$/,
  /^astral-canary-linux-x64-.+\.tar\.gz$/,
];

function completeArtifactVersion(artifacts: GitHubArtifact[]): string | null {
  if (
    !REQUIRED_CANARY_ARTIFACTS.every((pattern) =>
      artifacts.some((artifact) => pattern.test(artifact.name)),
    )
  ) {
    return null;
  }
  const versions = new Set(
    artifacts.map((artifact) => artifactVersion(artifact.name)).filter(Boolean),
  );
  return versions.size === 1 ? [...versions][0]! : null;
}

function usableArtifact(artifact: GitHubArtifact, now: number): boolean {
  if (artifact.expired || !artifact.expires_at) return false;
  return Date.parse(artifact.expires_at) > now;
}

function githubPageForRuns(): string {
  return `https://github.com/${repository()}/actions`;
}

async function stableVersions(max: number): Promise<VersionSummary[]> {
  const repo = repository();
  const releases = await githubRequest<GitHubRelease[]>(
    `/repos/${repo}/releases?per_page=100`,
    'github:stable:releases:v1',
    86_400,
  );
  const changelogResponse = await githubRequest<{ content?: string; encoding?: string }>(
    `/repos/${repo}/contents/CHANGELOG.md?ref=${encodeURIComponent(branch())}`,
    'github:stable:changelog:v1',
    86_400,
  );
  const changelog = changelogResponse.content
    ? decodeBase64(changelogResponse.content, changelogResponse.encoding)
    : '';

  return sortVersions(
    releases
      .map((release): VersionSummary | null => {
        const version = releaseVersion(release.tag_name);
        if (release.draft || release.prerelease || !version || !release.published_at) return null;
        return {
          channel: 'stable',
          version,
          title: `Release v${version}`,
          highlights: extractChangelogHighlights(changelog, version),
          publishedAt: release.published_at,
          expiresAt: null,
          pageUrl: release.html_url,
          source: {
            type: 'github_release',
            id: String(release.id),
            ref: release.tag_name,
          },
        };
      })
      .filter((value): value is VersionSummary => value !== null),
  ).slice(0, max);
}

function decodeBase64(value: string, encoding = 'base64'): string {
  if (encoding !== 'base64') return value;
  return Buffer.from(value.replace(/\s/g, ''), 'base64').toString('utf8');
}

async function fetchAllArtifacts(repo: string, now: number): Promise<GitHubArtifact[]> {
  const artifacts: GitHubArtifact[] = [];
  for (let page = 1; page <= 10; page += 1) {
    const response = await githubRequest<GitHubListResponse<GitHubArtifact>>(
      `/repos/${repo}/actions/artifacts?per_page=100&page=${page}`,
      `github:beta:artifacts:v1:${page}`,
      86_400,
    );
    const pageArtifacts = response.artifacts ?? [];
    artifacts.push(...pageArtifacts.filter((artifact) => usableArtifact(artifact, now)));
    if (pageArtifacts.length < 100) break;
    const oldestExpiry = pageArtifacts
      .map((artifact) => (artifact.expires_at ? Date.parse(artifact.expires_at) : 0))
      .filter((value) => value > 0)
      .sort((left, right) => left - right)[0];
    if (oldestExpiry !== undefined && oldestExpiry <= now) break;
  }
  return artifacts;
}

async function betaVersions(max: number): Promise<VersionSummary[]> {
  const repo = repository();
  const runsResponse = await githubRequest<GitHubListResponse<GitHubWorkflowRun>>(
    `/repos/${repo}/actions/workflows/${encodeURIComponent(workflow())}/runs?branch=${encodeURIComponent(branch())}&event=push&status=success&exclude_pull_requests=true&per_page=100`,
    'github:beta:runs:v1',
    86_400,
  );
  const runs = (runsResponse.workflow_runs ?? []).filter(
    (run) =>
      run.status === 'completed' &&
      run.conclusion === 'success' &&
      run.event === 'push' &&
      run.head_branch === branch(),
  );
  const artifacts = await fetchAllArtifacts(repo, Date.now());
  const artifactsByRun = new Map<number, GitHubArtifact[]>();
  for (const artifact of artifacts) {
    const runId = artifact.workflow_run?.id;
    if (runId === undefined) continue;
    const group = artifactsByRun.get(runId) ?? [];
    group.push(artifact);
    artifactsByRun.set(runId, group);
  }

  const versions: VersionSummary[] = [];
  for (const run of runs) {
    const runArtifacts = artifactsByRun.get(run.id) ?? [];
    const version = completeArtifactVersion(runArtifacts);
    if (!version) continue;
    const parts = semverParts(version);
    if (!parts || parts.prerelease.length !== 2 || parts.prerelease[0] !== 'alpha') continue;
    if (Number(parts.prerelease[1]) !== run.run_number) continue;
    if (version.slice(-7).toLowerCase() !== run.head_sha.slice(0, 7).toLowerCase()) continue;

    const expiresAt = runArtifacts
      .map((artifact) => artifact.expires_at)
      .filter((value): value is string => value !== null)
      .sort()[0];
    if (!expiresAt || Date.parse(expiresAt) <= Date.now()) continue;
    versions.push({
      channel: 'beta',
      version,
      title: `Beta v${version}`,
      highlights: { en: commitSubject(run.head_commit?.message) || `Beta v${version}` },
      publishedAt: run.updated_at,
      expiresAt,
      pageUrl: run.html_url || githubPageForRuns(),
      source: {
        type: 'github_actions',
        id: String(run.id),
        runNumber: run.run_number,
        runAttempt: run.run_attempt,
        commitSha: run.head_sha,
      },
    });
  }

  return sortVersions(versions).slice(0, max);
}

async function loadVersions(channel: Channel): Promise<VersionSummary[]> {
  const key = `index:v1:${channel}`;
  const cache = runtimeCache();
  const cached = (await cache.get(key)) as VersionSummary[] | null;
  if (cached) return cached.filter((item) => !item.expiresAt || Date.parse(item.expiresAt) > Date.now());

  const values = channel === 'stable' ? await stableVersions(30) : await betaVersions(30);
  await cache.set(key, values, {
    ttl: channel === 'stable' ? STABLE_INDEX_TTL_SECONDS : BETA_INDEX_TTL_SECONDS,
    tags: [`updates-${channel}`],
  });
  return values.filter((item) => !item.expiresAt || Date.parse(item.expiresAt) > Date.now());
}

function responseTtl(channel: Channel, values: VersionSummary[], status: number): number {
  if (status !== 200 || values.length === 0) return EMPTY_CHANNEL_TTL_SECONDS;
  if (channel === 'stable') return STABLE_INDEX_TTL_SECONDS;
  const earliest = values
    .map((value) => (value.expiresAt ? Date.parse(value.expiresAt) : Number.POSITIVE_INFINITY))
    .sort((left, right) => left - right)[0];
  if (!Number.isFinite(earliest)) return BETA_INDEX_TTL_SECONDS;
  return Math.max(0, Math.min(BETA_INDEX_TTL_SECONDS, Math.floor((earliest - Date.now()) / 1000)));
}

export function betaCacheTtl(values: VersionSummary[], now = Date.now()): number {
  const earliest = values
    .map((value) => (value.expiresAt ? Date.parse(value.expiresAt) : Number.POSITIVE_INFINITY))
    .sort((left, right) => left - right)[0];
  if (!Number.isFinite(earliest)) return BETA_INDEX_TTL_SECONDS;
  return Math.max(0, Math.min(BETA_INDEX_TTL_SECONDS, Math.floor((earliest - now) / 1000)));
}

function errorResponse(code: string, message: string, status: number): Response {
  return new Response(
    JSON.stringify({ schemaVersion: SCHEMA_VERSION, error: { code, message, retryable: status >= 500 } }),
    {
      status,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-store',
        'Access-Control-Allow-Origin': '*',
      },
    },
  );
}

function jsonResponse(
  body: unknown,
  status: number,
  channel: Channel,
  values: VersionSummary[],
  head = false,
): Response {
  const ttl = responseTtl(channel, values, status);
  const cacheControl =
    status === 200 && values.length > 0
      ? channel === 'stable'
        ? `public, s-maxage=${ttl}, stale-while-revalidate=3600`
        : `public, s-maxage=${ttl}`
      : `public, s-maxage=${EMPTY_CHANNEL_TTL_SECONDS}`;
  const headers = new Headers({
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'public, max-age=0, must-revalidate',
    'Vercel-CDN-Cache-Control': cacheControl,
    'Access-Control-Allow-Origin': '*',
    Vary: 'Accept-Encoding',
  });
  return new Response(head ? null : JSON.stringify(body), { status, headers });
}

function handleGitHubError(error: unknown): Response {
  if (error instanceof GitHubError && (error.status === 403 || error.status === 429)) {
    return errorResponse('github_rate_limited', 'GitHub is temporarily rate limited.', 503);
  }
  if (error instanceof GitHubError) {
    return errorResponse('github_unavailable', 'GitHub is temporarily unavailable.', 502);
  }
  console.error('Update API source failure', error);
  return errorResponse('internal_error', 'The update service failed unexpectedly.', 500);
}

export async function handleUpdateRequest(
  request: Request,
  route: 'latest' | 'versions',
): Promise<Response> {
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        Allow: 'GET, HEAD, OPTIONS',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
        'Access-Control-Allow-Headers': 'Accept, Content-Type',
      },
    });
  }
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    return errorResponse('method_not_allowed', 'Only GET and HEAD are supported.', 405);
  }

  const validated = validateSearchParams(request, route);
  if (validated instanceof Response) return validated;

  try {
    const values = await loadVersions(validated.channel);
    if (route === 'latest') {
      const latest = values[0];
      if (!latest) {
        return jsonResponse(
          {
            schemaVersion: SCHEMA_VERSION,
            error: {
              code: 'channel_unavailable',
              message: `No active ${validated.channel} version is currently available.`,
              retryable: false,
            },
          },
          404,
          validated.channel,
          [],
          request.method === 'HEAD',
        );
      }
      return jsonResponse(
        { schemaVersion: SCHEMA_VERSION, data: latest },
        200,
        validated.channel,
        [latest],
        request.method === 'HEAD',
      );
    }

    const list = values.slice(0, validated.limit);
    return jsonResponse(
      {
        schemaVersion: SCHEMA_VERSION,
        channel: validated.channel,
        limit: validated.limit,
        data: list,
      },
      200,
      validated.channel,
      list,
      request.method === 'HEAD',
    );
  } catch (error) {
    return handleGitHubError(error);
  }
}

export {
  extractChangelogHighlights,
  extractUnreleasedHighlight,
  artifactVersion,
  commitSubject,
  completeArtifactVersion,
};
