-- Delete data from before
DELETE FROM slack
WHERE message IN (
	'Thilo has left the channel',
	'Where can I buy vegemite?',
	'Voulez-Vous',
	'Zio has a thing for that',
	'can we make the meeting at 10am? I have an appointment with my pillow at 9',
	'paul is the dancing queen'
)

-- Find all the messages where cookies were given at all
-- ie. we check if there's a "cookie" key
SELECT message, author, reactionsb FROM slack WHERE reactionsb ? 'cookie';

-- Find all the messages where Thilo awarded a cookie
-- '@>' is the "contains" operator
-- "LEFT @> RIGHT" means "LEFT contains RIGHT as json"
SELECT message, author, reactionsb FROM slack WHERE reactionsb @> '{ "cookie": [ "thilo" ] }';

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

-- Making the above looser, find all the messages with a cookie reaction from just
-- thilo, pawel, paul or rohan
-- (and it's okay to have other reactions and other reactors)
SELECT message, reactionsb FROM slack
WHERE reactionsb -> 'cookie' <@ '[ "thilo", "pawel", "paul", "rohan" ]'

-- Find all messages where someone reacted with a cookie or party-parrot
-- Introduces the `?|` which is an existence operator that checks if at least one of the elements passed is a key
-- The `|` captures the "or" concept
SELECT message, author, reactionsb FROM slack WHERE reactionsb ?| array[ 'cookie', 'party-parrot' ]

-- Find all messages where there are reactions for _both_
-- blond-sassy-grandma-thilo and pink-sassy-grandma-thilo
-- The `&` captures the "and" concept
SELECT message, author, reactionsb
FROM slack
WHERE reactionsb ?& array[ 'blond-sassy-grandma-thilo', 'pink-sassy-grandma-thilo' ]

-- Find the 2'th person to react with devops-parrot on messages with that reaction
-- (0 indexed)
-- Will be null if there's less than 3 people who reacted with devops-parrot
SELECT message, author, reactionsb, reactionsb -> 'devops-parrot' -> 2 AS reactor_2
FROM slack WHERE reactionsb ? 'devops-parrot';
