/* Generates a .tsv file of records intended to be imported into slack table
 * Run with ammonite, e.g. amm generate_random_messages.sc
 *
 * Our database is running inside docker so you'll need to copy the
 * tsv file into the docker volume (should be in this dir)
 * sudo cp random_slack_data.tsv postgres-docker-volume
 *
 * Then run the COPY command from 03_advanced_operators.sql to load it
 */

// Generate enough records to make the table big enough to make it easy to
// spot performance differences between different approaches
val numRecords = 100 * 1000

val rng = new scala.util.Random(115953)

// Used to generate random sentences of the form:
// [ARTICLE] [NOUN] [VERB] [ARTICLE] [NOUN]
// e.g. "The customer ate the database"

def article(noun: String): String = {
  val definiteArticle = rng.nextBoolean
  if (definiteArticle) "the"
  else {
    if ("aeiou".contains(noun.toLowerCase.head)) "an"
    else "a"
  }
}
val nouns = Vector("customer", "prospect", "engineer", "PM", "lead", "dataiq", "database", "MR")
val verbs = Vector("crashed", "ate", "failed", "restarted", "reviewed", "logged")

val teamMembers = Vector(
  "thilo", "paul", "vish", "vinoth", "zij", "alan", "pawel", "jon", "adrian",
  "mei", "edmond", "sampson", "linh", "rohan", "zack", "willy", "valentine",
  "alvaro", "pratheema", "ritchie", "andrea", "kyle", "lorraine", "aelfric",
  "clement", "pinxi", "james", "alexandra",
  "benny", "agnetha", "anni-frid", "björn"
)

val channels = Vector(
  "dev", "team-singapore", "dev-backend", "dataiq",
  "general", "random", "scala-training", "triforce-tng"
)

val emojis = Vector(
  "party-parrot", "sad-parrot", "zio", "blond-sassy-grandma-thilo", "pink-sassy-grandma-thilo",
  "wfh-parrot", "+1", "heavy-check-mark", "ship-it-parrot", "jump",
  "fear-production", "thilo-shrugging", "thilo-come-back", "hurts-real-bad",
  "cookie", "tacookie", "cotacie", "cookie-eaten"
)

def rand(inputs: Vector[String]): String = inputs(rng.nextInt(inputs.size))

// TODO - reactions should have a non-empty list of reactors as you can't have an emoji on a slack
// message if no reacted to it
type Emoji = String
type Reactor = String
case class Record(message: String, author: String, channel: String, reactions: Map[Emoji, List[Reactor]])

val randomRecords = List.fill(numRecords) {
  val message = {
    val messageSubject = rand(nouns)
    val messageSubjectArticle = article(messageSubject).capitalize
    val messageVerb = rand(verbs)
    val messageObject = rand(nouns)
    val messageObjectArticle = article(messageObject)
    s"$messageSubjectArticle $messageSubject $messageVerb $messageObjectArticle $messageObject"
  }
  val author = rand(teamMembers)
  val channel = rand(channels)
  val reactions = {
    val numEmojies = rng.nextInt(5)
    val emojiKeys = rng.shuffle(emojis).take(numEmojies)
    emojiKeys.map { key =>
      val numReactionsToEmoji = rng.nextInt(10) + 1 // +1 as there needs to be at least one reactor
      val reactors = rng.shuffle(teamMembers).take(numReactionsToEmoji).toList
      (key, reactors)
    }.toMap
  }
  Record(message, author, channel, reactions)
}

// To make the demo a bit more predictable,
// there's some hand generated data.
// Also makes it easier to sneak some abba-isms in there...
val fixedRecords = List(
  Record("Thankyou for the json, the blobs we're searching", "benny", "random", Map(
    "zio" -> List("zack", "pinxi", "linh", "anni-frid", "paul"),
    "cookie" -> List("ritchie", "björn", "thilo", "paul", "aelfric", "andrea"),
    "fear-production" -> List("willy", "adrian", "zij")
  )),
  Record("DataIQ, couldn't escape if I wanted to", "zij", "dataiq", Map(
    "cookie" -> List("thilo", "rohan"),
    "hugging-face" -> List("rohan"),
    "let-me-out" -> List("jon", "ritchie", "lulu")
  )),
  Record("Mamma Mei-a, here we go again", "pratheema", "random", Map(
    "cookie" -> List("rohan", "thilo", "pawel", "paul"),
    "zio" -> List("paul", "jon"),
    "mei-approves" -> List("mei")
  )),
  Record("Gimme gimme gimme devops after midnight", "horea", "dev-ops", Map(
    "devops-parrot" -> List("adil", "anni-frid", "zack", "zij")
  )),
  Record("Linh! Linh! Why don't you give me a code review?", "willy", "dataiq", Map(
    "cookie-ask" -> List("linh"),
    "cookie-tell" -> List("linh"),
    "no-cookie" -> List("willy"),
    "phone" -> List("rohan", "zij")
  )),
  Record("Look into his Enxhell eyes, one look and you're hypnotised", "james", "dev", Map(
    "cookie-ask" -> List("james"),
    "cookie-tell" -> List("james"),
    "no-cookie" -> List("enxhell"),
    "party-enxhell" -> List("clement", "rohan", "zij")
  )),
  Record("My my! At code review, Andrea did surrender", "thilo", "dev-front-end", Map(
    "cookie-ask" -> List("thilo", "paul"),
    "cookie-tell" -> List("thilo", "edmond"),
    "no-cookie" -> List("andrea", "edy"),
    "cop-parrot" -> List("linh", "pawel", "james", "enxhell")
  ))
)

// Wraps quotes around the input
def quote(s: String): String = s""""$s""""

val tsvDataLines: List[List[String]] = (randomRecords ++ fixedRecords).map {
  case Record(message, author, channel, reactions) =>
    val reactionsJson = reactions.map {
      case (emoji, reactors) =>
        val emojiKey = quote(emoji)
        val reactorsJsonArray = reactors.map(quote).mkString("[", ", ", "]")
        s"$emojiKey: $reactorsJsonArray"
    }.mkString("{", ", ", "}")
    List(message, author, channel, reactionsJson, reactionsJson)
}

val tsvHeader = List("message", "author", "channel", "reactions", "reactionsb")

import $ivy.`com.github.tototoshi::scala-csv:1.3.6`
import com.github.tototoshi.csv.{CSVWriter, DefaultCSVFormat}

val file = new java.io.File("random_slack_data.tsv")

val tabDelimitFormat = new DefaultCSVFormat {
  override val delimiter = '\t'
}

val writer = CSVWriter.open(file)(tabDelimitFormat)

writer.writeAll(tsvHeader :: tsvDataLines)

writer.close()

println("All done")
