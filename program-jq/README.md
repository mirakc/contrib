# program-jq

This folder contains useful `jq` filters used for collecting programs matching
particular conditions.

Collect only news programs which have not started yet:

```sh
curl http://mirakc:40772/api/programs -sG | \
  jq -f not-started.jq | \
  jq -f news.jq
```

Add human-readable `startTime` and `endTime` properties:

```sh
curl http://mirakc:40772/api/programs -sG | \
  jq -f localtime.jq
```

Filter by a Mirakurun service ID:

```sh
curl http://mirakc:40772/api/programs -sG | \
  jq -f msid.jq | jq 'map(select(.msid == 400103))'  # BSP
```

Show summary:

```sh
# <id>,<startTime>,<endTime>,<duration in min>,<name>
curl http://mirakc:40772/api/programs -sG | \
  jq -f not-started.jq | \
  jq -f sports.jq | \
  jq -f localtime.jq | \
  jq -f summary.jq | \
  jq -r '. | @tsv' | \
  sed -e '1i ID\tSTART\tEND\tMINS\tTITLE' | \
  column -s$'\t' -t
```
