# docker-tsduck

This folder contains a Dockerfile to build a Docker image containing the latest `tsduck` package.

```shell
docker build -t tsduck .
```

The `tsduck` package contains many commands which are useful for analyzing TS packets.

It's recommended to create the following small script:

```shell
#!/bin/sh
docker run --rm -i tsduck $@
```

Dump TS packets:

```shell
curl 'http://mirakc:40772/api/channels/GR/27/stream' | tsduck tsdump
```

Dump PSI/SI tables:

```shell
curl 'http://mirakc:40772/api/channels/GR/27/stream' | tsduck tstables
```
