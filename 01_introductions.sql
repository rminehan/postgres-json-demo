-- Explore our table
SELECT * FROM slack LIMIT 100;

-- Inserting a document
INSERT INTO slack(message, author, channel, reactions, reactionsb) VALUES
(
  'Thilo has left the channel', 'slack', 'dataiq',
    '{
      "thilo-come-back": ["rohan", "zij", "clement", "linh", "agnetha"],
      "sad-parrot": ["zack", "willy", "rohan", "edmond" ]
    }'::json,
    '{
      "thilo-come-back": ["rohan", "zij", "clement", "linh", "agnetha"],
      "sad-parrot": ["zack", "willy", "rohan", "edmond" ]
    }'::jsonb
--          ^
);
SELECT * FROM slack WHERE author = 'slack';

-- Should fail as it's not valid json
INSERT INTO slack(message, author, channel, reactions, reactionsb) VALUES
(
  'Alvaro, du bist keine Banane.', 'thilo', 'dev',
    '{
      "dancing-banana": ["paul", "jon"],
    }'::json,  --                      ^ whoops! Trailing comma
    '{
      "dancing-banana": ["paul", "jon"],
    }'::jsonb
);

-- Json schema here doesn't match our other messages,
-- but we haven't declared any kind of schema so it would let this in
INSERT INTO slack(message, author, channel, reactions, reactionsb) VALUES
(
  'Where can I buy vegemite?', 'vinoth', 'general',
    '{
      "aussie-parrot": "rohan"
    }'::json,  --      ^ whoops! Should be an array, not a string
    '{
      "aussie-parrot": "rohan"
    }'::jsonb
);
INSERT INTO slack(message, author, channel, reactions, reactionsb) VALUES
(
  'Voulez-Vous', 'vinoth', 'dev-ops',
    '{
      "aha!": ["camilo", 10]
    }'::json,  --        ^ whoops! Number in the array!
    '{
      "aha!": ["camilo", 10]
    }'::jsonb
);
SELECT author, message, reactionsb FROM slack WHERE message = 'Voulez-Vous';

-- The projection operator
SELECT message, reactions->'thilo-come-back' AS thilo_come_back, reactions FROM slack
