/**
 * StatisticsRegistry.js
 * 
 * Registry pattern implementation for tour statistics calculators.
 * Provides a centralized system for registering, discovering, and executing
 * different types of statistics calculations. Enables easy addition of new
 * statistics types without modifying core service logic.
 * 
 * Design Pattern: Registry + Factory
 * - Registry: Manages calculator registration and discovery
 * - Factory: Creates calculator instances with proper configuration
 * - Strategy: Different calculation algorithms through common interface
 * 
 * Extensibility: Adding new statistics types requires:
 * 1. Create new calculator class extending BaseStatisticsCalculator
 * 2. Register calculator in this registry
 * 3. Statistics will be automatically included in generation
 */

import StatisticsConfig from '../Config/StatisticsConfig.js';
import LoggingService from './LoggingService.js';
import { LongestSongsCalculator } from './StatisticsCalculators/LongestSongsCalculator.js';
import { RarestSongsCalculator } from './StatisticsCalculators/RarestSongsCalculator.js';
import { MostPlayedSongsCalculator } from './StatisticsCalculators/MostPlayedSongsCalculator.js';
import { MostCommonSongsNotPlayedCalculator } from './StatisticsCalculators/MostCommonSongsNotPlayedCalculator.js';
import { SetSongStatsCalculator } from './StatisticsCalculators/SetSongStatsCalculator.js';
import { OpenersClosersCalculator } from './StatisticsCalculators/OpenersClosersCalculator.js';

/**
 * Registry for managing statistics calculators
 * 
 * Provides centralized registration, configuration, and execution
 * of all tour statistics calculation types.
 */
export class StatisticsRegistry {
    
    /**
     * Initialize registry with default calculators
     */
    constructor() {
        /** @type {Map<string, Object>} Registered calculators with metadata */
        this.calculators = new Map();
        
        /** @type {Map<string, Function>} Calculator class constructors */
        this.calculatorClasses = new Map();
        
        // Register built-in calculators
        this.registerBuiltInCalculators();
    }
    
    /**
     * Register all built-in statistics calculators
     * @private
     */
    registerBuiltInCalculators() {
        
        // Longest Songs Calculator
        this.registerCalculator('longestSongs', {
            name: 'Longest Songs',
            description: 'Identifies songs with longest performance durations',
            dataSource: 'Phish.in track durations',
            calculatorClass: LongestSongsCalculator,
            resultType: 'TrackDuration',
            enabled: true,
            priority: 1 // Display order priority
        });
        
        // Rarest Songs Calculator  
        this.registerCalculator('rarestSongs', {
            name: 'Rarest Songs',
            description: 'Identifies songs with highest gaps (shows since last played)',
            dataSource: 'Phish.net setlist gap data',
            calculatorClass: RarestSongsCalculator,
            resultType: 'SongGapInfo',
            enabled: true,
            priority: 2
        });
        
        // Most Played Songs Calculator
        this.registerCalculator('mostPlayedSongs', {
            name: 'Most Played Songs',
            description: 'Identifies songs played most frequently during tour',
            dataSource: 'Song frequency analysis from track data',
            calculatorClass: MostPlayedSongsCalculator,
            resultType: 'MostPlayedSong',
            enabled: true,
            priority: 3
        });

        // Most Common Songs Not Played Calculator
        this.registerCalculator('mostCommonSongsNotPlayed', {
            name: 'Most Common Songs Not Played',
            description: 'Identifies popular songs from Phish history absent from current tour',
            dataSource: 'Comprehensive song database with historical play counts',
            calculatorClass: MostCommonSongsNotPlayedCalculator,
            resultType: 'MostCommonSongNotPlayed',
            enabled: true,
            priority: 4
        });

        // Set Song Stats Calculator
        this.registerCalculator('setSongStats', {
            name: 'Songs Per Set',
            description: 'Identifies shows with most/fewest songs per set type',
            dataSource: 'Phish.net setlist data',
            calculatorClass: SetSongStatsCalculator,
            resultType: 'SetSongStats',
            enabled: true,
            priority: 5
        });

        // Openers, Closers, & Encores Calculator
        this.registerCalculator('openersClosers', {
            name: 'Openers, Closers, & Encores',
            description: 'Tracks set openers, closers, and encore songs with play counts',
            dataSource: 'Phish.net setlist data',
            calculatorClass: OpenersClosersCalculator,
            resultType: 'OpenersClosersStats',
            enabled: true,
            priority: 6
        });
    }
    
    /**
     * Register a new statistics calculator
     * 
     * @param {string} type - Unique calculator type identifier
     * @param {Object} metadata - Calculator metadata and configuration
     * @param {string} metadata.name - Display name
     * @param {string} metadata.description - Description of what this calculates
     * @param {string} metadata.dataSource - Data source description
     * @param {Function} metadata.calculatorClass - Calculator class constructor
     * @param {string} metadata.resultType - Type of results returned
     * @param {boolean} metadata.enabled - Whether calculator is enabled
     * @param {number} metadata.priority - Display order priority (lower = first)
     */
    registerCalculator(type, metadata) {
        // Validate required metadata
        const required = ['name', 'calculatorClass', 'resultType'];
        for (const field of required) {
            if (!metadata[field]) {
                throw new Error(`Calculator registration missing required field: ${field}`);
            }
        }
        
        // Validate calculator class extends BaseStatisticsCalculator
        if (!this.validateCalculatorClass(metadata.calculatorClass)) {
            throw new Error(`Calculator class must extend BaseStatisticsCalculator`);
        }
        
        // Store calculator metadata
        this.calculators.set(type, {
            type,
            name: metadata.name,
            description: metadata.description || '',
            dataSource: metadata.dataSource || 'Unknown',
            resultType: metadata.resultType,
            enabled: metadata.enabled !== false, // Default to enabled
            priority: metadata.priority || 999
        });
        
        // Store calculator class constructor
        this.calculatorClasses.set(type, metadata.calculatorClass);
        
        if (StatisticsConfig.isFeatureEnabled('enableDebugLogging')) {
            LoggingService.debug(`Registered calculator: ${metadata.name} (${type})`);
        }
    }
    
