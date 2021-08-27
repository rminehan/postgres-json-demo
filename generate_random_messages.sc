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
val numRecords = 30 * 1000

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
  "clement", "pinxi", "james", "alexandra"
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

val records = List.fill(numRecords) {
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

// def sanitize(token: String): String = s"\"${token.replace(",", "\\,")}\""

// Wraps quotes around the input
def quote(s: String): String = s""""$s""""

val tsvDataLines: List[List[String]] = records.map {
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
