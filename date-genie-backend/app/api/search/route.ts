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
    const { city, query, budget, radius, categories, userId, lat, lng, excludedVenueIds } =
      searchQuerySchema.parse(body);

    const now = Date.now();
    if (now - lastRequestTime < RATE_LIMIT_MS) {
      await new Promise((resolve) =>
        setTimeout(resolve, RATE_LIMIT_MS - (now - lastRequestTime))
      );
    }
    lastRequestTime = now;

    const categoriesHash = categories.sort().join(',');
    // Updated cache key to v5 to include pagination support
    const cacheKey = `search_v5:${city}:${query}:${budget}:${radius}:${categoriesHash}`;
    const cachedResult = await redis.get(cacheKey) as { venues: any[], nextPageToken?: string } | null;

    if (cachedResult) {
      if (userId) {
        await trackEvent('cache_hit', { userId, cacheKey, source: 'redis' });
      }

      // Filter out excluded venues from cache
      let filteredData = cachedResult.venues || [];
      if (excludedVenueIds && excludedVenueIds.length > 0) {
        filteredData = filteredData.filter(v => !excludedVenueIds.includes(v.id));
      }

      // If we have enough results, return them.
      if (filteredData.length >= 10) {
        const shuffledData = shuffleArray(filteredData).slice(0, 50);
        return NextResponse.json({
          success: true,
          source: 'cache',
          data: shuffledData,
          latency: Date.now() - startTime,
        });
      }

      // If results are low AND we have a next page token, fetch the next page!
      if (cachedResult.nextPageToken) {
        console.log(`Fetching next page for ${cacheKey} using token`);
        // Fall through to API call, but include the page token
      } else {
        // No more pages, just return what we have (even if it's 0)
        // Or we could fall through to force a fresh fetch just in case, but likely it's exhausted.
        // Let's force a fresh fetch if we have 0 results, just to be safe.
        if (filteredData.length > 0) {
          const shuffledData = shuffleArray(filteredData).slice(0, 50);
          return NextResponse.json({
            success: true,
            source: 'cache_exhausted',
            data: shuffledData,
            latency: Date.now() - startTime,
          });
        }
      }
    }

    if (userId) {
      await trackEvent('cache_miss', { userId, cacheKey, source: 'api' });
    }

    // Construct Google Places Text Search Payload
    const enhancedQuery = `${query} in ${city}`;

    const googlePlacesUrl = `https://places.googleapis.com/v1/places:searchText`;
    const googlePayload: any = {
      textQuery: enhancedQuery,
      maxResultCount: 50,
    };

    // Use nextPageToken if we are continuing a search (from cache hit logic)
    if (cachedResult?.nextPageToken) {
      googlePayload.pageToken = cachedResult.nextPageToken;
    }

    // Only apply location bias if we have coordinates (Current Location mode)
    if (lat && lng) {
      googlePayload.locationBias = {
        circle: {
          center: { latitude: lat, longitude: lng },
          radius: radius * 1000,
        },
      };
    }

    const googleResponse = await fetch(googlePlacesUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': process.env.GOOGLE_PLACES_API_KEY!,
        'X-Goog-FieldMask':
          'places.name,places.displayName,places.formattedAddress,places.priceLevel,places.rating,places.userRatingCount,places.types,places.location,places.photos,places.websiteUri,places.googleMapsUri,places.editorialSummary,places.generativeSummary,places.reviews,nextPageToken',
      },
      body: JSON.stringify(googlePayload),
    });

    if (!googleResponse.ok) {
      throw new Error(`Google Places API error: ${googleResponse.status}`);
    }

    const googleData = await googleResponse.json();
    const nextPageToken = googleData.nextPageToken;

    const newVenues =
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
            summary: place.editorialSummary?.text || place.generativeSummary?.overview?.text || null,
          };

          const dateabilityScore = calculateDateabilityScore(
            venueData,
            categories
          );

          const summary = place.editorialSummary?.text || place.generativeSummary?.overview?.text || null;

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
            aiPitch: summary || "No description available.",
            logisticsTip: "",
            bookingUrl: place.websiteUri || place.googleMapsUri,
            photoUrl: place.photos?.[0]?.name
              ? `https://places.googleapis.com/v1/${place.photos[0].name}/media?key=${process.env.GOOGLE_PLACES_API_KEY}&maxHeightPx=800`
              : null,
            summary: place.editorialSummary?.text || place.generativeSummary?.overview?.text || null,
            reviews: place.reviews?.slice(0, 3).map((r: any) => ({
              authorName: r.authorAttribution?.displayName || 'Anonymous',
              text: r.text?.text || '',
              rating: r.rating,
            })) || [],
          };
        }) ?? []
      )) || [];

    // Filter by budget
    let filteredNewVenues = newVenues
      .filter((v: any) => isWithinBudget(v.priceLevel, budget))
      .sort((a: any, b: any) => b.dateabilityScore - a.dateabilityScore);

    // Combine with existing cache if applicable
    let allVenues = filteredNewVenues;
    if (cachedResult?.venues) {
      // Merge and deduplicate
      const existingIds = new Set(cachedResult.venues.map((v: any) => v.id));
      const uniqueNew = filteredNewVenues.filter((v: any) => !existingIds.has(v.id));
      allVenues = [...cachedResult.venues, ...uniqueNew];
    }

    // Cache the updated list and new token
    await redis.set(cacheKey, { venues: allVenues, nextPageToken }, { ex: 7 * 24 * 60 * 60 });

    // Filter out excluded venues from API result
    let finalVenues = allVenues;
    if (excludedVenueIds && excludedVenueIds.length > 0) {
      finalVenues = finalVenues.filter((v: any) => !excludedVenueIds.includes(v.id));
    }

    // Shuffle and slice for the response
    const responseVenues = shuffleArray(finalVenues).slice(0, 50);

    if (userId) {
      await trackEvent('search_performed', {
        userId,
        city,
        query,
        categories,
        budget,
        radius,
        resultCount: finalVenues.length,
      });
    }

    return NextResponse.json({
      success: true,
      source: 'api',
      data: responseVenues,
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

function shuffleArray<T>(array: T[]): T[] {
  const newArray = [...array];
  for (let i = newArray.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [newArray[i], newArray[j]] = [newArray[j], newArray[i]];
  }
  return newArray;
}
