import { z } from 'zod';

export const dateCategorySchema = z.enum([
  'Food',
  'Fun',
  'Live Events',
  'Active',
  'Bars/Drinks',
  'Nature',
  'Romantic',
  'Cultural',
  'Adventure',
  'Relaxed',
  'Seasonal',
]);

export const searchQuerySchema = z.object({
  city: z.string().min(1),
  query: z.string().min(1),
  budget: z.number().min(0).max(1000),
  radius: z.number().min(1).max(50),
  categories: z.array(z.string()).min(1).max(3),
  userId: z.string().optional(),
  lat: z.number().optional(),
  lng: z.number().optional(),
  excludedVenueIds: z.array(z.string()).optional(),
});

export const dateabilitySchema = z.object({
  id: z.string(),
  name: z.string(),
  address: z.string(),
  price_level: z.string(),
  rating: z.number(),
  review_count: z.number(),
  categories: z.array(z.string()),
  latitude: z.number(),
  longitude: z.number(),
  distance: z.number(),
  vibe_tags: z.array(z.string()),
  selected_categories: z.array(z.string()),
});

export type DateabilityInput = z.infer<typeof dateabilitySchema>;
export type DateCategory = z.infer<typeof dateCategorySchema>;
