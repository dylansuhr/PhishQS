/**
 * LoggingService.js
 *
 * Centralized logging service for PhishQS server components.
 * Provides environment-aware, configurable logging with consistent formatting.
 *
 * Features:
 * - Environment-based log level control (development vs production)
 * - Emoji-prefixed consistent formatting
 * - Performance timing support
 * - Debug mode toggling
 * - Structured logging for better debugging
 */

import StatisticsConfig from '../Config/StatisticsConfig.js';

/**
 * Log levels in order of verbosity (higher number = more verbose)
 */
const LOG_LEVELS = {
    ERROR: 0,   // Always shown
    WARN: 1,    // Warnings and above
    INFO: 2,    // General information
    DEBUG: 3,   // Detailed debugging (development only)
    TRACE: 4    // Very verbose tracing (development only)
};

/**
 * Centralized logging service with environment-aware configuration
 */
export class LoggingService {

    /**
     * Get current log level based on environment and feature flags
     * @returns {number} Current log level
     */
    static getCurrentLogLevel() {
        const config = StatisticsConfig.getConfig();

        if (config.isDevelopment) {
            return StatisticsConfig.isFeatureEnabled('enableDebugLogging') ? LOG_LEVELS.DEBUG : LOG_LEVELS.INFO;
        } else {
            // Production: only errors and warnings
            return LOG_LEVELS.WARN;
        }
    }

    /**
     * Check if a log level should be shown
     * @param {number} messageLevel - Level of the message to log
     * @returns {boolean} True if message should be logged
     */
    static shouldLog(messageLevel) {
        return messageLevel <= this.getCurrentLogLevel();
    }

    /**
     * Log an error message (always shown)
     * @param {string} message - Error message
     * @param {Object} context - Optional context object
     */
    static error(message, context = {}) {
        if (this.shouldLog(LOG_LEVELS.ERROR)) {
            const formattedMessage = this.formatMessage('❌', 'ERROR', message);
            console.error(formattedMessage);
            if (Object.keys(context).length > 0) {
                console.error('   Context:', context);
            }
        }
    }

    /**
     * Log a warning message
     * @param {string} message - Warning message
     * @param {Object} context - Optional context object
     */
    static warn(message, context = {}) {
        if (this.shouldLog(LOG_LEVELS.WARN)) {
            const formattedMessage = this.formatMessage('⚠️', 'WARN', message);
            console.warn(formattedMessage);
            if (Object.keys(context).length > 0) {
                console.warn('   Context:', context);
            }
        }
    }

    /**
     * Log an info message
     * @param {string} message - Info message
     * @param {Object} context - Optional context object
     */
    static info(message, context = {}) {
        if (this.shouldLog(LOG_LEVELS.INFO)) {
            const formattedMessage = this.formatMessage('ℹ️', 'INFO', message);
            console.log(formattedMessage);
            if (Object.keys(context).length > 0) {
                console.log('   Context:', context);
            }
        }
    }

    /**
     * Log a debug message (development only)
     * @param {string} message - Debug message
     * @param {Object} context - Optional context object
     */
    static debug(message, context = {}) {
        if (this.shouldLog(LOG_LEVELS.DEBUG)) {
            const formattedMessage = this.formatMessage('🐛', 'DEBUG', message);
            console.log(formattedMessage);
            if (Object.keys(context).length > 0) {
                console.log('   Context:', context);
            }
        }
    }

    /**
     * Log a trace message (very verbose, development only)
     * @param {string} message - Trace message
     * @param {Object} context - Optional context object
     */
    static trace(message, context = {}) {
        if (this.shouldLog(LOG_LEVELS.TRACE)) {
            const formattedMessage = this.formatMessage('🔍', 'TRACE', message);
            console.log(formattedMessage);
            if (Object.keys(context).length > 0) {
                console.log('   Context:', context);
            }
        }
    }

    /**
     * Log a success message
     * @param {string} message - Success message
     * @param {Object} context - Optional context object
     */
    static success(message, context = {}) {
        if (this.shouldLog(LOG_LEVELS.INFO)) {
            const formattedMessage = this.formatMessage('✅', 'SUCCESS', message);
            console.log(formattedMessage);
            if (Object.keys(context).length > 0) {
                console.log('   Context:', context);
            }
        }
    }

