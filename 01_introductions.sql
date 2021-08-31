CREATE TABLE IF NOT EXISTS slack (
  message text NOT NULL,
  author text NOT NULL,
  channel text NOT NULL,
  reactions json NOT NULL,
  reactionsb jsonb NOT NULL
);

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

SELECT message, reactions->'thilo-come-back' AS thilo_come_back FROM slack
