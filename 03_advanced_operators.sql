-- Remove the little examples from previous sections
DELETE FROM slack;

-- Use this to load some random data in
-- There is an ammonite script that generates this
-- You'll need to copy the data into the postgres container
-- (see instructions in ammonite script)
COPY slack(message, author, channel, reactions, reactionsb)
FROM 'random_slack_data.tsv'
DELIMITER E'\t'
CSV HEADER;

-- Find all the messages where Thilo awarded a cookie
-- '@>' is the "contains" operator
-- "LEFT @> RIGHT" means "LEFT contains RIGHT as json"
SELECT message, author, reactionsb FROM slack WHERE reactionsb @> '{ "cookie": [ "thilo" ] }';

-- Find all the messages where cookies were given at all
-- ie. we check if there's a "cookie" key
SELECT message, author, reactionsb FROM slack WHERE reactionsb ? 'cookie';

-- Find the 2'th person to give a cookie on each message with a cookie
-- (0 indexed)
-- Will be null if there's less than 3 people who reacted with cookie
SELECT message, author, reactionsb, reactionsb -> 'cookie' -> 2 AS sheep FROM slack WHERE reactionsb ? 'cookie';

-- Find all the messages with only a cookie reaction and those reactions
-- are a subset of thilo, pawel, paul or rohan
-- Note the order of the "contains" operator is reversed from above
-- Now it means "RIGHT contains LEFT"
SELECT message, author, reactionsb FROM slack
WHERE reactionsb <@ '{ "cookie": [ "thilo", "pawel", "paul", "rohan" ] }';

-- Whoops! The above was also matching empty reaction sets which are technically contained in that json object
-- Add in an extra condition that the key must be defined
SELECT message, author, reactionsb FROM slack
WHERE reactionsb ? 'cookie' AND reactionsb <@ '{ "cookie": [ "thilo", "pawel", "paul", "rohan" ] }';

-- Making the above looser, find all the messages with a cookie reaction from at least one of
-- thilo, pawel, paul or rohan
-- (and it's okay to have other reactions and other reactors)
SELECT reactionsb FROM slack
WHERE reactionsb -> 'cookie' <@ '[ "thilo", "pawel", "paul", "rohan" ]'

-- Find all messages where someone reacted with a cookie or party-parrot
-- Introduces the `?|` which is an existence operator that checks if at least one of the elements passed is a key
-- The `|` captures the "or" concept
SELECT message, author, reactionsb FROM slack WHERE reactionsb ?| array[ 'cookie', 'party-parrot' ]

-- Find all messages where there are reactions for _both_
-- blond-sassy-grandma-thilo and pink-sassy-grandma-thilo
-- The `&` captures the "or" concept
SELECT message, author, reactionsb
FROM slack
WHERE reactionsb ?& array[ 'blond-sassy-grandma-thilo', 'pink-sassy-grandma-thilo' ]
