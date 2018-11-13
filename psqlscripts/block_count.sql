-- find the count of blocks a particular query needs to pull from (clustering factor)
-- for example:

-- select count(distinct regexp_match(ctid::text, '\(.*,')) from ts_rawqualifier where timeseriesid=38689171;
-- select count(distinct regexp_match(ctid::text, '\(.*,'))  from discretemeasurement where locationvisitid=886169;
