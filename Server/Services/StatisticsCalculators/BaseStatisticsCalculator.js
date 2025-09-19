/**
 * BaseStatisticsCalculator.js
 *
 * Abstract base class for all tour statistics calculators.
 * Provides shared functionality and enforces consistent interface
 * across different statistics calculation types.
 *
 * Design Pattern: Template Method + Strategy Pattern
 * - Template method defines calculation workflow
 * - Strategy pattern allows different calculation algorithms
 * - Extensible for future statistics types
 */

import LoggingService from '../LoggingService.js';

/**
 * Abstract base class for statistics calculators
 * 
 * All statistics calculators must extend this class and implement
 * the abstract methods for data collection and result processing.
 */
export class BaseStatisticsCalculator {
    
    /**
     * Initialize calculator with configuration
     * @param {Object} config - Configuration object with limits and settings
     */
    constructor(config = {}) {
        /** @type {number} Maximum number of results to return (default: 3) */
        this.resultLimit = config.resultLimit || 3;
        
        /** @type {boolean} Enable debug logging */
        this.debugMode = config.debugMode || false;
        
        /** @type {string} Calculator type name for logging */
        this.calculatorType = this.constructor.name;
    }
    
    /**
     * Main calculation method - Template Method Pattern
     *
     * Defines the standard workflow for all statistics calculations:
     * 1. Validate input data
     * 2. Initialize data containers
     * 3. Process each tour show
     * 4. Generate final results
     * 5. Apply result limiting
     *
     * @param {Array} tourShows - All enhanced setlists for the tour
     * @param {string} tourName - Name of the tour
     * @param {Object} context - Additional context data for specialized calculators
     * @returns {Array} Calculated statistics results
     */
    calculate(tourShows, tourName, context = {}) {
        this.log(`🧮 ${this.calculatorType}: Starting calculation for ${tourShows?.length || 0} shows`);
        
        // Step 1: Validate input
        if (!this.validateInput(tourShows, tourName)) {
            this.log(`⚠️  ${this.calculatorType}: Invalid input, returning empty results`);
            return [];
        }
        
        // Step 2: Initialize data collection containers
        const dataContainer = this.initializeDataContainer();
        
        // Step 3: Process each tour show (single pass)
        tourShows.forEach((show, index) => {
            this.log(`📅 Processing show ${index + 1}/${tourShows.length}: ${show.showDate}`);
            this.processShow(show, dataContainer);
        });
        
        // Step 4: Generate results from collected data
        const results = this.generateResults(dataContainer, tourName, context);
        
        // Step 5: Apply result limiting and return
        const limitedResults = results.slice(0, this.resultLimit);
        this.log(`✅ ${this.calculatorType}: Generated ${limitedResults.length} results`);
        
        return limitedResults;
    }
    
    /**
     * Validate input parameters
     * @param {Array} tourShows - Tour shows array
     * @param {string} tourName - Tour name
     * @returns {boolean} True if input is valid
     */
    validateInput(tourShows, tourName) {
        return Array.isArray(tourShows) && 
               tourShows.length > 0 && 
               typeof tourName === 'string';
    }
    
    /**
     * Log debug messages if debug mode is enabled
     * @param {string} message - Message to log
     */
    log(message) {
        if (this.debugMode) {
            LoggingService.debug(message);
        }
    }
    
    // Abstract methods that must be implemented by subclasses
    
    /**
     * Initialize data collection container
     * @abstract
     * @returns {Object} Initialized data container
     * @throws {Error} If not implemented by subclass
     */
    initializeDataContainer() {
        throw new Error(`${this.calculatorType} must implement initializeDataContainer()`);
    }
    
    /**
     * Process a single tour show and update data container
     * @abstract
     * @param {Object} show - Enhanced setlist data for one show
     * @param {Object} dataContainer - Data collection container
     * @throws {Error} If not implemented by subclass
     */
    processShow(show, dataContainer) {
        throw new Error(`${this.calculatorType} must implement processShow(show, dataContainer)`);
    }
    
    /**
     * Generate final results from collected data
     * @abstract
     * @param {Object} dataContainer - Data collection container with processed data
     * @param {string} tourName - Tour name for context
     * @param {Object} context - Additional context data for specialized calculators
     * @returns {Array} Final calculated results
     * @throws {Error} If not implemented by subclass
     */
    generateResults(dataContainer, tourName, context = {}) {
        throw new Error(`${this.calculatorType} must implement generateResults(dataContainer, tourName, context)`);
    }
    
    /**
     * Capitalize words in a string for consistent display formatting
     * @param {string} str - String to capitalize
     * @returns {string} Capitalized string
     */
    static capitalizeWords(str) {
        return str.replace(/\w\S*/g, txt => 
            txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
        );
    }
    
    /**
     * Generate hash code for string (for consistent IDs)
     * @param {string} str - String to hash
     * @returns {number} Hash code
     */
    static hashCode(str) {
        let hash = 0;
        if (str.length === 0) return hash;
        for (let i = 0; i < str.length; i++) {
            const char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32bit integer
        }
        return Math.abs(hash);
    }
}