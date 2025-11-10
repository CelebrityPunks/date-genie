// Direct Upstash REST API calls (bypasses SDK completely)
const UPSTASH_URL = process.env.UPSTASH_REDIS_REST_URL!;
const UPSTASH_TOKEN = process.env.UPSTASH_REDIS_REST_TOKEN!;

async function upstashRequest(command: string[]): Promise<any> {
  if (!UPSTASH_URL || !UPSTASH_TOKEN) {
    console.error('❌ Upstash credentials missing');
    return null;
  }

  const url = `${UPSTASH_URL}/${command[0]}/${encodeURIComponent(command[1])}`;

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${UPSTASH_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: command[0] === 'SET' ? JSON.stringify(command[2]) : undefined,
    });

    if (!res.ok) {
      console.error(`❌ Upstash HTTP error: ${res.status}`);
      return null;
    }

    const data = await res.json();
    return data.result;
  } catch (error) {
    console.error('❌ Upstash fetch error:', error);
    return null;
  }
}

export async function get<T>(key: string): Promise<T | null> {
  const result = await upstashRequest(['GET', key]);
  return result ? JSON.parse(result) : null;
}

export async function set(
  key: string,
  data: any,
  ttlSeconds: number = 604800
): Promise<void> {
  // Upstash SET with EX requires pipeline
  const pipelineUrl = `${UPSTASH_URL}/pipeline`;
  const body = JSON.stringify([
    ['SET', key, JSON.stringify(data)],
    ['EXPIRE', key, ttlSeconds.toString()],
  ]);

  try {
    await fetch(pipelineUrl, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${UPSTASH_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body,
    });
  } catch (error) {
    console.error('❌ Upstash SET error:', error);
  }
}

export async function del(key: string): Promise<void> {
  await upstashRequest(['DEL', key]);
}

export function generateCacheKey(
  city: string,
  category: string,
  budget: number
): string {
  const budgetHash = budget
    .toString()
    .split('')
    .reduce((a, b) => {
      a = (a << 5) - a + b.charCodeAt(0);
      return a & a;
    }, 0)
    .toString(16)
    .substring(0, 8);

  return `places:${city.toLowerCase()}:${category.toLowerCase()}:${budgetHash}`;
}
