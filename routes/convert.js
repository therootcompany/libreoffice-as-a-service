'use strict';

let tmpdir = require('os').tmpdir();
let Path = require('path');
let Fs = require('fs');
let Fsp = require('fs').promises;

let convert = require('../soffice.js');

module.exports = function (fastify, opts, done) {
  fastify.addContentTypeParser('*', function (request, payload, done) {
    // skip parsing so that the handler has access to the stream
    //request.raw.pause();
    console.log('rando type?');
    console.log(request.raw.rawHeaders);
    done();
  });

  async function receive(req, name, format = 'pdf') {
    let dirname = await Fsp.mkdtemp(Path.join(tmpdir, 'libreoffice-convert-'));
    console.log('tmpdir:', dirname);
    let dst = Path.join(dirname, name);
    let stream = Fs.createWriteStream(dst);

    let originalPath = await new Promise(function (resolve, reject) {
      req.pipe(stream);
      req.on('readable', function () {
        let chunk;
        while ((chunk = req.read())) {
          console.log('chunk', chunk.length);
        }
      });
      req.on('error', reject);
      req.on('end', function () {
        // remember: close() for files, end() for network streams
        stream.close();
        stream.on('close', function () {
          resolve(dst);
        });
      });
    });

    let pdfPath = await convert(originalPath, format);
    return pdfPath;
  }

  // POST /api/convert/:name (ex: report.docx)
  fastify.post('/:format', async function (request, reply) {
    // target format
    let format = request.params.format;

    // content-disposition filename hint
    let filename = request.query.filename;
    if (!filename) {
      throw new Error("BAD_REQUEST: 'filename' should be the name of the source file");
    }

    let dst = await receive(request.raw, filename, format);
    let stream = Fs.createReadStream(dst);
    stream.on('end', async function () {
      await Fsp.unlink(dst).catch(function (err) {
        console.error(`Error: failed to remove ${dst}`);
      });
    });

    let suggestedName = Path.basename(dst).replace(/"/g, '\\"');
    reply.header('Content-Disposition', `attachment; filename="${suggestedName}"`);
    reply.send(stream);
  });

  done();
};