    /**
     * Log a process start message
     * @param {string} message - Process description
     * @param {Object} context - Optional context object
     */
    static start(message, context = {}) {
        if (this.shouldLog(LOG_LEVELS.INFO)) {
            const formattedMessage = this.formatMessage('🚀', 'START', message);
            console.log(formattedMessage);
            if (Object.keys(context).length > 0) {
                console.log('   Context:', context);
            }
        }
    }

    /**
     * Performance timing utilities
     */
    static performance = {
        /**
         * Start a performance timer
         * @param {string} operation - Name of the operation
         * @returns {Object} Timer object with stop method
         */
        start(operation) {
            const startTime = process.hrtime.bigint();

            if (StatisticsConfig.isFeatureEnabled('enablePerformanceTiming')) {
                LoggingService.debug(`⏱️  Performance: Starting ${operation}`);
            }

            return {
                stop() {
                    const endTime = process.hrtime.bigint();
                    const duration = Number(endTime - startTime) / 1000000; // Convert to milliseconds

                    if (StatisticsConfig.isFeatureEnabled('enablePerformanceTiming')) {
                        LoggingService.info(`⏱️  Performance: ${operation} completed in ${duration.toFixed(2)}ms`);
                    }

                    return duration;
                }
            };
        }
    };

    /**
     * API call logging utilities
     */
    static api = {
        /**
         * Log an API request
         * @param {string} method - HTTP method
         * @param {string} url - API URL (with sensitive data masked)
         * @param {Object} context - Request context
         */
        request(method, url, context = {}) {
            LoggingService.debug(`📡 API Request: ${method} ${url}`, context);
        },

        /**
         * Log an API response
         * @param {string} method - HTTP method
         * @param {string} url - API URL (with sensitive data masked)
         * @param {number} status - HTTP status code
         * @param {number} duration - Response time in ms
         */
        response(method, url, status, duration) {
            const emoji = status >= 200 && status < 300 ? '✅' : '❌';
            LoggingService.info(`${emoji} API Response: ${method} ${url} - ${status} (${duration}ms)`);
        },

        /**
         * Log an API error
         * @param {string} method - HTTP method
         * @param {string} url - API URL (with sensitive data masked)
         * @param {Error} error - Error object
         */
        error(method, url, error) {
            LoggingService.error(`💥 API Error: ${method} ${url}`, {
                message: error.message,
                stack: error.stack
            });
        }
    };

    /**
     * Statistics-specific logging utilities
     */
    static stats = {
        /**
         * Log tour statistics calculation progress
         * @param {string} step - Current calculation step
         * @param {Object} data - Progress data
         */
        calculation(step, data = {}) {
            LoggingService.debug(`📊 Statistics: ${step}`, data);
        },

        /**
         * Log statistics results summary
         * @param {Object} results - Statistics results
         */
        results(results) {
            const summary = {
                longestSongs: results.longestSongs?.length || 0,
                rarestSongs: results.rarestSongs?.length || 0,
                mostPlayedSongs: results.mostPlayedSongs?.length || 0,
                mostCommonSongsNotPlayed: results.mostCommonSongsNotPlayed?.length || 0
            };
            LoggingService.success(`Statistics calculation completed`, summary);
        }
    };

    /**
     * Format a log message with consistent structure
     * @param {string} emoji - Emoji prefix
     * @param {string} level - Log level
     * @param {string} message - Message content
     * @returns {string} Formatted message
     */
    static formatMessage(emoji, level, message) {
        const timestamp = new Date().toISOString().slice(11, 23); // HH:mm:ss.sss
        return `${emoji} [${timestamp}] ${level}: ${message}`;
    }

    /**
     * Log current logging configuration (for debugging)
     */
    static logConfiguration() {
        const config = StatisticsConfig.getConfig();
        const currentLevel = this.getCurrentLogLevel();
        const levelName = Object.keys(LOG_LEVELS).find(key => LOG_LEVELS[key] === currentLevel);

        this.info('Logging Configuration', {
            environment: config.environment,
            currentLogLevel: `${levelName} (${currentLevel})`,
            debugLogging: config.features.enableDebugLogging,
            performanceTiming: config.features.enablePerformanceTiming,
            extendedLogging: config.features.enableExtendedLogging
        });
    }
}

/**
 * Default export for easy access
 */
export default LoggingService;