-- Note all the extra whitespace
INSERT INTO slack(message, author, channel, reactions, reactionsb) VALUES
(
  'Zio has a thing for that', 'paul', 'dev-back-end',
    '{ "zio": [   "alvaro", "jon"  , "james"  , "lulu"  ], "zio": [    "paul",  "thilo"] }'::json,
    '{ "zio": [   "alvaro", "jon"  , "james"  , "lulu"  ], "zio": [    "paul",  "thilo"] }'::jsonb
);
-- In a good client like pgAdmin you'll be able to see the difference between the two
-- sqlectron hides the difference
SELECT reactions, reactionsb FROM slack WHERE message = 'Zio has a thing for that';


-- jsonb may change the order of keys in json objects based on its internal storage rules
-- It won't change the order in arrays though
INSERT INTO slack(message, author, channel, reactions, reactionsb) VALUES
(
  'can we make the meeting at 10am? I have an appointment with my pillow at 9', 'jon', 'scala-training',
    '{"zzz":["clement","lulu"], "bed":["thilo"], "sleepy":["zij","pawel"] }'::json,
    '{"zzz":["clement","lulu"], "bed":["thilo"], "sleepy":["zij","pawel"] }'::jsonb
);
INSERT INTO slack(message, author, channel, reactions, reactionsb) VALUES
(
  'paul is the dancing queen', 'jon', 'random',
    '{"dancing-panda":["rohan","clement"], "pikachu-dancing":["james"]}'::json,
    '{"dancing-panda":["rohan","clement"], "pikachu-dancing":["james"]}'::jsonb
);
SELECT reactions, reactionsb FROM slack WHERE message IN ('can we make the meeting at 10am? I have an appointment with my pillow at 9', 'paul is the dancing queen';
