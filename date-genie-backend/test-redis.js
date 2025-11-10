import fs from 'node:fs';
import path from 'node:path';
import { Redis } from '@upstash/redis';

const envFiles = ['.env.local', '.env', '../.env.local', '../.env'];

function loadEnv(file) {
  const envPath = path.resolve(process.cwd(), file);
  if (!fs.existsSync(envPath)) {
    return;
  }

  const contents = fs.readFileSync(envPath, 'utf8');
  for (const line of contents.split(/\r?\n/)) {
    if (!line || line.trim().startsWith('#')) {
      continue;
    }
    const [key, ...rest] = line.split('=');
    const value = rest.join('=').trim().replace(/^['"]|['"]$/g, '');
    if (key && value && !(key in process.env)) {
      process.env[key.trim()] = value;
    }
  }
}

envFiles.forEach(loadEnv);

const redisUrl = process.env.UPSTASH_REDIS_REST_URL || process.env.UPSTASH_REDIS_URL;
const redisToken = process.env.UPSTASH_REDIS_REST_TOKEN || process.env.UPSTASH_REDIS_TOKEN;

if (!redisUrl || !redisToken) {
  console.error('Missing UPSTASH_REDIS_REST_URL or UPSTASH_REDIS_REST_TOKEN environment variables.');
  process.exit(1);
}

const redis = new Redis({
  url: redisUrl,
  token: redisToken,
});

async function main() {
  try {
    await redis.set('test:key', 'hello', { ex: 60 });
    const value = await redis.get('test:key');
    console.log('Redis works:', value === 'hello');
    await redis.del('test:key');
  } catch (error) {
    console.error('Redis test failed:', error);
    process.exitCode = 1;
  }
}

main();
