/**
 * StatisticsConfig.js
 * 
 * Centralized configuration for tour statistics calculations.
 * Eliminates hardcoded values and provides environment-specific settings
 * for different deployment scenarios (development, production, testing).
 * 
 * Configuration Categories:
 * - Result limits (top N calculations)
 * - Debug and logging settings
 * - API endpoints and keys
 * - Performance thresholds
 * - Feature flags
 */

/**
 * Environment detection for configuration
 */
const getEnvironment = () => {
    // Check for Vercel environment variables
    if (process.env.VERCEL_ENV) {
        return process.env.VERCEL_ENV; // 'production', 'preview', 'development'
    }
    
    // Fallback to NODE_ENV
    return process.env.NODE_ENV || 'development';
};

/**
 * Base configuration shared across all environments
 */
const baseConfig = {
    
    // ===== RESULT LIMITS =====
    // Control how many results each statistics type returns
    
    /** @type {number} Default number of results for each statistics type */
    defaultResultLimit: 3,
    
    /** @type {Object} Specific limits for each statistics type */
    resultLimits: {
        longestSongs: 3,
        rarestSongs: 3,
        mostPlayedSongs: 3
    },
    
    // ===== HISTORICAL DATA ENHANCEMENT =====
    // Configuration for API-driven historical data enhancement
    
    /** @type {Object} Historical data enhancement settings */
    historicalDataEnhancement: {
        /** @type {boolean} Whether to enable historical data API calls */
        enabled: true,
        
        /** @type {Object} Enhancement settings for each statistics type */
        categories: {
            rarestSongs: {
                enabled: true,
                enhanceTopN: 3  // Easy to change to 10 for top 10
            },
            longestSongs: {
                enabled: false, // Could add venue history later
                enhanceTopN: 3
            },
            mostPlayedSongs: {
                enabled: false, // Could add debut dates later  
                enhanceTopN: 3
            }
        },
        
        /** @type {number} Delay between API calls (ms) for rate limiting */
        apiCallDelay: 100,
        
        /** @type {number} Timeout for individual historical data API calls (ms) */
        apiTimeout: 5000
    },
    
    // ===== PERFORMANCE THRESHOLDS =====
    // Define what constitutes notable performances
    
    /** @type {number} Duration threshold for "extended jam" logging (seconds) */
    extendedJamThreshold: 1800, // 30 minutes
    
    /** @type {number} Gap threshold for "rare song" logging */
    rareSongGapThreshold: 200,
    
    /** @type {number} Maximum debug results to log for analysis */
    debugResultLimit: 10,
    
    // ===== API CONFIGURATION =====
    // External API settings and endpoints
    
    /** @type {Object} Phish.net API configuration */
    phishNetApi: {
        baseUrl: 'https://api.phish.net/v5',
        defaultApiKey: process.env.PHISH_NET_API_KEY || '4771B8589CD3E53848E7',
        endpoints: {
            shows: '/setlists/showyear/{year}.json',
            setlist: '/setlists/showdate/{date}.json',
            songs: '/songs.json'
        }
    },
    
    /** @type {Object} Phish.in API configuration */
    phishInApi: {
        baseUrl: 'https://phish.in/api/v2',
        requiresApiKey: false,
        endpoints: {
            shows: '/shows',
            showByDate: '/shows/{date}',
            showsForTour: '/shows?tour_name={tourName}&per_page=500'
        }
    },
    
    // ===== CACHING CONFIGURATION =====
    // Cache settings for performance optimization
    
    /** @type {Object} Cache settings */
    cache: {
        /** @type {number} Default cache duration in seconds */
        defaultTtl: 3600, // 1 hour
        
        /** @type {number} Statistics cache duration (longer since data changes infrequently) */
        statisticsTtl: 7200, // 2 hours
        
        /** @type {boolean} Enable tour shows caching to avoid duplicate API calls */
        enableTourShowsCaching: true
    },
    
    // ===== FEATURE FLAGS =====
    // Enable/disable features for different environments
    
    /** @type {Object} Feature toggles */
    features: {
        /** @type {boolean} Enable comprehensive debug logging */
        enableDebugLogging: false,
        
        /** @type {boolean} Enable performance timing logs */
        enablePerformanceTiming: false,
        
        /** @type {boolean} Enable extended statistics logging */
        enableExtendedLogging: false,
        
        /** @type {boolean} Enable gap validation and warnings */
        enableGapValidation: true,
        
        /** @type {boolean} Enable automatic statistics regeneration */
        enableAutoRegeneration: true
    }
};

/**
 * Environment-specific configuration overrides
 */
