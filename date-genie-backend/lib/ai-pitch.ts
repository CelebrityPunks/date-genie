import crypto from 'crypto';
import { Redis } from '@upstash/redis';
import { DateCategory } from './schemas';

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL || '',
  token: process.env.UPSTASH_REDIS_REST_TOKEN || '',
});

const OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions';
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || process.env.OPENAI_KEY || '';

type PitchResult = {
  pitch: string;
  logistics_tip: string;
};

export async function generateAIPitch(
  venue: any,
  userPrefs: { budget: number; radius: number; categories: DateCategory[] }
): Promise<PitchResult> {
  const prefsHash = crypto
    .createHash('md5')
    .update(JSON.stringify(userPrefs))
    .digest('hex')
    .slice(0, 8);

  const venueHash = crypto
    .createHash('md5')
    .update(venue.id)
    .digest('hex')
    .slice(0, 8);

  const cacheKey = `llm:${venueHash}:${prefsHash}`;
  try {
    const cached = await redis.get<PitchResult>(cacheKey);
    if (cached) {
      return cached;
    }
  } catch (error) {
    console.error('AI pitch cache read failed:', error);
  }

  const systemPrompt =
    'You are a date concierge. Write 1-2 sentence pitches using ONLY provided facts. Incorporate user selected categories naturally. Avoid availability claims unless confirmed.';

  const userPrompt = `FACTS: Name: ${venue.name}, Category: ${venue.categories?.[0] ?? 'unknown'
    }, Price: ${venue.price_level}, Rating: ${venue.rating}/5, Reviews: ${venue.review_count
    }, Distance: ${Math.round(venue.distance ?? 0)}mi, Vibes: ${venue.vibe_tags?.join(', ') ?? 'none'
    }
USER_PREFS: Budget: $${userPrefs.budget}, Radius: ${userPrefs.radius
    }mi, Categories: ${userPrefs.categories.join(', ')}

OUTPUT: { "pitch": string, "logistics_tip": string }`;

  try {
    if (!OPENAI_API_KEY) {
      throw new Error('Missing OPENAI_API_KEY');
    }

    const response = await fetch(OPENAI_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        max_tokens: 500,
        temperature: 0.7,
      }),
    });

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`);
    }

    const completion = await response.json();
    const rawContent =
      completion?.choices?.[0]?.message?.content?.trim();

    if (!rawContent) {
      throw new Error('Empty AI response');
    }

    const cleaned = rawContent.replace(/```json\n?|\n?```/g, '').trim();
    const result: PitchResult = JSON.parse(cleaned);

    await redis.set(cacheKey, result, { ex: 30 * 24 * 60 * 60 });
    return result;
  } catch (error) {
    console.error('AI pitch generation failed:', error);

    const fallbackText = venue.summary
      ? venue.summary
      : `${venue.name} offers ${venue.vibe_tags?.join(', ') || 'unique'} vibes perfect for ${userPrefs.categories.join(' or ')}.`;

    const fallback: PitchResult = {
      pitch: fallbackText,
      logistics_tip: 'Check reviews for current hours and make reservations.',
    };

    try {
      await redis.set(cacheKey, fallback, { ex: 60 * 60 });
    } catch (cacheError) {
      console.error('AI pitch fallback cache failed:', cacheError);
    }

    return fallback;
  }
}
