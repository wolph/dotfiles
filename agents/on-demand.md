# On-demand guidance

Read the section you need, when you need it. These moved out of global.md so
they do not load into every request.

Tells of a second writer: before any prose pass over a draft. For Claude the
restoring-author-voice skill carries the same catalogue as a table.

Releases: before cutting or verifying a release. For Claude the
release-python-package skill covers the same checklist.

## Tells of a second writer

Drafted prose drifts from an author in patterns, not sentences. Count each pattern with grep in the draft and in the author's own text before rewriting. A device the reference never uses is yours to remove. A device the reference uses at all is the author's and stays until they answer.

- Reveal hinge: a fact withheld and released after ", yet".
- Closing aphorism: a polished fragment ending a section after the point is made, or a full sentence that restates the sentence before it in a figure ("That is not composition doing you a favour."). A fragment stays only when it carries the mechanism. Read each closer against the sentence before it, and count figurative nouns in closers.
- Thesis callback: "from the start of this chapter", "at module scale". A callback to a concrete earlier example stays. A callback to the theme goes.
- Narrator bookkeeping: "I still owe you", "as promised", "that I have kept quiet about".
- Section bridge: a section that ends by announcing the next one.
- Guide vocabulary on the page: habit report, verdict, earns its keep, read back, load-bearing, spine. These words are for the editor, never for the reader.
- Coined metaphor system: label, rung, ladder where the author says "points to". The author's plain phrase wins.
- Reference-manual register: attribute inventories that no transcript on the page shows. Cut to a one-sentence pointer only when the reference never showed it either. When the reference has the transcript, restore the demonstration in the chapter's own example.
- Thesis-first opener: a section that opens on the theme instead of the reader's situation.
- Trailer copy: "the stakes go up", "watch X", "while you watch", "see who wins".
- Self-interview and question lists: a question answered in a fragment, or an opener listing the questions the section will answer. Voicing the reader's question and answering it in full sentences is the author's move and stays. Count question marks in both texts: a draft with none against a reference with several has lost the move, and the reference's question on the same topic comes back.
- Frame phrases and unbounded superlatives: "the honest way to think about", "let me be precise", "three weeks from now", "better than anything else in the language".
- Contraction drought: the reference contracts and the draft does not. Count both. The settled rule: contract the negatives (don't, doesn't, can't), leave "it is", "that is", and "you are" as the reference leaves them. A non-negative contraction approved before this rule reverts on the next pass.
- Commentary about the page itself, including its own test suite, and bug tracker numbers in prose.
- Policy register: consumers, installers, resolvers, operators as subjects, "must" and "should" as verbs, almost no "you". Count agentless nouns, "must", and "you" per hundred lines in both texts. When "you" is under a fifth of the reference, the register is the finding and every paragraph is rewritten from the reader's side with the same facts.
- Antithesis pair: "X rather than Y", "X, not Y". Each becomes one plain statement.
- Coined abstraction family: boundary, claim, evidence, prove, promise standing where the plain noun would. Once one member appears, count the family, headings included, and keep a word only where it names a real thing.
- Transcripts that are not what the tool prints (a bare list where the tool prints a table, a hand-sorted listing, an elided version, a percentage rounded by hand, a transcript inherited from the previous edition that the current code cannot produce) and pins one release series behind the current one. Rebuild the example from the page's own code blocks, diff every transcript with the inherited ones first, re-pin before recording, record at the book's width with COLUMNS=66 instead of narrowing by hand, and change the command rather than the output when the real output does not fit the page.
- A tool used before the section that introduces what it runs under (Hypothesis under pytest before pytest). Move the section.
- Example drift: the same function defined differently across a chapter's blocks where the difference is not the lesson. Diff the bodies.
- A rewritten confession: an "I" sentence with an ancestor in the reference whose reasons were replaced. Put both on the page and let the author choose.
- Topics covered twice, and paragraphs another chapter already carries. One home per topic, and a one-sentence pointer at the chapter that owns the paragraph.
- Definition-first opener: a section whose first sentence defines the heading's term ("A composition root is the one place that..."), the vocabulary-chapter form of the thesis-first opener. The reader's situation goes first and the definition second. Count openers that start with the heading's noun against the number of sections.
- Described output with no transcript: prose that says what a command prints, raises, or returns while no fenced block on the page shows it. Rebuild from the page's own code blocks, record it, and read it back. Count "prints", "raises", "returns", and "fails" in prose against the fenced blocks.
- Cross-references: the full chapter title in italics on the first mention (Chapter 9, *Testing for Confidence*), the bare number afterwards, and at most one pointer per target chapter per section. Check titles against the project's titles table, and grep the target branch for the word it uses for the concept before pointing at it.
- Adverbs the reference never uses: genuinely, quietly, deliberately. Count each in both texts. One inside an "I" sentence is the author's.
- A demonstrative in the first sentence after a box ("is that documented surface"), and a term used before its definition.
- Internet catchphrases that read as plain English: "with extra steps", "a scavenger hunt".
- Time-cost motif: "hours", "3 a.m.", "several hours later" as the price of every mistake. Count in both texts, keep the one the reference has.
- A sentence between a setup colon and its code, usually a version note. It is a box, a deletion, or the setup sentence itself, never a third thing.
- Two rules for one concept in one chapter's code, such as a registry that accepts "upper-case" and a metaclass that demands an identifier. Grep the blocks for the same policy before reading the prose.
- A rewritten read-back is a claim to run. Improving the voice of a wrong sentence keeps it wrong.
- A mechanism retired for a decade is deleted whole, not owned as a reversal. Own a reversal only while the old way is in living memory.
- Output fences in a form the harness does not lex verify nothing. Count fences by form, and give a noexec block a text fence with a sentence saying where the run came from.
- Test-pinned prose: read the chapter's test file before a pass, keep pinned sentences verbatim inside any rewrite, and change a pinned heading with its test in one commit.
- Summary habit fork: quote the body's "I" sentences verbatim. Never paraphrase one into the summary. Joining two of the author's own clauses, even from different sections, is allowed when the page names both source lines and the author approves the join.
- Thesis word: a plain adjective worn into a system by repetition (a section title, the opening, five verdicts, the summary). Count any adjective in a heading that recurs in more than three verdicts, in both texts. Show the author every place with what each option produces. They decide which places keep it.
- Undefined acronym at first use where the reference defined it with a link (LBYL, EAFP). Restore the reference definition instead of writing a box.
- Edition commentary: "the earlier edition", "the original lesson", a box naming editions. A read-back that refers to a lesson the page never sets up is a missing restoration, not a deletion.
- A technical adjective in two senses inside one section ("undecorated" for the decorated fallback and for the handler that register() returns). Check that each repeated technical word means the same thing both times.
- A deprecated construct inside the supported range (typing.TypeAlias in a block that runs green on 3.10 through 3.15). A green test does not catch a deprecation, so check every typing import and standard-library name against the docs' deprecation notes and the owning chapter's advice.
- A preservation ledger line is a claim about the text ("The readability verdict remains under ## Summary"). Verify every [adapted] and [retained] line the way a cross-reference is verified.
- Verification can end in a box: run an undemonstrated claim, and the obvious misuse of the object it describes, on every supported version. A behaviour that changed at a version boundary is a version box, not a cut.
- A section that only defines a term and has no fenced block is a definition box at first use, not a section.
- Back-pointer: two chapters each saying the other owns a topic, so nobody covers it. Grep the target branch for this chapter's number and the previous chapter for promises made to this one before trusting or dropping a pointer.
- Verification that ends in a box: an undemonstrated version claim that, once run on every supported version, differs across them becomes a version caveat with a fallback, not a cut.
- Figures as transcripts: a figure inherited from the previous edition beside retyped code, and a read-back that quotes identifiers the figure no longer shows. Read the identifiers in each image against the block above it and the prose around it, rebuild the page from the chapter's own blocks on the pinned tool, and re-key the pixel manifest.
- Options counted by the prose: "three more options" above a block that adds four. Count the options in the block and in the sentence, and read back the one the sentence skipped.
- Luck in a read-back: "in this run", "this time", "happened to" over deterministic behaviour. Check the behaviour before keeping the hedge.
- The fork stated twice: an imperative use-case fork repeated where the reference had one first-person verdict. Restore the verdict. When a later sentence undercuts the verdict's reason clause, the verdict becomes a use-case fork in the author's voice from the author's own answer, with the mix-and-match case, and a tool named in it is built against the chapter's own package first and dated when its last release is old.
- Reader routing in the body: "skip this ..." outside a box, and a demonstrative with no referent ("this gallery"). Permission to skip is a box placed before the section it skips, naming that section.
- Appendix commentary: "portable", "centre of gravity", "next to this chapter" in a companion file's first sentences or in the pointers at it. A companion file is a named appendix in print that opens on what it is.
- Figure gaps and one-line sections: figure numbers run without gaps within a chapter, appendix included, with files renamed and the manifest re-keyed in one commit, and a section of one sentence and a figure folds into the one before it, with ledger anchors re-pointed and the contract digest recomputed by the test's own algorithm.
- A humour line the author asks for: ground every candidate in the changelog or source of the author's own packages, show them beside the section, and place only what the author picks, verbatim. A candidate that names a bug still live in the author's package gets the bug fixed on a pushed branch in the same session, with a test that pins the observable the sentence claims.
- A flourish approved from a label is not approved: six deadpan lines kept when offered as labels in a question all went plain once the author read one in its paragraph. Show a flourish on the page in its paragraph with the plain version beside it, never as a label in a question.
- An imperative pair that is a recommendation ("Use X for... Use Y once..."): offer the reader's situation and a first-person habit report built from the draft's own facts, and let the author pick. The agent never writes the "I" sentence on its own, but it may offer one.
- Dry-run every numbered page through the chapter's test file before publishing it. Gate self-tests mutate pinned sentences with replace_once, so a rewritten pin fails before the page goes out, and the pin moves with its prose in the same commit.
- A fact the agent adds to carry a sentence ("what asyncio was originally built on") is named as an addition in the item's reason and asked about, never slipped in with the rewrite.
- Shared-build voice: count "we" per thousand prose words separately from "you". The form that is not new content is the setup sentence before a block we define together, in "let's" and "we will". A read-back that narrates the build is new content and the author's call.

## Releases

- A release has five parts: version bump + changelog entry, pushed git tag, package registry publish (PyPI etc.), a GitHub release, and the stable branch (master) fast-forwarded to the tag. Verify all five — compare `git tag --sort=-creatordate` against `gh release list`, and check `git rev-list --count origin/master..vX.Y.Z` prints 0.
  Why: CI publish workflows typically cover only the registry (e.g. Trusted Publishing to PyPI); the GitHub release and the master sync are manual unless explicitly automated, and manual steps get silently skipped (portalocker: 4.1.0 shipped without a GitHub release, 4.2.0 without the master fast-forward).
- Create missing GitHub releases from the already-pushed tag: extract that version's changelog section to a file, then `gh release create vX.Y.Z --title vX.Y.Z --notes-file <file> --verify-tag`. Match the body format of the repo's previous releases.
  Why: `--verify-tag` fails instead of minting a new tag from the wrong ref; sourcing the body from the changelog keeps release notes single-sourced and consistent.
- Sync a stale master with `git push origin vX.Y.Z^{commit}:master`.
  Why: a plain push refuses non-fast-forward updates, so a diverged master fails loudly instead of being overwritten.
- Automating the master sync in CI requires a fine-grained PAT (Contents + Workflows write) or a write deploy key, passed to actions/checkout as `token:`/`ssh-key:`.
  Why: GITHUB_TOKEN is forbidden from pushing commits that touch .github/workflows/, and release diffs regularly include workflow changes.
- Afterwards confirm with `gh release list` that the release exists and is marked Latest.
  Why: verification rule — no completion claims without checked output.
