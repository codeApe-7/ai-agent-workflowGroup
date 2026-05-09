'use strict';

/**
 * Minimal JSON Schema (Draft-07 subset) validator — zero deps.
 *
 * Supported keywords:
 *   type, required, enum, const, pattern, format(date-time), additionalProperties,
 *   properties, items, minLength, minItems, uniqueItems, default(passthrough), oneOf
 *
 * Not supported (out of scope for our schemas): $ref resolution across files, allOf,
 * anyOf, not, dependencies, conditionals (if/then/else). If you add those to a schema,
 * extend this file.
 */

const fs = require('fs');

const ISO_DATETIME_RE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$/;

function loadSchema(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(raw);
}

function jsTypeOf(value) {
  if (value === null) return 'null';
  if (Array.isArray(value)) return 'array';
  if (Number.isInteger(value)) return 'integer';
  return typeof value; // string, number, boolean, object, undefined
}

function matchesType(value, type) {
  if (Array.isArray(type)) return type.some(t => matchesType(value, t));
  const actual = jsTypeOf(value);
  if (type === 'integer') return actual === 'integer';
  if (type === 'number') return actual === 'integer' || actual === 'number';
  return actual === type;
}

function validate(value, schema, pathPrefix = '$') {
  const errors = [];

  if (schema === true) return errors;
  if (schema === false) {
    errors.push(`${pathPrefix}: schema explicitly forbids this value`);
    return errors;
  }
  if (!schema || typeof schema !== 'object') return errors;

  // type
  if (schema.type !== undefined && !matchesType(value, schema.type)) {
    errors.push(`${pathPrefix}: expected type ${JSON.stringify(schema.type)}, got ${jsTypeOf(value)}`);
    return errors; // bail — downstream checks meaningless
  }

  // const
  if (schema.const !== undefined && value !== schema.const) {
    errors.push(`${pathPrefix}: expected const ${JSON.stringify(schema.const)}, got ${JSON.stringify(value)}`);
  }

  // enum
  if (Array.isArray(schema.enum) && !schema.enum.includes(value)) {
    errors.push(`${pathPrefix}: value not in enum ${JSON.stringify(schema.enum)}`);
  }

  // string-specific
  if (typeof value === 'string') {
    if (typeof schema.minLength === 'number' && value.length < schema.minLength) {
      errors.push(`${pathPrefix}: shorter than minLength ${schema.minLength}`);
    }
    if (schema.pattern && !new RegExp(schema.pattern).test(value)) {
      errors.push(`${pathPrefix}: does not match pattern /${schema.pattern}/`);
    }
    if (schema.format === 'date-time' && !ISO_DATETIME_RE.test(value)) {
      errors.push(`${pathPrefix}: not a valid ISO-8601 date-time`);
    }
  }

  // array-specific
  if (Array.isArray(value)) {
    if (typeof schema.minItems === 'number' && value.length < schema.minItems) {
      errors.push(`${pathPrefix}: array shorter than minItems ${schema.minItems}`);
    }
    if (schema.uniqueItems === true) {
      const seen = new Set();
      for (const item of value) {
        const key = JSON.stringify(item);
        if (seen.has(key)) {
          errors.push(`${pathPrefix}: array has duplicate items`);
          break;
        }
        seen.add(key);
      }
    }
    if (schema.items) {
      for (let i = 0; i < value.length; i += 1) {
        errors.push(...validate(value[i], schema.items, `${pathPrefix}[${i}]`));
      }
    }
  }

  // object-specific
  if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
    if (Array.isArray(schema.required)) {
      for (const key of schema.required) {
        if (!(key in value)) errors.push(`${pathPrefix}.${key}: required field missing`);
      }
    }
    if (schema.properties) {
      for (const [key, propSchema] of Object.entries(schema.properties)) {
        if (key in value) {
          errors.push(...validate(value[key], propSchema, `${pathPrefix}.${key}`));
        }
      }
    }
    if (schema.additionalProperties === false && schema.properties) {
      const allowed = new Set(Object.keys(schema.properties));
      for (const key of Object.keys(value)) {
        if (!allowed.has(key)) errors.push(`${pathPrefix}.${key}: additionalProperties not allowed`);
      }
    }
  }

  // oneOf
  if (Array.isArray(schema.oneOf)) {
    const matches = schema.oneOf.filter(sub => validate(value, sub, pathPrefix).length === 0);
    if (matches.length === 0) {
      errors.push(`${pathPrefix}: matches none of oneOf branches`);
    } else if (matches.length > 1) {
      errors.push(`${pathPrefix}: matches ${matches.length} oneOf branches (must match exactly 1)`);
    }
  }

  return errors;
}

function validateAgainstSchema(data, schema) {
  const errors = validate(data, schema);
  return { valid: errors.length === 0, errors };
}

module.exports = {
  loadSchema,
  validateAgainstSchema,
  validate
};