const environmentConfigs = {
    
    // Development environment - verbose logging, shorter caches
    development: {
        features: {
            enableDebugLogging: true,
            enablePerformanceTiming: true,
            enableExtendedLogging: true
        },
        cache: {
            defaultTtl: 300, // 5 minutes for faster development iteration
            statisticsTtl: 600 // 10 minutes
        }
    },
    
    // Production environment - optimized for performance
    production: {
        features: {
            enableDebugLogging: false,
            enablePerformanceTiming: false,
            enableExtendedLogging: false
        },
        cache: {
            defaultTtl: 3600, // 1 hour
            statisticsTtl: 7200 // 2 hours
        }
    },
    
    // Preview environment - balanced settings for staging
    preview: {
        features: {
            enableDebugLogging: true,
            enablePerformanceTiming: true,
            enableExtendedLogging: false
        },
        cache: {
            defaultTtl: 1800, // 30 minutes
            statisticsTtl: 3600 // 1 hour
        }
    }
};

/**
 * Deep merge utility for combining configurations
 * @param {Object} target - Target object
 * @param {Object} source - Source object to merge
 * @returns {Object} Merged configuration
 */
function deepMerge(target, source) {
    const result = { ...target };
    
    for (const key in source) {
        if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
            result[key] = deepMerge(target[key] || {}, source[key]);
        } else {
            result[key] = source[key];
        }
    }
    
    return result;
}

/**
 * Current environment
 */
const environment = getEnvironment();

/**
 * Final configuration - base config merged with environment-specific overrides
 */
const config = deepMerge(baseConfig, environmentConfigs[environment] || {});

// Add environment metadata
config.environment = environment;
config.isProduction = environment === 'production';
config.isDevelopment = environment === 'development';

/**
 * Configuration accessor with type safety and validation
 */
export class StatisticsConfig {
    
    /**
     * Get the complete configuration object
     * @returns {Object} Complete configuration
     */
    static getConfig() {
        return { ...config };
    }
    
    /**
     * Get result limit for a specific statistics type
     * @param {string} statisticsType - Type of statistics (longestSongs, rarestSongs, mostPlayedSongs)
     * @returns {number} Result limit
     */
    static getResultLimit(statisticsType) {
        return config.resultLimits[statisticsType] || config.defaultResultLimit;
    }

    /**
     * Get historical data enhancement configuration
     * @param {string} statisticsType - Type of statistics (rarestSongs, longestSongs, mostPlayedSongs)
     * @returns {Object} Enhancement configuration object
     */
    static getHistoricalEnhancementConfig(statisticsType) {
        const category = config.historicalDataEnhancement.categories[statisticsType];
        if (!category) {
            return { enabled: false, enhanceTopN: 0 };
        }
        
        return {
            enabled: config.historicalDataEnhancement.enabled && category.enabled,
            enhanceTopN: category.enhanceTopN,
            apiCallDelay: config.historicalDataEnhancement.apiCallDelay,
            apiTimeout: config.historicalDataEnhancement.apiTimeout
        };
    }

    /**
     * Check if historical enhancement is needed for any statistics type
     * @returns {boolean} True if any category has historical enhancement enabled
     */
    static isHistoricalEnhancementEnabled() {
        if (!config.historicalDataEnhancement.enabled) return false;
        
        return Object.values(config.historicalDataEnhancement.categories)
            .some(category => category.enabled);
    }
    
    /**
     * Get calculator configuration with debug settings
     * @param {string} calculatorType - Type of calculator
     * @returns {Object} Calculator configuration
     */
    static getCalculatorConfig(calculatorType) {
        return {
            resultLimit: this.getResultLimit(calculatorType),
            debugMode: config.features.enableDebugLogging,
            extendedJamThreshold: config.extendedJamThreshold,
            rareSongGapThreshold: config.rareSongGapThreshold,
            debugResultLimit: config.debugResultLimit
        };
    }
    
    /**
     * Check if a feature is enabled
     * @param {string} featureName - Name of the feature
     * @returns {boolean} True if feature is enabled
     */
    static isFeatureEnabled(featureName) {
        return config.features[featureName] || false;
    }
    
    /**
     * Get API configuration for external services
     * @param {string} apiName - API name ('phishNet' or 'phishIn')
     * @returns {Object} API configuration
     */
    static getApiConfig(apiName) {
        const apiKey = apiName === 'phishNet' ? 'phishNetApi' : 'phishInApi';
        return config[apiKey];
    }
    
    /**
     * Get cache TTL for specific data type
     * @param {string} dataType - Type of data ('default' or 'statistics')
     * @returns {number} Cache TTL in seconds
     */
    static getCacheTtl(dataType = 'default') {
        const ttlKey = `${dataType}Ttl`;
        return config.cache[ttlKey] || config.cache.defaultTtl;
    }
    
    /**
     * Log current configuration (debug utility)
     */
    static logConfig() {
        if (config.features.enableDebugLogging) {
            console.log('📋 Statistics Configuration:');
            console.log(`   Environment: ${config.environment}`);
            console.log(`   Debug logging: ${config.features.enableDebugLogging}`);
            console.log(`   Result limits: ${JSON.stringify(config.resultLimits)}`);
            console.log(`   Cache TTLs: Default ${config.cache.defaultTtl}s, Stats ${config.cache.statisticsTtl}s`);
        }
    }
}

/**
 * Default export for easy access
 */
export default StatisticsConfig;