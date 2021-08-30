-- You can index jsonb columns, just the top level keys

CREATE INDEX idx ON slack USING GIN (reactionsb);

-- This is the same query from section 4
-- It filters by top level keys so should get a speed up from the index
SELECT author, reactionsb -> 'cookie' -> 0 AS eager_cookie_giver, reactionsb
FROM slack
WHERE reactionsb ? 'cookie';

-- Before indexing it took around 400ms
-- After indexing it takes around 175ms
-- Note the first time you run it after setting up the index it's a bit slower than 175ms,
-- probably building some internal cache
