'use strict';

function rnd(n) {
  let crypto = require('crypto');
  return crypto
    .randomBytes(n)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

module.exports = rnd;

if (require.main === module) {
  console.info(rnd(8));
}
