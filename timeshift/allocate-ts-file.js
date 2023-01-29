import * as yaml from 'https://deno.land/std/encoding/yaml.ts';
import { default as docopt } from 'https://deno.land/x/docopt/mod.ts';

const CONFIG_YML = Deno.env.get('MIRAKC_CONFIG');

const DOC= `
Allocate each \`ts-file\` with its maximum size.

Usage:
  allocate-ts-file.js [options]
  allocate-ts-file.js -h | --help

Options:
  -c, --config=<config-yml>  [default: ${CONFIG_YML}]
    Path to config.yml.

Description:
  This script allocates the ts-file of each timeshift recorder with its maximum
  size which can be calculated using \`chunk-size\` and \`num-chunks\` defined
  in the config.yml.

Permissions:
  The following permissions are required:

    * --allow-env=MIRAKC_CONFIG
    * --allow-run=fallocate
    * --allow-read=<config.yml>
    * --allow-write<ts-file>
`.trim();

let args;
try {
  args = docopt(DOC, { optionsFirst: true })
} catch (err) {
  console.error(err.message);
  Deno.exit(1);
}

let configYml = args['--config'];
if (!configYml) {
  console.error('No <config-yml> is specified');
  Deno.exit(1);
}

const config = yaml.parse(await Deno.readTextFile(configYml));
for (const [name, timeshiftConfig] of Object.entries(config.timeshift.recorders)) {
  let tsFile = timeshiftConfig['ts-file'];
  let chunkSize = timeshiftConfig['chunk-size'] || 154009600;
  let numChunks = timeshiftConfig['num-chunks'];
  let size = chunkSize * numChunks;
  console.info(`${name}: allocating ${tsFile} with ${size}...`);
  let status = await Deno.run({
    cmd: ['fallocate', '-l', size, tsFile],
  }).status();
  if (!status.success) {
    console.error(`${name}: fallocate failed: ${status.code}`);
    Deno.exit(1);
  }
}

console.info('Done');
