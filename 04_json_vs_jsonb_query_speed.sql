-- Some queries to compare the performance of the
-- json and jsonb columns for querying

-- Use the json column
-- For 100K records, this averaged around 600ms
SELECT author, reactions -> 'thilo-come-back' -> 0 AS eager_cookie_giver, reactions
FROM slack
WHERE reactions -> 'thilo-come-back' IS NOT NULL;

-- Use the jsonb column
-- For 100K records, this averaged around 400ms
SELECT author, reactionsb -> 'cookie' -> 0 AS eager_cookie_giver, reactionsb
FROM slack
WHERE reactionsb ? 'cookie';
--               ^ Able to use simpler syntax, json doesn't support this


-- Overall jsonb is faster to query because the json is already stored in an
-- efficient binary format.
-- The json column is basically just text and has to be reparsed on each new query.
-- One advantage this gives it is that it's faster to store it.
