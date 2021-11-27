'use strict';

// Note: You MUST load any ENVs BEFORE this file is required. Example:
// require('dotenv').config({ path: ".env" })

let config = module.exports;

config.NODE_ENV = process.env.NODE_ENV;
config.PORT = process.env.PORT;
config.API_TOKEN = process.env.API_TOKEN;

// CORS
config.CORS_DOMAINS = (process.env.CORS_DOMAINS || '')
  .trim()
  .split(/[,\s]+/g)
  .filter(Boolean);
config.CORS_METHODS = (process.env.CORS_METHODS || '')
  .trim()
  .split(/[,\s]+/g)
  .filter(Boolean);
