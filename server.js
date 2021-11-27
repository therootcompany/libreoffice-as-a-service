'use strict';

let Path = require('path');
require('dotenv').config({ path: '../.env.secret' });
require('dotenv').config({ path: '.env' });
require('dotenv').config({ path: Path.join(process.env.HOME, '.env') });

let config = require('./config.js');

let Http = require('http');

let fastify = require('fastify')({
  logger: true,
  serverFactory: function (handler, opts) {
    let httpServer = Http.createServer(handler);
    return httpServer;
  },
});
let fastifyStatic = require('fastify-static');

fastify.register(fastifyStatic, {
  root: Path.join(__dirname, 'public'),
  prefix: '/',
});

fastify.register(require('./routes/convert.js'), { prefix: '/api/convert' });

if (require.main === module) {
  fastify
    .listen(config.PORT || 5227, '0.0.0.0')
    .then(function (address) {
      console.info('');
      console.info('Listening on', address);
      console.info('');
    })
    .catch(function (err) {
      console.error('Error starting server:', err);
      process.exit(1);
    });
} else {
  module.exports = fastify;
}
