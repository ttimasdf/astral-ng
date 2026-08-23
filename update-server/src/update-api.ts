import { getCache } from '@vercel/functions';

const API_VERSION = '2022-11-28';
const SCHEMA_VERSION = 1;
const DEFAULT_REPOSITORY = 'ttimasdf/astral-ng';
const DEFAULT_WORKFLOW = 'build.yml';
const DEFAULT_BRANCH = 'main';
const STABLE_INDEX_TTL_SECONDS = 300;
const BETA_INDEX_TTL_SECONDS = 600;
const MAX_BETA_ARTIFACT_AGE_SECONDS = 90 * 24 * 60 * 60;
const EMPTY_CHANNEL_TTL_SECONDS = 60;
const MAX_LIMIT = 30;
const MAX_GITHUB_PAGES = 10;
const GITHUB_API = 'https://api.github.com';

export type Channel = 'stable' | 'beta' | 'alpha';
export type ReleaseStage = 'stable' | 'rc' | 'beta' | 'alpha';

type Highlights = {
  en: string;
  zh?: string;
};

export type VersionSummary = {
  channel: Channel;
  stage: ReleaseStage;
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
  body?: string | null;
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
  pull_requests?: Array<{ number: number }>;
  html_url: string | null;
  created_at: string;
  updated_at: string;
};

