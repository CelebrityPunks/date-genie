import { DateCategory } from './schemas';

interface CategoryConfig {
  queryKeywords: string[];
  googleTypes: string[];
  vibeBoostTags: string[];
}

export const CATEGORY_MAP: Record<DateCategory, CategoryConfig> = {
  Food: {
    queryKeywords: ['restaurant', 'cafe', 'dining'],
    googleTypes: ['restaurant', 'cafe', 'bakery', 'meal_takeaway'],
    vibeBoostTags: ['casual dining', 'intimate', 'culinary'],
  },
  Fun: {
    queryKeywords: ['arcade', 'museum', 'entertainment', 'games'],
    googleTypes: ['amusement_center', 'arcade', 'museum', 'bowling_alley'],
    vibeBoostTags: ['fun', 'playful', 'entertainment'],
  },
  'Live Events': {
    queryKeywords: ['concert', 'comedy', 'live music', 'performance'],
    googleTypes: ['performing_arts_theater', 'concert_hall', 'night_club'],
    vibeBoostTags: ['live entertainment', 'energetic', 'performance'],
  },
  Active: {
    queryKeywords: ['hiking', 'sports', 'fitness', 'activity'],
    googleTypes: ['gym', 'sports_complex', 'park', 'hiking_area'],
    vibeBoostTags: ['active', 'energetic', 'outdoor'],
  },
  'Bars/Drinks': {
    queryKeywords: ['bar', 'pub', 'wine tasting', 'cocktails'],
    googleTypes: ['bar', 'pub', 'wine_bar', 'cocktail_bar'],
    vibeBoostTags: ['drinks', 'nightlife', 'social'],
  },
  Nature: {
    queryKeywords: ['park', 'beach', 'nature', 'outdoor'],
    googleTypes: ['park', 'beach', 'garden', 'nature_reserve'],
    vibeBoostTags: ['nature', 'outdoor', 'scenic'],
  },
  Romantic: {
    queryKeywords: ['romantic', 'sunset', 'picnic', 'intimate'],
    googleTypes: ['restaurant', 'park', 'viewpoint'],
    vibeBoostTags: ['romantic', 'intimate', 'scenic'],
  },
  Cultural: {
    queryKeywords: ['art gallery', 'theater', 'cultural', 'exhibit'],
    googleTypes: ['art_gallery', 'museum', 'performing_arts_theater'],
    vibeBoostTags: ['cultural', 'artistic', 'sophisticated'],
  },
  Adventure: {
    queryKeywords: ['escape room', 'zip-lining', 'adventure', 'thrilling'],
    googleTypes: ['amusement_center', 'tourist_attraction'],
    vibeBoostTags: ['adventure', 'thrilling', 'unique'],
  },
  Relaxed: {
    queryKeywords: ['spa', 'coffee shop', 'relaxing', 'chill'],
    googleTypes: ['spa', 'cafe', 'park'],
    vibeBoostTags: ['relaxed', 'cozy', 'peaceful'],
  },
  Seasonal: {
    queryKeywords: ['holiday', 'seasonal', 'christmas', 'summer'],
    googleTypes: ['tourist_attraction', 'event_venue'],
    vibeBoostTags: ['seasonal', 'festive', 'timely'],
  },
};

export function buildSearchQuery(
  city: string,
  userQuery: string,
  categories: DateCategory[]
): string {
  const categoryKeywords = categories.flatMap(
    (cat) => CATEGORY_MAP[cat].queryKeywords
  );
  const uniqueKeywords = Array.from(
    new Set([...userQuery.split(' '), ...categoryKeywords])
  );
  return `${uniqueKeywords.join(' ')} in ${city}`;
}

export function getGoogleTypes(categories: DateCategory[]): string[] {
  const types = categories.flatMap((cat) => CATEGORY_MAP[cat].googleTypes);
  return Array.from(new Set(types));
}

export function getVibeBoostTags(categories: DateCategory[]): string[] {
  const tags = categories.flatMap((cat) => CATEGORY_MAP[cat].vibeBoostTags);
  return Array.from(new Set(tags));
}
