# program-jq

This folder contains useful `jq` filters used for collecting programs matching
particular conditions.

Collect only news programs which have not started yet:

```sh
curl http://mirakc:40772/api/programs | jq -f not-started.jq | jq -f news.jq
```

Add human-readable `startTime` and `endTime` properties:

```sh
curl http://mirakc:40772/api/programs | jq -f localtime.jq
```

Show summary in CSV:

```sh
# <id>,<startTime or startAt>,<endTime or duration>,<name>
curl http://mirakc:40772/api/programs | jq -f not-started.jq | \
  jq -f sports.jq | jq -f localtime.jq | jq -f summary-csv.jq
```
