import argparse
import json
import re
import sys
import urllib.request

DESCRIPTION = 'Filter timeshift events'

EPILOG = '''
description:
  This script reads log messages from STDIN and outputs stream of timeshift
  events to STDOUT in a JSON format.

  Each JSON is delimited with a line feed.

json format:

  {
    "type": "start",  // or "end"
    "data": {
      // Metadata returned from the /api/timeshift/{recorder}/records/{record}
      // endpoint
    }
  }

examples:
  Extract timeshift events from logs, and pipe the JSON stream to another
  program to notify events:

    tail -F /path/to/mirakc.log | \\
      python3 %(prog)s --mirakc=http://mirakc:40772 | \\
      program-to-notify-events
'''

PATTERN = re.compile(
  r'(?P<recorder>\w+): Record#(?P<record_id>\w+): (?P<event_type>Started|Ended):')

def _eprint(*args, **kwargs):
  print(*args, file=sys.stderr, **kwargs)

parser = argparse.ArgumentParser(
  description=DESCRIPTION,
  epilog=EPILOG,
  formatter_class=argparse.RawDescriptionHelpFormatter)
parser.add_argument(
  '--mirakc',
  help="Base URL of mirakc")
parser.add_argument(
  '--debug',
  action='store_true',
  help="Output debug messages to STDERR")
args = parser.parse_args()

for line in sys.stdin:
  timestamp, level, module, message = re.split(r'\s+', line.strip(), 3)
  if module != 'mirakc_core::timeshift:':
    continue

  match = PATTERN.match(message)
  if not match:
    continue

  if args.debug:
    _eprint('{}'.format(message))

  recorder = match.group('recorder')
  record_id = int(match.group('record_id'), 16)
  if match.group('event_type') == 'Started':
    event_type = 'start'
  else:
    event_type = 'end'

  url = '{}/api/timeshift/{}/records/{}'.format(args.mirakc, recorder, record_id)
  if args.debug:
    _eprint('Loading metadata from {}...'.format(url))
  try:
    with urllib.request.urlopen(url) as res:
      record = json.loads(res.read().decode('utf8'))
  except:
    _eprint('ERROR: Failed to load metadata')
    continue

  if args.debug:
    _eprint('Output JSON...')
  print(json.dumps({
    'type': event_type,
    'data': record,
  }))
