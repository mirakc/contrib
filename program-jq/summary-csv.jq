sort_by(.startAt) | .[] | if has("startTime") then [.id, .startTime, .endTime, .duration / 60000, .name ] else [.id, .startAt, .duration, .name] end | @csv
