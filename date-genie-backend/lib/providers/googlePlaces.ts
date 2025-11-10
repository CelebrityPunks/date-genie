import { z } from 'zod';

/**
 * Zod schema for Google Places API response
 */
const GooglePlacesResponseSchema = z.object({
  results: z.array(
    z.object({
      place_id: z.string(),
      name: z.string(),
      formatted_address: z.string(),
      geometry: z.object({
        location: z.object({
          lat: z.number(),
          lng: z.number(),
        }),
      }),
      rating: z.number().optional(),
      user_ratings_total: z.number().optional(),
      price_level: z.number().optional(),
      photos: z
        .array(
          z.object({
            photo_reference: z.string(),
          })
        )
        .optional(),
    })
  ),
  status: z.string(),
});

/**
 * Zod schema for Google Geocoding API response
 */
const GeocodingResponseSchema = z.object({
  results: z.array(
    z.object({
      geometry: z.object({
        location: z.object({
          lat: z.number(),
          lng: z.number(),
        }),
      }),
    })
  ),
  status: z.string(),
});

/**
 * Venue schema for normalized results
 */
export interface Venue {
  id: string;
  name: string;
  lat: number;
  lng: number;
  rating?: number;
  price_level?: number;
  photos: string[];
  city: string;
}

/**
 * Parameters for searching places
 */
export interface SearchPlacesParams {
  city: string;
  radius: number;
  budget: number;
  category: string;
}

/**
 * Search for places using Google Places API
 *
 * @param params - Search parameters including city, radius, budget, and category
 * @returns Array of normalized venues (max 10 results)
 *
 * @example
 * ```typescript
 * const venues = await searchPlaces({
 *   city: 'New York',
 *   radius: 5000,
 *   budget: 100,
 *   category: 'restaurant'
 * });
 * ```
 */
export async function searchPlaces(
  params: SearchPlacesParams
): Promise<Venue[]> {
  const { city, radius, budget, category } = params;

  try {
    // Step 1: Convert city to lat/lng using Geocoding API
    const geocodingUrl = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(
      city
    )}&key=${process.env.GOOGLE_PLACES_API_KEY}`;

    const geocodingResponse = await fetch(geocodingUrl);
    if (!geocodingResponse.ok) {
      throw new Error(`Geocoding API error: ${geocodingResponse.statusText}`);
    }
    const geocodingResponseData = await geocodingResponse.json();
    const geocodingData = GeocodingResponseSchema.parse(geocodingResponseData);

    if (
      geocodingData.status !== 'OK' ||
      geocodingData.results.length === 0
    ) {
      console.error(
        `Geocoding failed for city: ${city}. Status: ${geocodingData.status}`
      );
      return [];
    }

    const { lat, lng } = geocodingData.results[0].geometry.location;

    // Step 2: Call Google Places Text Search API
    const placesUrl = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(
      category
    )}+in+${encodeURIComponent(city)}&key=${process.env.GOOGLE_PLACES_API_KEY}`;

    const placesResponse = await fetch(placesUrl);
    if (!placesResponse.ok) {
      throw new Error(`Places API error: ${placesResponse.statusText}`);
    }
    const placesResponseData = await placesResponse.json();
    const placesData = GooglePlacesResponseSchema.parse(placesResponseData);

    if (placesData.status !== 'OK') {
      console.error(
        `Places API error for city: ${city}, category: ${category}. Status: ${placesData.status}`
      );
      // Return empty array on API errors (REQUEST_DENIED, ZERO_RESULTS, etc.)
      // The error is already logged for debugging
      return [];
    }

    // Step 3: Filter results by budget (price_level <= budget / 25)
    // price_level: 0=free, 1=inexpensive, 2=moderate, 3=expensive, 4=very expensive
    const maxPriceLevel = Math.floor(budget / 25);

    const filteredResults = placesData.results.filter((place) => {
      // If price_level is not available, include it (let user decide)
      if (place.price_level === undefined) {
        return true;
      }
      return place.price_level <= maxPriceLevel;
    });

    // Step 4: Normalize to Venue schema and return max 10 venues
    const venues: Venue[] = filteredResults
      .slice(0, 10)
      .map((place) => ({
        id: place.place_id,
        name: place.name,
        lat: place.geometry.location.lat,
        lng: place.geometry.location.lng,
        rating: place.rating,
        price_level: place.price_level,
        photos: place.photos?.map((p) => p.photo_reference) || [],
        city: city,
      }));

    return venues;
  } catch (error) {
    // Handle errors: log to console, return empty array
    if (error instanceof z.ZodError) {
      console.error('Zod validation error in searchPlaces:', error.errors);
    } else if (error instanceof Error) {
      console.error('Error in searchPlaces:', error.message);
    } else {
      console.error('Unknown error in searchPlaces:', error);
    }
    return [];
  }
}

