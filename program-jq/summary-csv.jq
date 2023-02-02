sort_by(.startAt) | .[] | [.id, .startTime // .startAt, .endTime // .duration // 0, .name ] | @csv
