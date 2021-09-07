---
author: Zihan
date: 2021-09-07
title: Postgres and Json
---

```
 ____           _                      
|  _ \ ___  ___| |_ __ _ _ __ ___  ___ 
| |_) / _ \/ __| __/ _` | '__/ _ \/ __|
|  __/ (_) \__ \ || (_| | | |  __/\__ \
|_|   \___/|___/\__\__, |_|  \___||___/
                   |___/               
                 _ 
  __ _ _ __   __| |
 / _` | '_ \ / _` |
| (_| | | | | (_| |
 \__,_|_| |_|\__,_|
                   
     _                 
    | |___  ___  _ __  
 _  | / __|/ _ \| '_ \ 
| |_| \__ \ (_) | | | |
 \___/|___/\___/|_| |_|
                       
```

---

# Sponsor

Today's talk is sponsored by Abba

They convinced me to take a chance on them

Will be some subliminal Abba references scattered throughout

Points if you spot them

---

# What's today about?

Postgres has had basic json support for a while now

```
 ------------------------------------------------
| name  | hobbies                                |
 ------------------------------------------------
| paul  | ["zio", "dancing"]"                    |
| thilo | ["standup comedy", "correcting typos"] |
| rohan | ["parrots"]                            |
 ------------------------------------------------
```

Not everyone knows about it

---

# Why get excited?

One reason:

> You can get more work done without joins

Want to know more?

> I do, I do, I do, I do, I do

---

# Traditionally

1 person has many hobbies

Use two tables

```
people  -----------
       | id | name |
        -----------
       | 0  | paul |
       | 1  | thilo|
       | 2  | rohan|
        -----------

hobbies  ------------------------------
        | person_id | hobby            |
         ------------------------------
        | 0         | zio              |
        | 0         | dancing          |
        | 1         | standup comedy   |
        | 1         | correcting typos |
        | 2         | parrots          |
         ------------------------------
```

---

# Traditionally

A bit icky

- more tables to know about


- more keys stuffs


- joins

```sql
SELECT *
FROM leads AS l INNER JOIN signals AS s ON l.id = s.lead_id
FROM company_locations AS c ON l.company_id = c.id
WHERE ...
```

---

# Quick poll

What familiarity do you already have with this?

- no familiarity


- a bit


- fairly comfortable

---

# Get excited!

Aim for today is to get you excited about json and postgres

We can stretch postgres a bit further

---

# Aims

- create a general awareness of the `json` and `jsonb` types


- not trying to cover every last detail

---

# How

Zij-Rohan tag teaming

Zij: demo these features

Rohan: chin wagging

---

# Agenda

- play around inserting a few documents


- load in a lot of data


- comparing query speed: json vs jsonb


- indexing json data

---

# Clarify

Following the official postgres docs
[here](https://www.postgresql.org/docs/13/datatype-json.html)
and
[here](https://www.postgresql.org/docs/13/functions-json.html)

They are quite detailed

Today is just the gist

---

# Baton handover

To Professor Zij!

---

# Following along

Slides and scripts are on [github](https://github.com/rminehan/postgres-json-demo)

You can spin up your own db in docker

You can follow along on the beast

---

# Our example

The `slack` table

Each record is a message from slack

---

# Reactions

Messages can have reactions

```
#dataiq
  Zack: Releasing DataIQ!
    ship-it-parrot: [ "linh", "rohan", "zij", "willy", "vinoth" ]
    fear-production: [ "rohan" ]
```

---

# If it were scala code 

```
#dataiq
  Zack: Releasing DataIQ!
    ship-it-parrot: [ "linh", "rohan", "zij", "willy", "vinoth" ]
    fear-production: [ "rohan" ]
```

```scala
type Person = String
type Reaction = String

case class Message(
  text: String,
  author: Person,
  channel: String,
  reactions: Map[Reaction, List[Person]]
)

val message = Message("Releasing DataIQ!", "zack", "dataiq", Map(
  "ship-it-parrot" -> List("linh", "rohan", "zij", "willy", "vinoth"),
  "fear-production" -> List("rohan")
))
```

(Using `List` not set to preserve order of reactions)

---

# Sql

Translating to sql

```
 ----------------------------------------------------------------------------------------------
| message           | author | channel | reactions                                             |
 ----------------------------------------------------------------------------------------------
| Releasing DataIQ! | zack   | dataiq  | { "ship-it-parrot": [...], "fear-production": [...] } |
| Move to LO        | thilo  | dev-ops | { "stack-overflow": [...], "cop-parrot": [...] }      |
 ----------------------------------------------------------------------------------------------
```

---

# Types?

```
 ----------------------------------------------------------------------------------------------
| message           | author | channel | reactions   (type?)                                   |
 ----------------------------------------------------------------------------------------------
| Releasing DataIQ! | zack   | dataiq  | { "ship-it-parrot": [...], "fear-production": [...] } |
| Move to LO        | thilo  | dev-ops | { "stack-overflow": [...], "cop-parrot": [...] }      |
 ----------------------------------------------------------------------------------------------
```

What sql type do you give to the reactions column?

---

# Types

```
 ----------------------------------------------------------------------------------------------
| message           | author | channel | reactions   (type?)                                   |
 ----------------------------------------------------------------------------------------------
| Releasing DataIQ! | zack   | dataiq  | { "ship-it-parrot": [...], "fear-production": [...] } |
| Move to LO        | thilo  | dev-ops | { "stack-overflow": [...], "cop-parrot": [...] }      |
 ----------------------------------------------------------------------------------------------
```

> What sql type do you give to the reactions column?

`json` or `jsonb`

---

# jsonb

We all know `json`, who is `jsonb`?

---

# jsonb

> who is jsonb?

`json`'s cool older brother

Owns a car

Has a girlfriend

Smokes casually

---

# jsonb

"Binary json"

---

# Quick overview of differences

```
 -------------------------------------------------
|                     | json   | jsonb            |
 -------------------------------------------------
| storage             | text   | optimized parsed |
|                     |        | binary format    |
 -------------------------------------------------
| duplicate keys      | yes    | no               |
 -------------------------------------------------
| ordering preserved  | yes    | no               |
 -------------------------------------------------
| supported operators | weaker | richer           |
 -------------------------------------------------
| time to query       | slower | faster           |
 -------------------------------------------------
```

Will become clearer during the demo

_Generally_ speaking, `jsonb` will make more sense


---

# Side by side

To make it easier to compare, we'll see use both in our table

```
 ---------------------------------------------------------------
| message | ... | reactions: json       | reactionsb: jsonb     |
 ---------------------------------------------------------------
| ...     | ... | {cookie:["zij"]}      | {cookie:["zij"]}      |
| ...     |     | {no-cookie:["thilo"]} | {no-cookie:["thilo"]} |
 ---------------------------------------------------------------
```

---

# If you want to follow along

There is a db setup on the beast

Start redshift prod vpn

Tunnel your local port 6677 to 6677 on the beast:

```bash
ssh -L 6677:localhost:6677 beast
#                          ^^^^^ your ssh alias for the beast
```

---

# If you want to replicate this locally

See the README.md on the repo

Not too hard

---

# Connecting a sql client

Host: localhost

Port: 6677

Username: `postgres`

DB Password: `boban_jones`

No fancy stuff

---

# Sqlectron users beware!

It aggressively shrinks and trims whitespace

Do `SELECT 'abc          def'` to see what I mean

Can cause confusion with some demos

---

# To save time...

Table is already generated and has ~100K rows

```sql
CREATE TABLE IF NOT EXISTS slack (
  message text NOT NULL,
  author text NOT NULL,
  channel text NOT NULL,
  reactions json NOT NULL,
  --        ^^^^
  reactionsb jsonb NOT NULL
  --         ^^^^^
);
```

---

# Section 1

To the client!

We'll leave the slides and follow the snippets for a while

---

# Summarizing section 1

`:batton-pass:` to Rohan

---

# Two json types

- `json`


- `jsonb`

---

# What we've seen

Validates json before accepting it

No schema enforcement by default

(There is a [postgres extension](https://github.com/furstenheim/is_jsonb_valid)
you can use to add validation)

---

# Section 2

Deeper comparison of `json` and `jsonb`

Snippets in `02_json_vs_jsonb.sql`

`:pass-baton:`

To the client!

---

# Summarizing section 2

`:baton-throw:`

`json` vs `jsonb`

---

# `json`

Just wrapper type for text

Just gives you json validation and some operators

---

# jsonb type

"True" json format

---

# jsonb type

> "True" json format

Impacts:

- original whitespace is lost


- order of keys may change (not in arrays though)


- duplicate keys get dropped (last is kept)


- probably uses less space


- has more operators (will see later)

---

# Remember our table

```
 -------------------------------------------------
|                     | json   | jsonb            |
 -------------------------------------------------
| storage             | text   | optimized parsed |
|                     |        | binary format    |
 -------------------------------------------------
| duplicate keys      | yes    | no               |
 -------------------------------------------------
| ordering preserved  | yes    | no               |
 -------------------------------------------------
| supported operators | weaker | richer           |
 -------------------------------------------------
| time to query       | slower | faster           |
 -------------------------------------------------
```

---

# Aside: Size limits

```
 -------------------------------------------------
|                     | json   | jsonb            |
 -------------------------------------------------
| storage             | text   | optimized parsed |
|                     |        | binary format    |
 -------------------------------------------------
```

You might be asking:

> What are the size limits of these data types?

---

# Aside: Size limits

```
 -------------------------------------------------
|                     | json   | jsonb            |
 -------------------------------------------------
| storage             | text   | optimized parsed |
|                     |        | binary format    |
 -------------------------------------------------
```

> What are the size limits of these data types?

Not documented, but from SO:

- json is backed by text, so ~1GB


- jsonb ~255MB

---

# Shouldn't hit the limit

> Not documented

Potentially because you shouldn't be inserting such big docs

Maybe doing something wrong

> If you're exceeding, darling then you're n00bing, S.O.S!

---

# Case Study: Old Man Zij rambling

After a tour of duty in csqw,

Zij has earnt the right to bore us with war stories

---

# Zij's war story

Document with 120k lines is only ~9MB

- json is backed by text, so ~1GB


- jsonb ~255MB

---

# Section 3

`:baton-toss:`

`03_advanced_operators.sql`

Look into more funky json operators (many just for `jsonb`)

To the snippets!

---

# Summary of section 3

`:baton-hurl:`

---

# Existence operator

For when you just want to know if it has a key,

but don't care about the value

> Find the messages where someone reacted with :hurts-real-bad:

---

# Existence operator

> Find the messages where someone reacted with :hurts-real-bad:

```sql
SELECT message, author, reactionsb FROM slack
WHERE reactionsb ? 'hurts-real-bad'
```

---

# Alternative for json

Only `jsonb` has the existence operator

Can use `->` and `IS NOT NULL` for `json`:

```sql
-- jsonb
SELECT message, author, reactionsb FROM slack
WHERE reactionsb ? 'hurts-real-bad'

-- json
SELECT message, author, reactions FROM slack
WHERE reactions -> 'hurts-real-bad' IS NOT NULL
```

---

# Supported for arrays too

Example:

```sql
SELECT * FROM slack
WHERE reactionsb -> 'fear-production' ? 'thilo'
```

---

# Contains

`LEFT @> RIGHT` contains operator

Does the left json thingy "contain" the right json thingy

("contain" isn't quite right, but close enough)

Good for "at least/minimal" logic

---

# Contains

```sql
SELECT * FROM slack
WHERE reactionsb @> '{ "cookie": [ "jon", "zij" ], "party-parrot": [ "aelfric" ] }'
```

This will match:

```json
{
  "cookie": [ "paul", "pratheema", "pinxi", "linh", "zij", "james", "jon" ],
  "cookie-eaten": [ "alan", "pawel", "pratheema", "zij" ],
  "party-parrot": [ "adrian", "lorraine", "alexandra", "aelfric", "kyle" ],
  "hurts-real-bad": [ "alvaro", "sampson", "vish", "pratheema" ]
}
```

---

# Contains the other way

`LEFT <@ RIGHT` contains operator

Does the right json thingy "contain" the left json thingy

Good for "at most/maximal" logic

---

# Contains the other way

```sql
SELECT reactionsb FROM slack
WHERE reactionsb -> 'cookie' <@ '[ "thilo", "pawel", "paul", "rohan" ]'
```

Will match:

```json
{
  "cookie": [ "rohan", "pawel" ],
  "cotacie": [ "thilo" ],
  "thilo-shrugging": [ "willy", "zack", "edmond", "jon" ]
}
```

Won't match:

```json
{
  "cookie": [ "rohan", "jon" ]
}
```

---


# Mama-Mia! `@` Which-a-way?


If you have:
```json
{
  "cookie": [ "rohan", "pawel" ],
  "thilo-shrugging": [ "willy", "thilo", "edmond", "jon" ]
},
{
  "cookie": [ "rohan", "pawel" ],
  "thilo-shrugging": [ "willy", "thilo" ]
}
```

```sql
SELECT reactionsb FROM slack
WHERE reactionsb -> 'thilo-shrugging' @> '[ "willy", "thilo" ]'
```

will match both whereas

```sql
SELECT reactionsb FROm slack
WHERE reactionsb -> 'thilo-shrugging' <@ '[ "willy", "thilo" ]'
```

will match only the second


---

# And many more

We saw `?|` and `?&` but there's many more!

Check the [docs](https://www.postgresql.org/docs/13/functions-json.html) for a full list

---

# Section 4

`:baton-teleport:`

Query performance of `json` vs `jsonb`

---

# From the [docs](https://www.postgresql.org/docs/13/datatype-json.html)

- jsonb is parsed once on loading


- json is parsed on every query

---

# Our example

Find the first person to react with `:thilo-come-back:` on messages with that reaction

---

# To sql

> Find the first person to react with :thilo-come-back: on messages with that reaction

Using `json` column:

```sql
SELECT author, reactions -> 'thilo-come-back' -> 0 AS eager_thilo_fan, reactions
FROM slack
WHERE reactions -> 'thilo-come-back' IS NOT NULL;
```

Using `jsonb` column:

```sql
SELECT author, reactionsb -> 'thilo-come-back' -> 0 AS eager_thilo_fan, reactionsb
FROM slack
WHERE reactionsb ? 'thilo-come-back';
--               ^ Able to use simpler syntax
```

---

# Let's run them!

See how fast they are

To the client!

---

# Section 4 summary

`:baton-flick:`

Not much to say here

`jsonb` is faster for searching

`json` is faster for loading but that's just done once

---

# Section 5

`:baton-flick-back:`

Indexes on jsonb columns

`05_indexing.sql`

---

# Indexing jsonb?

Question like:

> Find all the messages where someone reacted with :cotacie:

We'll index the top level keys

---

# Adding an index

We'll add an index and observe the speedup

To the client!

---

# Summarizing section 5

`:baton-pass:`

You can do a lot with indexes

We just covered a basic example

Docs are very detailed

---

# Have you been listening?

Get the audience to come up with some queries

The winner takes it all

---

# Example 1

Sql query to answer this:

> Find all slack messages where:
>
> both thilo and paul reacted with a cookie (minimum)
>
> and
>
> fear-production can only be reacted by zij, adrian, ritchie or willy (maximum)
>
> and
>
> someone reacted with zio (probably paul)
>
> (other reactions are allowed)

---

# Example 1 solution

```sql
SELECT author, message, reactionsb
FROM slack
WHERE
  -- both thilo and paul reacted with a cookie (minimum)
  reactionsb -> 'cookie' @> '[ "thilo", "paul" ]' AND
  -- fear-production can only be reacted by zij, adrian, ritchie or willy (maximum)
  reactionsb -> 'fear-production' <@ '[ "zij", "adrian", "ritchie", "willy" ]' AND
  -- someone reacted with zio
  reactionsb ? 'zio'
```

---

# Example 2 question

Sql query to answer this:

> Find all the records where
>
> there were reactions for all of these emojis:
>
> cookie-ask, cookie-tell, no-cookie
>
> AND
>
> reactions for at least one of these emojies:
>
> running-thilo, party-enxhell, phone, cop-parrot

---

# Example 2 solution

```sql
SELECT author, message, reactionsb
FROM slack
WHERE reactionsb ?& array[ 'cookie-ask', 'cookie-tell', 'no-cookie' ]
AND reactionsb ?| array[ 'running-thilo', 'party-enxhell', 'phone' ]
```

---

# Wrapping up

Today's goal:

> Get you excited about postgres and json

---

# Wrapping up

ie. want you to know it exists and get the gist without too much detail

---

# Postgres vs Mongo

> (Postgres) If you change your mind, I'm the first in line
>
> (Mongo) I tried to hold you back but you were stronger
>
> (Postgres) Don't, go, cha-sing af-ter mon-go, lay, all your search, on, me
>
> (Mongo) Knowing me, knowing you, there is nothing you can't do

---

# json vs jsonb

`jsonb` will generally make more sense

Faster

Richer operators

---

# Side note

Seems to be a postgres-only feature

Locks you in

---

# For the analytics team

Could improve our postgres db

But can't replicate on redshift

---

# Further Reading

Postgres docs are quite good

- [intro to json and jsonb types](https://www.postgresql.org/docs/13/datatype-json.html)


- [json functions](https://www.postgresql.org/docs/13/functions-json.html)

There is also xpath support

---

# Abba Gurus?

Any standout super trouper abba fans?

---

```
  ___                  _   _                ___ 
 / _ \ _   _  ___  ___| |_(_) ___  _ __  __|__ \
| | | | | | |/ _ \/ __| __| |/ _ \| '_ \/ __|/ /
| |_| | |_| |  __/\__ \ |_| | (_) | | | \__ \_| 
 \__\_\\__,_|\___||___/\__|_|\___/|_| |_|___(_) 
                                                
  ____                                     _      ___ 
 / ___|___  _ __ ___  _ __ ___   ___ _ __ | |_ __|__ \
| |   / _ \| '_ ` _ \| '_ ` _ \ / _ \ '_ \| __/ __|/ /
| |__| (_) | | | | | | | | | | |  __/ | | | |_\__ \_| 
 \____\___/|_| |_| |_|_| |_| |_|\___|_| |_|\__|___(_) 
                                                      
```

(Hard questions go to Zij)
