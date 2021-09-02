# postgres-json-demo!

It's bring your son to work day, so Zij and I did a collaborative presentation to the leadiq team on json support in postgres.

Overall the presentation is just trying to get across the general idea of the `json` and `jsonb` columns to create general awareness.
It doesn't try to cover things in detail.

More details can be found in the official postgres docs
[here](https://www.postgresql.org/docs/13/datatype-json.html)
and
[here](https://www.postgresql.org/docs/13/functions-json.html).

# Snippet based

The talk is based around a collection of snippet files that copy-pasted into a sql client.

The `00` files are for setting up the db (below) and were done before the talk to save time.

# Replicating the db locally

The script `00_setup_table.sql` can be used to start a postgres container on port 6677.

To put meaningful data into the table, run the ammonite script and copy the tsv file it creates into the docker container:

```bash
amm generate_random_messages.sc

sudo cp random_slack_data.tsv postgres-docker-volume/
```

Then create the table and load the tsv file using the commands from `00_setup_table.sql`.