type GitHubPullRequest = {
  number: number;
  title: string;
  html_url: string;
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

type CachedImmutableChangelog = {
  content: string | null;
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
  sourceTtlSeconds: number,
): Promise<T> {
  const cache = runtimeCache();
  const scopedCacheKey = `source:v1:${repository()}:${workflow()}:${branch()}:${cacheKey}`;
  const cached = (await cache.get(scopedCacheKey)) as CachedGitHubValue<T> | null;
  const response = await fetch(`${GITHUB_API}${path}`, {
    headers: githubHeaders(cached?.etag),
    signal: AbortSignal.timeout(15_000),
  });

  if (response.status === 304 && cached) {
    await cache.set(scopedCacheKey, cached, { ttl: sourceTtlSeconds });
    return cached.data;
  }
  if (!response.ok) {
    const error = new GitHubError(response.status, path);
    throw error;
  }

  const data = (await response.json()) as T;
  await cache.set(
    scopedCacheKey,
    {
      etag: response.headers.get('etag'),
      data,
    } satisfies CachedGitHubValue<T>,
    { ttl: sourceTtlSeconds },
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
  if (value === null) return 10;
  if (!/^\d+$/.test(value)) return null;
  const limit = Number(value);
  return Number.isSafeInteger(limit) && limit >= 1 && limit <= MAX_LIMIT
    ? limit
    : null;
}

function parseChannel(value: string | null): Channel | null {
  return value === 'stable' || value === 'beta' || value === 'alpha'
    ? value
    : null;
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
      'The channel must be stable, beta, or alpha.',
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

function isValidationError(
  value: { channel: Channel; limit: number } | Response,
): value is Response {
  return value instanceof Response;
}

function isGitHubPageUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === 'https:' &&
      (url.hostname === 'github.com' || url.hostname === 'www.github.com');
  } catch {
    return false;
  }
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

function stableReleaseVersion(tag: string): string | null {
  if (!/^v\d+\.\d+\.\d+$/.test(tag)) return null;
  return tag.slice(1);
}

function rcReleaseVersion(tag: string): string | null {
  if (!/^v\d+\.\d+\.\d+-rc\.[1-9]\d*$/.test(tag)) return null;
  return tag.slice(1);
}

function extractHighlightBlock(markdown: string): Highlights | null {
  const match = /> \*\*Highlight:\*\* ([^\r\n]+)\r?\n>\r?\n> \*\*版本亮点：\*\* ([^\r\n]+)$/m.exec(
    markdown,
  );
  return match ? { en: match[1], zh: match[2] } : null;
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
  return extractHighlightBlock(content);
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function commitSubject(message: string | null | undefined): string {
  return (message ?? '').split(/\r?\n/, 1)[0]?.trim() ?? '';
}

const CANARY_ARTIFACT_PATTERN =
  /^astral-canary-.+-(\d+\.\d+\.\d+-(?:alpha|beta)\.\d+\+[0-9a-f]{7})\.(?:apk|exe|zip|deb|rpm|tar\.gz)$/i;

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

function requiredArtifacts(artifacts: GitHubArtifact[]): GitHubArtifact[] {
  return artifacts.filter((artifact) =>
    REQUIRED_CANARY_ARTIFACTS.some((pattern) => pattern.test(artifact.name)),
  );
}

function completeArtifactVersion(artifacts: GitHubArtifact[]): string | null {
  const required = requiredArtifacts(artifacts);
  if (
    !REQUIRED_CANARY_ARTIFACTS.every((pattern) =>
      required.some((artifact) => pattern.test(artifact.name)),
    )
  ) {
    return null;
  }
  const versions = new Set(
    required.map((artifact) => artifactVersion(artifact.name)).filter(Boolean),
  );
  return versions.size === 1 ? [...versions][0]! : null;
}

function usableArtifact(artifact: GitHubArtifact, now: number): boolean {
  if (artifact.expired || !artifact.expires_at) return false;
  return Date.parse(artifact.expires_at) > now;
}

async function immutableReleaseChangelog(
  repo: string,
  tag: string,
): Promise<string | null> {
  const cache = runtimeCache();
  const immutableKey = `immutable:v1:${repository()}:stable:changelog:${tag}`;
  const cached = (await cache.get(immutableKey)) as CachedImmutableChangelog | null;
  if (cached) return cached.content;

  let content: string | null = null;
  try {
    const response = await githubRequest<{ content?: string; encoding?: string }>(
      `/repos/${repo}/contents/CHANGELOG.md?ref=${encodeURIComponent(tag)}`,
      `github:stable:changelog:v1:${tag}`,
      STABLE_INDEX_TTL_SECONDS,
    );
    if (response.content) {
      content = decodeBase64(response.content, response.encoding);
    }
  } catch (error) {
    if (!(error instanceof GitHubError) || error.status !== 404) throw error;
  }

  // Release tags are immutable. Cache both a tagged file and a missing legacy
  // file so the fallback path never adds recurring GitHub traffic.
  await cache.set(immutableKey, { content }, { ttl: 31_536_000 });
  return content;
}

async function githubReleases(repo: string): Promise<GitHubRelease[]> {
  return githubRequest<GitHubRelease[]>(
    `/repos/${repo}/releases?per_page=100`,
    'github:releases:v2',
    STABLE_INDEX_TTL_SECONDS,
  );
}

async function stableVersions(): Promise<VersionSummary[]> {
  const repo = repository();
  const releases = await githubReleases(repo);
  let changelog = '';
  try {
    const changelogResponse = await githubRequest<{
      content?: string;
      encoding?: string;
    }>(
      `/repos/${repo}/contents/CHANGELOG.md?ref=${encodeURIComponent(branch())}`,
      'github:stable:changelog:v1',
      STABLE_INDEX_TTL_SECONDS,
    );
    if (changelogResponse.content) {
      changelog = decodeBase64(changelogResponse.content, changelogResponse.encoding);
    }
  } catch (error) {
    if (!(error instanceof GitHubError) || error.status !== 404) throw error;
  }

  const values: VersionSummary[] = [];
  // Prefer the immutable tagged changelog for the latest release. Older
  // releases use the current release-history index to keep a cold refresh
  // bounded to one extra GitHub request. Missing sections or malformed
  // highlights are intentionally non-fatal.
  for (const release of releases) {
    if (values.length >= MAX_LIMIT) break;
    const version = stableReleaseVersion(release.tag_name);
    if (
      release.draft ||
      release.prerelease ||
      !version ||
      !release.published_at ||
      !isGitHubPageUrl(release.html_url)
    ) {
      continue;
    }

    const taggedChangelog =
      values.length === 0
        ? await immutableReleaseChangelog(repo, release.tag_name)
        : null;
    const highlights = extractChangelogHighlights(
      taggedChangelog ?? changelog,
      version,
    );
    values.push({
      channel: 'stable',
      stage: 'stable',
      version,
      title: `Release v${version}`,
      highlights,
      publishedAt: release.published_at,
      expiresAt: null,
      pageUrl: release.html_url,
      source: {
        type: 'github_release',
        id: String(release.id),
        ref: release.tag_name,
      },
    });
  }

  return sortVersions(values);
}

async function rcVersions(): Promise<VersionSummary[]> {
  const repo = repository();
  const releases = await githubReleases(repo);
  const values: VersionSummary[] = [];
  for (const release of releases) {
    const version = rcReleaseVersion(release.tag_name);
    if (
      release.draft ||
      !release.prerelease ||
      !version ||
      !release.published_at ||
      !isGitHubPageUrl(release.html_url)
    ) {
      continue;
    }
    values.push({
      channel: 'beta',
      stage: 'rc',
      version,
      title: `Release candidate v${version}`,
      highlights: extractHighlightBlock(release.body ?? ''),
      publishedAt: release.published_at,
      expiresAt: null,
      pageUrl: release.html_url,
      source: {
        type: 'github_release',
        id: String(release.id),
        ref: release.tag_name,
      },
    });
  }
  return sortVersions(values);
}

function decodeBase64(value: string, encoding = 'base64'): string {
  if (encoding !== 'base64') return value;
  return Buffer.from(value.replace(/\s/g, ''), 'base64').toString('utf8');
}

async function fetchAllArtifacts(repo: string, now: number): Promise<GitHubArtifact[]> {
  const artifacts: GitHubArtifact[] = [];
  for (let page = 1; page <= MAX_GITHUB_PAGES; page += 1) {
    const response = await githubRequest<GitHubListResponse<GitHubArtifact>>(
      `/repos/${repo}/actions/artifacts?per_page=100&page=${page}`,
      `github:preview:artifacts:v2:${page}`,
      BETA_INDEX_TTL_SECONDS,
    );
    const pageArtifacts = response.artifacts ?? [];
    artifacts.push(...pageArtifacts.filter((artifact) => usableArtifact(artifact, now)));
    if (pageArtifacts.length < 100) break;
    const oldestCreated = pageArtifacts
      .map((artifact) => Date.parse(artifact.created_at))
      .filter((value) => Number.isFinite(value))
      .sort((left, right) => left - right)[0];
    if (
      oldestCreated !== undefined &&
      oldestCreated <= now - MAX_BETA_ARTIFACT_AGE_SECONDS * 1000
    ) {
      break;
    }
  }
  return artifacts;
}

async function fetchWorkflowRuns(
  repo: string,
  now: number,
  stage: 'alpha' | 'beta',
): Promise<GitHubWorkflowRun[]> {
  const runs: GitHubWorkflowRun[] = [];
  const event = stage === 'alpha' ? 'pull_request' : 'push';
  const scope =
    stage === 'alpha'
      ? `event=pull_request&status=completed&exclude_pull_requests=false`
      : `branch=${encodeURIComponent(branch())}&event=push&status=completed&exclude_pull_requests=true`;
  for (let page = 1; page <= MAX_GITHUB_PAGES; page += 1) {
    const response = await githubRequest<GitHubListResponse<GitHubWorkflowRun>>(
      `/repos/${repo}/actions/workflows/${encodeURIComponent(workflow())}/runs?${scope}&per_page=100&page=${page}`,
      `github:${stage}:runs:v2:${page}`,
      BETA_INDEX_TTL_SECONDS,
    );
    const pageRuns = response.workflow_runs ?? [];
    runs.push(
      ...pageRuns.filter(
        (run) =>
          run.status === 'completed' &&
          run.conclusion === 'success' &&
          run.event === event &&
          (stage === 'alpha' || run.head_branch === branch()) &&
          run.html_url !== null &&
          isGitHubPageUrl(run.html_url),
      ),
    );
    if (pageRuns.length < 100) break;
    const oldestCreated = pageRuns
      .map((run) => Date.parse(run.created_at))
      .filter((value) => Number.isFinite(value))
      .sort((left, right) => left - right)[0];
    if (
      oldestCreated !== undefined &&
      oldestCreated <= now - MAX_BETA_ARTIFACT_AGE_SECONDS * 1000
    ) {
      break;
    }
  }
  return runs;
}

async function fetchWorkflowRun(
  repo: string,
  id: number,
): Promise<GitHubWorkflowRun | null> {
  try {
    return await githubRequest<GitHubWorkflowRun>(
      `/repos/${repo}/actions/runs/${id}`,
      `github:alpha:run:v1:${id}`,
      BETA_INDEX_TTL_SECONDS,
    );
  } catch (error) {
    if (error instanceof GitHubError && error.status === 404) return null;
    throw error;
  }
}

async function fetchPullRequest(
  repo: string,
  number: number,
): Promise<GitHubPullRequest | null> {
  try {
    const pullRequest = await githubRequest<GitHubPullRequest>(
      `/repos/${repo}/pulls/${number}`,
      `github:alpha:pull:v1:${number}`,
      BETA_INDEX_TTL_SECONDS,
    );
    return pullRequest.title.trim() ? pullRequest : null;
  } catch (error) {
    if (error instanceof GitHubError && error.status === 404) return null;
    throw error;
  }
}

async function actionVersions(
  stage: 'alpha' | 'beta',
  max: number,
): Promise<VersionSummary[]> {
  const repo = repository();
  const now = Date.now();
  const [runs, artifacts] = await Promise.all([
    fetchWorkflowRuns(repo, now, stage),
    fetchAllArtifacts(repo, now),
  ]);
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
    if (!parts || parts.prerelease.length !== 2 || parts.prerelease[0] !== stage) continue;
    if (Number(parts.prerelease[1]) !== run.run_number) continue;
    if (version.slice(-7).toLowerCase() !== run.head_sha.slice(0, 7).toLowerCase()) continue;

    let title = `Beta build #${run.run_number}`;
    if (stage === 'alpha') {
      let pullNumber = run.pull_requests?.[0]?.number;
      if (!pullNumber) {
        const detailedRun = await fetchWorkflowRun(repo, run.id);
        pullNumber = detailedRun?.pull_requests?.[0]?.number;
      }
      if (!pullNumber) continue;
      const pullRequest = await fetchPullRequest(repo, pullNumber);
      if (!pullRequest) continue;
      title = `${pullRequest.title.trim()} · Build #${run.run_number}`;
    }

    const requiredRunArtifacts = requiredArtifacts(runArtifacts).filter(
      (artifact) => artifactVersion(artifact.name) === version,
    );
    const expiresAt = requiredRunArtifacts
      .map((artifact) => artifact.expires_at)
      .filter((value): value is string => value !== null)
      .sort()[0];
    if (!expiresAt || Date.parse(expiresAt) <= now) continue;
    versions.push({
      channel: stage,
      stage,
      version,
      title,
      highlights: { en: commitSubject(run.head_commit?.message) || title },
      publishedAt: run.updated_at,
      expiresAt,
      pageUrl: run.html_url!,
      source: {
        type: 'github_actions',
        id: String(run.id),
        runNumber: run.run_number,
        runAttempt: run.run_attempt,
        commitSha: run.head_sha,
      },
    });
    if (versions.length >= max) break;
  }

  return sortVersions(versions).slice(0, max);
}

async function betaVersions(max: number): Promise<VersionSummary[]> {
  const [betas, releaseCandidates] = await Promise.all([
    actionVersions('beta', max),
    rcVersions(),
  ]);
  return sortVersions([...betas, ...releaseCandidates]).slice(0, max);
}

async function loadVersions(channel: Channel): Promise<VersionSummary[]> {
  const key = `index:v2:${repository()}:${workflow()}:${branch()}:${channel}`;
  const cache = runtimeCache();
  const cached = (await cache.get(key)) as VersionSummary[] | null;
  if (cached) return cached.filter((item) => !item.expiresAt || Date.parse(item.expiresAt) > Date.now());

  const values =
    channel === 'stable'
      ? await stableVersions()
      : channel === 'beta'
        ? await betaVersions(30)
        : await actionVersions('alpha', 30);
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
  if (isValidationError(validated)) return validated;

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
  artifactVersion,
  commitSubject,
  completeArtifactVersion,
};