    /**
     * Validate that calculator class follows the expected interface
     * @param {Function} calculatorClass - Calculator class to validate
     * @returns {boolean} True if valid calculator class
     * @private
     */
    validateCalculatorClass(calculatorClass) {
        try {
            // Check if class has required methods
            const instance = new calculatorClass();
            const requiredMethods = ['calculate', 'initializeDataContainer', 'processShow', 'generateResults'];
            
            return requiredMethods.every(method => typeof instance[method] === 'function');
        } catch (error) {
            return false;
        }
    }
    
    /**
     * Get metadata for all registered calculators
     * @returns {Array<Object>} Array of calculator metadata objects
     */
    getRegisteredCalculators() {
        return Array.from(this.calculators.values())
            .sort((a, b) => a.priority - b.priority);
    }
    
    /**
     * Get metadata for enabled calculators only
     * @returns {Array<Object>} Array of enabled calculator metadata
     */
    getEnabledCalculators() {
        return this.getRegisteredCalculators()
            .filter(calc => calc.enabled);
    }
    
    /**
     * Check if a calculator is registered and enabled
     * @param {string} type - Calculator type identifier
     * @returns {boolean} True if calculator is registered and enabled
     */
    isCalculatorAvailable(type) {
        const calculator = this.calculators.get(type);
        return calculator && calculator.enabled;
    }
    
    /**
     * Create calculator instance with proper configuration
     * @param {string} type - Calculator type identifier
     * @returns {Object} Configured calculator instance
     * @throws {Error} If calculator type is not registered or disabled
     */
    createCalculator(type) {
        if (!this.isCalculatorAvailable(type)) {
            throw new Error(`Calculator '${type}' is not registered or is disabled`);
        }
        
        const CalculatorClass = this.calculatorClasses.get(type);
        const config = StatisticsConfig.getCalculatorConfig(type);
        
        return new CalculatorClass(config);
    }
    
    /**
     * Execute all enabled calculators and return combined results
     *
     * @param {Array} tourShows - All enhanced setlists for the tour
     * @param {string} tourName - Name of the tour
     * @param {Object} context - Additional context data for calculators (optional)
     * @param {Array} context.comprehensiveSongs - Complete song database for calculators that need it
     * @returns {Object} Combined results from all calculators
     */
    calculateAllStatistics(tourShows, tourName, context = {}) {
        if (StatisticsConfig.isFeatureEnabled('enablePerformanceTiming')) {
            console.time('🚀 Total Statistics Calculation');
        }
        
        const results = {};
        const enabledCalculators = this.getEnabledCalculators();
        
        if (StatisticsConfig.isFeatureEnabled('enableDebugLogging')) {
            LoggingService.info(`Executing ${enabledCalculators.length} statistics calculators for ${tourShows?.length || 0} shows`);
        }
        
        // Execute each enabled calculator
        for (const calculatorInfo of enabledCalculators) {
            const { type, name } = calculatorInfo;
            
            try {
                if (StatisticsConfig.isFeatureEnabled('enablePerformanceTiming')) {
                    console.time(`⏱️  ${name}`);
                }
                
                const calculator = this.createCalculator(type);
                const calculationResults = calculator.calculate(tourShows, tourName, context);
                
                // Store results using calculator type as key
                results[type] = calculationResults;
                
                if (StatisticsConfig.isFeatureEnabled('enablePerformanceTiming')) {
                    console.timeEnd(`⏱️  ${name}`);
                }
                
                if (StatisticsConfig.isFeatureEnabled('enableDebugLogging')) {
                    LoggingService.debug(`${name}: Generated ${calculationResults.length} results`);
                }
                
            } catch (error) {
                LoggingService.error(`Error calculating ${name}:`, error.message);
                
                // Store empty results for failed calculations to maintain structure
                results[type] = [];
            }
        }
        
        if (StatisticsConfig.isFeatureEnabled('enablePerformanceTiming')) {
            console.timeEnd('🚀 Total Statistics Calculation');
        }
        
        return results;
    }
    
    /**
     * Enable or disable a calculator
     * @param {string} type - Calculator type identifier
     * @param {boolean} enabled - Whether to enable the calculator
     */
    setCalculatorEnabled(type, enabled) {
        const calculator = this.calculators.get(type);
        if (calculator) {
            calculator.enabled = enabled;
            
            if (StatisticsConfig.isFeatureEnabled('enableDebugLogging')) {
                const status = enabled ? 'enabled' : 'disabled';
                LoggingService.debug(`Calculator '${calculator.name}' ${status}`);
            }
        }
    }
    
    /**
     * Get registry statistics for monitoring/debugging
     * @returns {Object} Registry statistics
     */
    getRegistryStats() {
        const all = this.getRegisteredCalculators();
        const enabled = this.getEnabledCalculators();
        
        return {
            totalCalculators: all.length,
            enabledCalculators: enabled.length,
            disabledCalculators: all.length - enabled.length,
            calculatorTypes: all.map(calc => calc.type)
        };
    }
}

/**
 * Singleton registry instance
 * Export single instance for consistent calculator registration across the application
 */
export const statisticsRegistry = new StatisticsRegistry();

/**
 * Default export
 */
export default statisticsRegistry;