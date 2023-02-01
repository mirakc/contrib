[.[] | . + { startTime: (.startAt / 1000 | strflocaltime("%Y-%m-%d %H:%M")), endTime: ((.startAt + .duration) / 1000 | strflocaltime("%Y-%m-%d %H:%M")) }]
