import { DateabilityInput, DateCategory } from './schemas';
import { getVibeBoostTags, CATEGORY_MAP } from './category-map';

export function calculateDateabilityScore(
  venue: DateabilityInput & { selected_categories?: string[] },
  userCategories?: string[]
): number {
  let score = 0;

  // Base components
  score += Math.min(venue.rating, 5);

  if (venue.review_count > 1000) score += 3;
  else if (venue.review_count > 500) score += 2;
  else if (venue.review_count > 100) score += 1;

  const priceBonus: Record<string, number> = {
    PRICE_LEVEL_INEXPENSIVE: 2,
    PRICE_LEVEL_MODERATE: 1.5,
    PRICE_LEVEL_EXPENSIVE: 1,
    PRICE_LEVEL_VERY_EXPENSIVE: 0,
  };
  score += priceBonus[venue.price_level] || 0.5;

  // Category matching bonus
  if (userCategories && userCategories.length > 0) {
    const categoryVibeTags = getVibeBoostTags(userCategories);
    const matches = venue.vibe_tags.filter((tag) =>
      categoryVibeTags.some((catTag) => tag.includes(catTag))
    );
    score += matches.length * 1.5;

    const userGoogleTypes = userCategories.flatMap(
      (cat) => CATEGORY_MAP[cat as DateCategory]?.googleTypes || []
    );
    const typeMatches = venue.categories.filter((type) =>
      userGoogleTypes.includes(type)
    );
    score += typeMatches.length * 2;
  }

  const chains = [
    'McDonald',
    'Starbucks',
    'Target',
    'Walmart',
    'Applebee',
    'Chili',
  ];
  const isChain = chains.some((chain) => venue.name.includes(chain));
  if (!isChain) score += 0.5;

  if (venue.distance > 20) score -= 1;
  else if (venue.distance > 10) score -= 0.5;

  return Math.round(score * 10) / 10;
}
