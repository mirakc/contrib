import { format } from 'https://deno.land/std@0.173.0/datetime/mod.ts';
import { default as docopt } from 'https://deno.land/x/docopt@v1.0.7/mod.ts';
import { EventSource } from 'https://deno.land/x/eventsource@v0.0.3/mod.ts';

const DEFAULT_BASE_URL = 'http://localhost:40772';

const DOC = `
Add recording schedules automatically according to rules.

Usage:
  simple-rules.js [options]
  simple-rules.js -h | --help

Options:
  -b, --base-url=<base-url>  [default: ${DEFAULT_BASE_URL}]
    Base URL.

  --folder=<folder>  [default: .]
    Folder name of recorded files.

  --dry-run
    No recording schedule will be added.

Description:
  This script starts listening the following events coming from the /events
  endpoint:

    epg.programs-updated
    onair.program-changed

  When an event is received, recording schedules are added according to rules.

  A rule is just an async function which adds the program ID of a TV program to
  be recorded.  See RULES for details.
`.trim();

let args;
try {
  args = docopt(DOC, { optionsFirst: true })
} catch (err) {
  console.error(err.message);
  Deno.exit(0);
}

let base_url = args['--base-url'];
let dryRun = args['--dry-run'];
let folder = args['--folder'];

// event source

const url = `${base_url}/events`;
console.log(`Connect to ${url}...`);

const source = new EventSource(url);
source.addEventListener('error', (err) => {
  console.error("Failed to connect");
  Deno.exit(1);
});

// epg.programs-updated

source.addEventListener('epg.programs-updated', async (event) => {
  const { serviceId } = JSON.parse(event.data);
  const service = await getService(serviceId);
  console.info(`EPG programs updated: ${service.name}: ${service.id}`);
  const programs = await getPrograms(service.id);
  await updateRecordingSchedules(service, programs);
});

// rules

const RULES = [
  // ＮＨＫニュース７
  async (service, program, targets) => {
    if (service.id !== 3273601024) {
      return;
    }
    if (program.name && program.name.includes("ＮＨＫニュース７")) {
      addOrUpdateTargets(program, "ＮＨＫニュース７", targets);
    }
  },
];

// helpers

async function updateRecordingSchedules(service, programs) {
  const schedules = await getRecordingSchedules();

  let targets = {};
  for (const program of Object.values(programs)) {
    for (const rule of RULES) {
      await rule(service, program, targets);
    }
  }

  await addRecordingSchedules(targets, service, programs, schedules);
}

async function getService(serviceId) {
  const resp = await fetch(`${base_url}/api/services/${serviceId}`);
  return await resp.json();
}

async function getPrograms(serviceId) {
  const now = Date.now();
  const resp = await fetch(`${base_url}/api/services/${serviceId}/programs`);
  const programs = await resp.json();
  // `programs` contains ended TV programs.
  return programs.reduce((acc, program) => {
    if (program.startAt > now + 30000) { // +30s
      acc[program.id] = program;
    }
    return acc;
  }, {});
}

async function getRecordingSchedules() {
  const resp = await fetch(`${base_url}/api/recording/schedules`);
  const schedules = await resp.json();
  return schedules.reduce((acc, schedule) => {
    acc[schedule.program.id] = schedule;
    return acc;
  }, {});
}

async function addRecordingSchedules(targets, service, programs, schedules) {
  for (const [programId, data] of Object.entries(targets)) {
    if (programId in schedules) {
      const schedule = schedules[programId];
      console.info(`Already exists: ${stringifySchedule(service, schedule)}`);
    } else {
      const program = programs[programId];
      if (dryRun) {
        console.info(`Matched: ${stringifyProgram(service, program)}`);
      } else {
        const date = format(new Date(program.startAt), "yyyyMMddHHmm");
        console.log(JSON.stringify({
          programId: program.id,
          options: {
            contentPath: `${folder}/${date}_${program.id}.m2ts`,
          },
          tags: Array.from(data.tags),
        }));
        const resp = await fetch(`${base_url}/api/recording/schedules`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            programId: program.id,
            options: {
              contentPath: `${folder}/${date}_${program.id}.m2ts`,
            },
            tags: Array.from(data.tags),
          }),
        });
        const schedule = await resp.json();
        console.info(`Added: ${stringifySchedule(service, schedule)}`);
      }
    }
  }
}

function stringifyProgram(service, program) {
  const startAt = new Date(program.startAt);
  return `${service.name}: ${program.id}: ${startAt}: ${program.name}`;
}

function stringifySchedule(service, schedule) {
  return `${schedule.state}: ${stringifyProgram(service, schedule.program)}`;
}

function addOrUpdateTargets(program, tag, targets) {
  if (program.id in targets) {
    targets[program.id].tags.add(TAG);
  } else {
    targets[program.id] = {
      tags: new Set(["rules", tag])
    };
  }
}
