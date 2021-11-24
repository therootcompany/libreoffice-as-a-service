'use strict';

let spawn = require('child_process').spawn;

async function exec(cmd, args, opts) {
  return await new Promise(function (resolve, reject) {
    let chunks = [];

    let proc = spawn(cmd, args, {
      windowsHide: true,
      shell: false,
      timeout: 60 * 1000,
      encoding: 'utf8',
      env: {
        SHELL: process.env.SHELL,
        PATH: process.env.PATH,
        HOME: process.env.HOME,
      },
      cwd: process.cwd(),
    });

    proc.stdout.on('readable', log);
    proc.stderr.on('readable', log);
    proc.on('error', function (err) {
      err.cmd = cmd + ' ' + args.join('');
      err.out = chunks.join('');
      reject(err);
    });
    proc.on('exit', function () {
      resolve(chunks.join());
    });
    if (opts?.stdin) {
      opts.stdin.pipe(proc.stdin);
    }

    function log() {
      let data;
      /*jshint validthis:true*/
      while ((data = this.read())) {
        //console.log(`[spawn: ${cmd}]`, data.toString('utf8'));
        chunks.push(data.toString('utf8'));
      }
    }
  });
}

/**
 * @params String inputPath - full path of input file
 * @params String format - the target format (typically file extension, such as 'pdf')
 * @returns Promise<string> - full path of output file
 */
async function convert(inputPath, format, options) {
  let Os = require('os');
  let Path = require('path');
  let Fsp = require('fs').promises;

  let cmd = 'soffice';
  // ex: /tmp/soffice-abc123
  let tmpPrefix = Path.join(Os.tmpdir(), 'soffice-');
  let tmpDir = await Fsp.mkdtemp(tmpPrefix);
  if (options?.filter) {
    // ex: --convert-to .pdf:"Special Filter Info"
    format += `:"${options.filter}"`;
  }
  let args = [
    `-env:UserInstallation=file://${tmpDir}`,
    '--headless',
    '--convert-to',
    format,
    '--outdir',
    tmpDir,
    inputPath,
  ];

  console.log(cmd, args.join(' '));
  await exec(cmd, args, { TODO_log: false });
  let basename = Path.basename(inputPath, Path.extname(inputPath));
  console.log('[soffice] basename:', basename);
  return Path.join(tmpDir, `${basename}.${format}`);
}

module.exports = convert;

if (require.main === module) {
  let input = process.argv[2];
  let outfile = process.argv[3];
  if (!input || !outfile) {
    console.error('Usage: node ./soffice.js input.docx output.pdf');
    process.exit(1);
  }

  let Path = require('path');
  let format = Path.extname(outfile).slice(1);

  // soffice can *technically* support reading from stdin,
  // but probably not in a more useful way that writing a tmp file to disk.
  // See https://unix.stackexchange.com/a/264127
  convert(input, format)
    .then(async function (out) {
      let Fsp = require('fs').promises;
      await Fsp.rename(out, outfile);
      console.info('Success!', out, outfile);
    })
    .catch(function (err) {
      console.error('Something went wrong:');
      console.error(err);
    });
}
