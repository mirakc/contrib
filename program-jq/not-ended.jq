map(select(has("startAt") and ((has("duration") | not) or (has("duration") and ((.startAt + .duration) / 1000 > now)))))
