import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';

// Create mock Redis methods
const mockGet = vi.fn();
const mockSet = vi.fn();
const mockDel = vi.fn();

// Mock @upstash/redis before importing cache module
vi.mock('@upstash/redis', () => {
  return {
    Redis: vi.fn(() => ({
      get: mockGet,
      set: mockSet,
      del: mockDel,
    })),
  };
});

// Mock crypto module
vi.mock('crypto', () => {
  const actualCrypto = vi.importActual('crypto');
  return {
    default: actualCrypto,
  };
});

describe('cache', () => {
  beforeEach(async () => {
    // Clear all mocks before each test
    vi.clearAllMocks();
    
    // Set up environment variables
    process.env.UPSTASH_REDIS_URL = 'https://test-redis.upstash.io';
    process.env.UPSTASH_REDIS_TOKEN = 'test-token';
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('generateCacheKey', () => {
    it('should generate cache key with correct pattern', async () => {
      const { generateCacheKey } = await import('../lib/cache');
      const key = generateCacheKey('New York', 'restaurant', 100);
      expect(key).toMatch(/^places:new york:restaurant:[a-f0-9]{8}$/);
    });

    it('should lowercase city and category', async () => {
      const { generateCacheKey } = await import('../lib/cache');
      const key = generateCacheKey('SAN FRANCISCO', 'BAR', 50);
      expect(key).toMatch(/^places:san francisco:bar:[a-f0-9]{8}$/);
    });

    it('should generate consistent hash for same budget', async () => {
      const { generateCacheKey } = await import('../lib/cache');
      const key1 = generateCacheKey('New York', 'restaurant', 100);
      const key2 = generateCacheKey('New York', 'restaurant', 100);
      expect(key1).toBe(key2);
    });

    it('should generate different hash for different budgets', async () => {
      const { generateCacheKey } = await import('../lib/cache');
      const key1 = generateCacheKey('New York', 'restaurant', 100);
      const key2 = generateCacheKey('New York', 'restaurant', 200);
      expect(key1).not.toBe(key2);
    });
  });

  describe('get', () => {
    it('should retrieve and return cached data', async () => {
      // Dynamic import after mocks are set up
      const { get } = await import('../lib/cache');
      const mockData = [{ id: '1', name: 'Test Venue' }];
      mockGet.mockResolvedValue(mockData);

      const result = await get<typeof mockData>('test-key');

      expect(result).toEqual(mockData);
      expect(mockGet).toHaveBeenCalledWith('test-key');
    });

    it('should return null on cache miss', async () => {
      const { get } = await import('../lib/cache');
      mockGet.mockResolvedValue(null);

      const consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {});
      const result = await get('test-key');

      expect(result).toBeNull();
      expect(consoleSpy).toHaveBeenCalledWith('Cache miss: test-key');
      consoleSpy.mockRestore();
    });

    it('should handle Redis errors gracefully and return null', async () => {
      const { get } = await import('../lib/cache');
      const error = new Error('Redis connection failed');
      mockGet.mockRejectedValue(error);

      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
      const result = await get('test-key');

      expect(result).toBeNull();
      expect(consoleSpy).toHaveBeenCalledWith(
        'Redis get error for key test-key:',
        'Redis connection failed'
      );
      consoleSpy.mockRestore();
    });

    it('should handle non-Error exceptions', async () => {
      const { get } = await import('../lib/cache');
      mockGet.mockRejectedValue('String error');

      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
      const result = await get('test-key');

      expect(result).toBeNull();
      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
    });
  });

  describe('set', () => {
    it('should store data with default TTL (604800 seconds)', async () => {
      const { set } = await import('../lib/cache');
      const mockData = [{ id: '1', name: 'Test Venue' }];
      mockSet.mockResolvedValue('OK');

      await set('test-key', mockData);

      expect(mockSet).toHaveBeenCalledWith('test-key', mockData, { ex: 604800 });
    });

    it('should store data with custom TTL', async () => {
      const { set } = await import('../lib/cache');
      const mockData = [{ id: '1', name: 'Test Venue' }];
      const customTTL = 3600; // 1 hour
      mockSet.mockResolvedValue('OK');

      await set('test-key', mockData, customTTL);

      expect(mockSet).toHaveBeenCalledWith('test-key', mockData, { ex: customTTL });
    });

    it('should handle Redis errors gracefully without throwing', async () => {
      const { set } = await import('../lib/cache');
      const error = new Error('Redis write failed');
      mockSet.mockRejectedValue(error);

      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      // Should not throw
      await expect(set('test-key', { data: 'test' })).resolves.toBeUndefined();

      expect(consoleSpy).toHaveBeenCalledWith(
        'Redis set error for key test-key:',
        'Redis write failed'
      );
      consoleSpy.mockRestore();
    });

    it('should store complex nested objects', async () => {
      const { set } = await import('../lib/cache');
      const complexData = {
        venues: [
          { id: '1', name: 'Venue 1', location: { lat: 40.7128, lng: -74.0060 } },
          { id: '2', name: 'Venue 2', location: { lat: 40.7589, lng: -73.9851 } },
        ],
        metadata: {
          city: 'New York',
          category: 'restaurant',
          count: 2,
        },
      };
      mockSet.mockResolvedValue('OK');

      await set('test-key', complexData, 86400);

      expect(mockSet).toHaveBeenCalledWith('test-key', complexData, { ex: 86400 });
    });
  });

  describe('del', () => {
    it('should delete a key from cache', async () => {
      const { del } = await import('../lib/cache');
      mockDel.mockResolvedValue(1);

      await del('test-key');

      expect(mockDel).toHaveBeenCalledWith('test-key');
    });

    it('should handle Redis errors gracefully when deleting', async () => {
      const { del } = await import('../lib/cache');
      const error = new Error('Redis delete failed');
      mockDel.mockRejectedValue(error);

      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      await expect(del('test-key')).resolves.toBeUndefined();

      expect(consoleSpy).toHaveBeenCalledWith(
        'Redis delete error for key test-key:',
        'Redis delete failed'
      );
      consoleSpy.mockRestore();
    });
  });

  describe('integration with generateCacheKey', () => {
    it('should work with generated cache keys', async () => {
      const { get, set, generateCacheKey } = await import('../lib/cache');
      const key = generateCacheKey('Chicago', 'bar', 75);
      const mockData = [{ id: '1', name: 'Chicago Bar' }];
      
      mockSet.mockResolvedValue('OK');
      mockGet.mockResolvedValue(mockData);

      await set(key, mockData, 604800);
      const result = await get<typeof mockData>(key);

      expect(result).toEqual(mockData);
      expect(mockSet).toHaveBeenCalledWith(key, mockData, { ex: 604800 });
      expect(mockGet).toHaveBeenCalledWith(key);
    });
  });
});

