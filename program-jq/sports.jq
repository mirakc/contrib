[.[] | select(has("genres") and (.genres | any(.lv1 == 1)))]
