map(select(has("startAt") and (.startAt / 1000 > now)))
