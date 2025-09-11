//import { LightningElement } from 'lwc';

//export default class GgwErrorHandler extends LightningElement {
/**
 * Wrapper function that handles both simple text strings and JSON objects
 * @param {string|Object} input - Either a simple text string or JSON object
 * @returns {string} - Formatted error message string
 */
export function errorMessage(input) {
    // Check if input is null or undefined
    if (input == null) {
    }
    
    // Check if input is a simple string
    if (typeof input === 'string') {
        return input;
    }
    
    // Check if input is an object (JSON) - handle it directly here
    if (typeof input === 'object') {
        // Initialize error message parts
        const errorParts = [];
        
        // Extract status code and status text
        if (input.status) {
            errorParts.push(`Status: ${input.status}`);
        }
        
        if (input.statusText) {
            errorParts.push(`(${input.statusText})`);
        }
        
        // Extract field errors if they exist
        if (input.body && input.body.fieldErrors) {
            const fieldErrors = input.body.fieldErrors;
            
            // Iterate through each field that has errors
            Object.keys(fieldErrors).forEach(fieldName => {
                const fieldErrorArray = fieldErrors[fieldName];
                
                // Process each error for this field
                fieldErrorArray.forEach(error => {
                    if (error.statusCode) {
                        errorParts.push(`Field: ${fieldName} - ${error.statusCode}`);
                    }
                    
                    if (error.message) {
                        // Truncate message to first 30 characters
                        const truncatedMessage = error.message.length > 30 
                            ? error.message.substring(0, 30) + '...' 
                            : error.message;
                        errorParts.push(`Message: ${truncatedMessage}`);
                    }
                });
            });
        }
        
        // Extract page errors if they exist
        if (input.body && input.body.pageErrors && input.body.pageErrors.length > 0) {
            input.body.pageErrors.forEach(pageError => {
                if (pageError.statusCode) {
                    errorParts.push(`Page Error: ${pageError.statusCode}`);
                }
                if (pageError.message) {
                    // Truncate page error message to first 30 characters
                    const truncatedPageMessage = pageError.message.length > 30 
                        ? pageError.message.substring(0, 30) + '...' 
                        : pageError.message;
                    errorParts.push(`Page Message: ${truncatedPageMessage}`);
                }
            });
        }
        
        // If no specific errors found, add a generic message
        if (errorParts.length === 0) {
            errorParts.push('An unknown error occurred');
        }
        
        // Join all error parts with line breaks for readability
        return errorParts.join('\n');
    }
    
    // For any other type, convert to string
    return String(input);
}

