const API_BASE_URL = __DEV__
  ? 'http://localhost:3000/api'
  : 'https://date-genie.vercel.app/api';

export interface Venue {
  id: string;
  name: string;
  address: string;
  priceLevel: string;
  rating: number;
  reviewCount: number;
  categories: string[];
  location: { lat: number; lng: number };
  vibeTags: string[];
  selectedCategories: string[];
  dateabilityScore: number;
  aiPitch: string;
  logisticsTip: string;
  bookingUrl: string;
  photoUrl?: string | null;
}

interface SearchResponse {
  success: boolean;
  source?: string;
  data: Venue[];
  latency?: number;
  error?: string;
}

export const DateGenieAPI = {
  async searchVenues(
    city: string,
    categories: string[],
    budget: number = 100,
    radius: number = 10,
    userId: string
  ): Promise<Venue[]> {
    const response = await fetch(`${API_BASE_URL}/search`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        city,
        query: categories.join(' '),
        budget,
        radius,
        categories,
        userId,
      }),
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }

    const result: SearchResponse = await response.json();

    if (!result.success) {
      throw new Error(result.error || 'Unknown API error');
    }

    return result.data;
  },

  trackEvent(event: string, properties: Record<string, any>) {
    console.log('📊 Analytics:', event, properties);
  },
};
