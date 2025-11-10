import { NextRequest, NextResponse } from 'next/server';
import { Redis } from '@upstash/redis';
import { z } from 'zod';
import { searchQuerySchema } from '@/lib/schemas';
import { calculateDateabilityScore } from '@/lib/dateability';
import { generateAIPitch } from '@/lib/ai-pitch';
import {
  buildSearchQuery,
  getGoogleTypes,
  getVibeBoostTags,
} from '@/lib/category-map';

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
});

let lastRequestTime = 0;
const RATE_LIMIT_MS = 100;

export async function POST(request: NextRequest) {
  const startTime = Date.now();

  try {
    const body = await request.json();
    const { city, query, budget, radius, categories, userId } =
      searchQuerySchema.parse(body);

    const now = Date.now();
    if (now - lastRequestTime < RATE_LIMIT_MS) {
      await new Promise((resolve) =>
        setTimeout(resolve, RATE_LIMIT_MS - (now - lastRequestTime))
      );
    }
    lastRequestTime = now;

    const categoriesHash = categories.sort().join(',');
    const cacheKey = `search:${city}:${query}:${budget}:${radius}:${categoriesHash}`;
    const cachedResult = await redis.get(cacheKey);

    if (cachedResult) {
      if (userId) {
        await trackEvent('cache_hit', { userId, cacheKey, source: 'redis' });
      }

      return NextResponse.json({
        success: true,
        source: 'cache',
        data: cachedResult,
        latency: Date.now() - startTime,
      });
    }

    if (userId) {
      await trackEvent('cache_miss', { userId, cacheKey, source: 'api' });
    }

    const enhancedQuery = buildSearchQuery(city, query, categories);
    const googleTypes = getGoogleTypes(categories);

    const googlePlacesUrl = `https://places.googleapis.com/v1/places:searchText`;
    const googlePayload = {
      textQuery: enhancedQuery,
      maxResultCount: 20,
      includedType: googleTypes[0],
      locationBias: {
        circle: {
          center: { latitude: 40.7128, longitude: -74.006 },
          radius: radius * 1609.34,
        },
      },
    };

    const googleResponse = await fetch(googlePlacesUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': process.env.GOOGLE_PLACES_API_KEY!,
        'X-Goog-FieldMask':
          'places.name,places.displayName,places.formattedAddress,places.priceLevel,places.rating,places.userRatingCount,places.types,places.location,places.photos,places.websiteUri,places.googleMapsUri',
      },
      body: JSON.stringify(googlePayload),
    });

    if (!googleResponse.ok) {
      throw new Error(`Google Places API error: ${googleResponse.status}`);
    }

    const googleData = await googleResponse.json();

    const venues =
      (await Promise.all(
        googleData.places?.map(async (place: any) => {
          const vibeTags = extractVibeTags(place.types || []);
          const vibeBoost = getVibeBoostTags(categories);

          const venueData = {
            id: place.name.split('/')[1],
            name: place.displayName.text,
            address: place.formattedAddress,
            price_level: place.priceLevel || 'PRICE_LEVEL_UNSPECIFIED',
            rating: place.rating || 0,
            review_count: place.userRatingCount || 0,
            categories: place.types || [],
            latitude: place.location.latitude,
            longitude: place.location.longitude,
            distance: 0,
            vibe_tags: [...vibeTags, ...vibeBoost],
            selected_categories: categories,
          };

          const dateabilityScore = calculateDateabilityScore(
            venueData,
            categories
          );

          const aiPitch = await generateAIPitch(venueData, {
            budget,
            radius,
            categories,
          });

          return {
            id: venueData.id,
            name: venueData.name,
            address: venueData.address,
            priceLevel: venueData.price_level,
            rating: venueData.rating,
            reviewCount: venueData.review_count,
            categories: venueData.categories,
            location: {
              lat: venueData.latitude,
              lng: venueData.longitude,
            },
            vibeTags: venueData.vibe_tags,
            selectedCategories: categories,
            dateabilityScore,
            aiPitch: aiPitch.pitch,
            logisticsTip: aiPitch.logistics_tip,
            bookingUrl: place.websiteUri || place.googleMapsUri,
            photoUrl: place.photos?.[0]?.name
              ? `https://places.googleapis.com/v1/${place.photos[0].name}/media?key=${process.env.GOOGLE_PLACES_API_KEY}&maxHeightPx=800`
              : null,
          };
        }) ?? []
      )) || [];

    const filteredVenues = venues
      .filter((v) => isWithinBudget(v.priceLevel, budget))
      .sort((a, b) => b.dateabilityScore - a.dateabilityScore)
      .slice(0, 10);

    await redis.set(cacheKey, filteredVenues, { ex: 7 * 24 * 60 * 60 });

    if (userId) {
      await trackEvent('search_performed', {
        userId,
        city,
        query,
        categories,
        budget,
        radius,
        resultCount: filteredVenues.length,
      });
    }

    return NextResponse.json({
      success: true,
      source: 'api',
      data: filteredVenues,
      latency: Date.now() - startTime,
    });
  } catch (error) {
    console.error('Search API error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}

function extractVibeTags(types: string[]): string[] {
  const vibeMap: Record<string, string[]> = {
    restaurant: ['casual dining'],
    cafe: ['coffee', 'cozy'],
    bar: ['drinks', 'nightlife'],
    park: ['outdoor', 'nature'],
    movie_theater: ['entertainment', 'indoor'],
    arcade: ['games', 'fun'],
  };

  return types.flatMap((type) => vibeMap[type] || []).slice(0, 3);
}

function isWithinBudget(priceLevel: string, budget: number): boolean {
  const priceMap: Record<string, number> = {
    PRICE_LEVEL_UNSPECIFIED: 50,
    PRICE_LEVEL_FREE: 0,
    PRICE_LEVEL_INEXPENSIVE: 20,
    PRICE_LEVEL_MODERATE: 50,
    PRICE_LEVEL_EXPENSIVE: 100,
    PRICE_LEVEL_VERY_EXPENSIVE: 200,
  };

  return (priceMap[priceLevel] || 50) <= budget;
}

async function trackEvent(eventName: string, properties: Record<string, any>) {
  try {
    await fetch('https://us.i.posthog.com/capture/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        api_key: process.env.NEXT_PUBLIC_POSTHOG_KEY,
        event: eventName,
        properties,
      }),
    });
  } catch (e) {
    console.error('PostHog tracking failed:', e);
  }
}
