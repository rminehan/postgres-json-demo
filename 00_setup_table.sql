CREATE TABLE IF NOT EXISTS slack (
  message text NOT NULL,
  author text NOT NULL,
  channel text NOT NULL,
  reactions json NOT NULL,
  reactionsb jsonb NOT NULL
);

-- Use this to load some random data in
-- There is an ammonite script that generates this
-- You'll need to copy the data into the postgres container
-- (see instructions in ammonite script)
COPY slack(message, author, channel, reactions, reactionsb)
FROM 'random_slack_data.tsv'
DELIMITER E'\t'
CSV HEADER;
