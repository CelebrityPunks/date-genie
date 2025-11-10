const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const axios = require('axios');

const CHECKS = [];
let hasFailure = false;

function log(status, name, message, error) {
  const icon = status === 'PASS' ? '✅' : '❌';
  const finalMessage = message || (error ? error.message : '');
  const entry = { status, name, message: finalMessage };
  CHECKS.push(entry);

  const output = `${icon} ${status} - ${name}: ${finalMessage}`;
  if (status === 'PASS') {
    console.log(output);
  } else {
    hasFailure = true;
    console.error(output);
    if (error) {
      console.error(error);
    }
  }
}

function loadEnvFile(envPath) {
  const contents = fs.readFileSync(envPath, 'utf8');
  for (const line of contents.split(/\r?\n/)) {
    if (!line || line.trim().startsWith('#')) continue;
    const idx = line.indexOf('=');
    if (idx === -1) continue;
    const key = line.slice(0, idx).trim();
    const raw = line.slice(idx + 1).trim();
    const value = raw.replace(/^['"]|['"]$/g, '');
    if (key && !(key in process.env)) {
      process.env[key] = value;
    }
  }
}

async function testRedisConnection(url, token) {
  const command = async (cmd, args = [], params = {}) => {
    const sanitizedUrl = url.replace(/\/$/, '');
    const encodedArgs = args.map((arg) => encodeURIComponent(arg));
    const endpoint = `${sanitizedUrl}/${cmd}/${encodedArgs.join('/')}`;
    const response = await axios.get(endpoint, {
      headers: { Authorization: `Bearer ${token}` },
      params,
    });
    if (response.status !== 200 || (response.data && response.data.error)) {
      throw new Error(
        `Redis command failed: ${cmd} ${JSON.stringify(response.data)}`,
      );
    }
    return response.data?.result;
  };

  const testKey = `diagnose:test:${Date.now()}:${crypto.randomBytes(4).toString('hex')}`;
  await command('set', [testKey, 'hello'], { EX: 60 });
  const value = await command('get', [testKey]);
  await command('del', [testKey]);
  return value === 'hello';
}

async function testApiTwice() {
  const payload = {
    city: 'San Diego',
    radius: 10,
    budget: 80,
    category: 'restaurant',
  };

  const call = async () => {
    const response = await axios.post('http://localhost:3000/api/search', payload, {
      headers: { 'Content-Type': 'application/json' },
      timeout: 15000,
    });
    return response.data;
  };

  const first = await call();
  const second = await call();

  const dataMatch =
    first &&
    second &&
    JSON.stringify(first.data ?? null) === JSON.stringify(second.data ?? null);
  const expectedSources =
    first?.source === 'api' && second?.source === 'cache';

  return {
    first,
    second,
    dataMatch,
    expectedSources,
  };
}

async function main() {
  const envCandidates = [
    path.join(process.cwd(), '.env.local'),
    path.join(process.cwd(), '..', '.env.local'),
  ];

  let envPath = null;
  for (const candidate of envCandidates) {
    try {
      fs.accessSync(candidate, fs.constants.R_OK);
      envPath = candidate;
      break;
    } catch {
      // keep trying other candidates
    }
  }

  if (envPath) {
    log('PASS', '.env.local', `Found and readable at ${envPath}`);
    loadEnvFile(envPath);
  } else {
    log('FAIL', '.env.local', 'File missing or not readable in known locations');
  }

  // Check 2: Required env vars
  const redisUrl =
    process.env.UPSTASH_REDIS_REST_URL || process.env.UPSTASH_REDIS_URL;
  const redisToken =
    process.env.UPSTASH_REDIS_REST_TOKEN || process.env.UPSTASH_REDIS_TOKEN;

  if (redisUrl && redisToken) {
    log('PASS', 'Redis env vars', 'Redis URL and token are set');
  } else {
    log(
      'FAIL',
      'Redis env vars',
      'Missing UPSTASH_REDIS_REST_URL/UPSTASH_REDIS_REST_TOKEN (or fallback vars)',
    );
  }

  // Check 3: Redis connectivity
  if (redisUrl && redisToken) {
    try {
      const redisOk = await testRedisConnection(redisUrl, redisToken);
      if (redisOk) {
        log('PASS', 'Redis connectivity', 'Set/Get/Delete succeeded');
      } else {
        log('FAIL', 'Redis connectivity', 'Unexpected value returned from Redis');
      }
    } catch (error) {
      log('FAIL', 'Redis connectivity', 'Unable to complete Redis commands', error);
    }
  }

  // Check 4: API cache behavior
  try {
    const { first, second, dataMatch, expectedSources } = await testApiTwice();
    if (dataMatch && expectedSources) {
      log(
        'PASS',
        'API cache behavior',
        `First call source=${first.source}, second call source=${second.source}`,
      );
    } else if (dataMatch) {
      log(
        'FAIL',
        'API cache behavior',
        `Calls succeeded but sources were unexpected (first=${first.source}, second=${second.source})`,
      );
    } else {
      log(
        'FAIL',
        'API cache behavior',
        'Responses differed between calls',
      );
    }
  } catch (error) {
    log('FAIL', 'API cache behavior', 'Unable to call /api/search twice', error);
  }

  // Summary output
  console.log('\n=== Diagnosis Summary ===');
  for (const check of CHECKS) {
    const icon = check.status === 'PASS' ? '✅' : '❌';
    console.log(`${icon} ${check.name}: ${check.message}`);
  }

  if (hasFailure) {
    process.exitCode = 1;
  } else {
    console.log('\nAll checks passed!');
  }
}

main().catch((error) => {
  console.error('Unexpected error during diagnosis:', error);
  process.exitCode = 1;
});
