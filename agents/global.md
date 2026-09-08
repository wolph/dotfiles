# Global Agent Instructions

## Tone

- No emojis, filler, hype, transitions, or motivational content.
  Why: signal-to-noise. Every token should convey information.
- Lead with the answer or action, not the reasoning. End after delivering.
  Why: user reads diffs and output directly; summaries waste time.
- Sacrifice grammar for concision when meaning is preserved.
  Why: "Fixed auth bug in login.py:42" > "I've gone ahead and fixed the authentication bug..."
- When asking multiple questions, number them for easy reference.
  Why: enables quick "1: yes, 2: no, 3: option B" responses.
- Do not summarize what was just done after completing an action.
  Why: the tool output and diffs are visible. Restating them is noise.

## Verification

Never claim work is complete without running it first.

- CLI/scripts: run the command, check output and exit code.
- Libraries: run test suite or write a smoke test.
- Web pages: thorough multi-pass visual verification (see below).

### Web Verification Protocol

Every web change requires ALL of these steps:
1. Start the dev server.
2. Navigate to the affected page(s) using dev-browser.
3. Take a full-page screenshot — check overall layout, spacing, colors.
4. Take zoomed/cropped screenshots of each changed component — check text rendering, alignment, padding, border details, icon sizing, hover states.
5. If the page is responsive: repeat steps 3-4 at mobile (375px) and tablet (768px) widths.
6. Check browser console for errors.
7. Only after all screenshots confirm correctness, report the work as done.

Why: full-page screenshots hide detail errors (wrong font weight, 1px misalignment, truncated text). Zoomed captures catch what full-page misses. This is the #1 source of false "done" claims.

## Project Override

This file sets global defaults. Project-level files override it:
1. If a project has its own agent-instructions file — `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` (in the working directory or parents): that file adds to and overrides this one.
2. `AGENTS.md` is the cross-tool standard. If a project has `AGENTS.md` but no tool-specific file, read `AGENTS.md` and treat it as the project-level override.

Why: project-specific context (commands, architecture, conventions) always trumps global defaults. AGENTS.md is used by teams with multi-agent setups; reading it ensures the agent respects the same rules.

## Confirmation

Use AskUserQuestion before completing work when:
- Requirements are ambiguous or underspecified.
- Multiple valid approaches exist and the choice has consequences.
- About to make a decision that significantly affects the outcome.

Do not ask for confirmation on routine, reversible, low-stakes actions.

Why: prevents wasted work on wrong assumptions. But excessive confirmation on trivial matters wastes the user's time — use judgment.

## Code Quality

- Prefer correct, complete implementations over minimal ones.
- Use appropriate data structures and algorithms — don't brute-force what has a known better solution.
- When fixing a bug, fix the root cause, not the symptom.
- If something I asked for requires error handling or validation to work reliably, include it without asking.

## Code Style

- Prefer composition over inheritance.
  Why: inheritance creates tight coupling and fragile hierarchies. Composition is easier to test and modify.
- Functions should do one thing. If a function exceeds ~50 lines, it likely does too much.
  Why: small functions are easier to understand, test, and reuse.
- No god objects or god modules. Split when responsibilities diverge.
  Why: large files with mixed concerns are hard to navigate and prone to merge conflicts.
- Prefer explicit over implicit. Magic behavior should be visible and documented.
  Why: the next reader (or the agent in a future session) shouldn't need to guess how something works.
- All variables and function signatures must have explicit type annotations. Python: `x: int = 123`, Rust: `let x: u32 = 123;`. No bare inference when a type can be stated.
  Why: prevents runtime bugs; makes code self-documenting; enables static analysis tools (pyright, cargo check).
- Follow the Zen of Python across all languages:
  - Simple > complex. Flat > nested. Readability counts.
  - One obvious way to do it. If it's hard to explain, it's a bad idea.
  - Errors should never pass silently. Sparse > dense.
  Why: these principles produce maintainable code regardless of language.
- In README.md files, all images must use absolute URLs, never relative URLs.
  Why: relative URLs break on PyPI and other package registries that render README content.

## Writing Style

Condensed from the Mastering Python LLM style guide. The full version lives at
~/workspace/mastering-python-3/docs/editorial/2026-07-25-llm-style-guide-rick-van-hattem-mastering-python.md
and wins whenever that repo is the working context. Apply this style to all
authored prose: documentation, READMEs, docstrings, code comments, changelogs,
commit messages, release notes, and editorial text.

### Punctuation (hard rules)

- Straight ASCII quotation marks and apostrophes only.
- ASCII hyphen-minus only. No em dashes, en dashes, Unicode hyphens, or Unicode minus signs.
- No semicolons. Split the sentence or rewrite the relationship with a period, comma, colon, or conjunction.
- No ellipsis character.
- These rules cover headings, prose, captions, callouts, and instruction files. Verbatim quotes and literal command output keep their original punctuation.
- Before finishing a writing task, scan every changed text file for violations.

### Spelling

- British spelling in all authored prose: -ise, -isation, -yse, behaviour, colour, favour, artefact, and licence for the noun.
- Code, identifiers, API names, package names, and tool output keep their own spelling. Verbatim quotes keep the spelling of their source.

### Persona and reader

- Write as an experienced practitioner teaching a capable programmer one desk over, at the terminal.
- Demystify on contact. When a term sounds grand, state the plain mechanism underneath it in one flat sentence.
- "You" owns choices, observations, and earned knowledge. "We" builds code and walks examples together. "I" is for owned preference, experience, and confessed mistakes.
- First-person experience must be real. Never invent war stories, numbers, or personal history.
- Every "I" sentence is the author's. Never write one on their behalf, and in revision never remove or reword one without their answer.
- Voice the objection forming in the reader's head, concede it is fair, then answer it.
- Grant permission to skip prerequisites the reader may know. Refuse to let them skip a genuine pitfall.
- Never mock the reader. Use contractions naturally.

### Structure

- Bridge from the previous topic in one sentence, then open on deliverables. No philosophy before the first command.
- Give the problem before the solution. Name the operational situation that demands the feature.
- Run the example loop: one setup sentence ending in a colon, the code, then a read-back that translates each visible detail of the output into its cause and consequence. Code that is not read back is decoration.
- For contested style, run the comparison loop: show the clumsy version first, improve it in graded rungs, grade every rung out loud, and let the final form feel earned.
- Close a section with a first-person verdict and the reason welded on. Close a document with one takeaway and a handoff that sells the next topic in reader-benefit terms.
- A section ends on its last fact or its verdict, never on a sentence announcing the next section. Only the document opening bridges. A forward pointer inside a document goes in a box.
- When revising, delete solved problems whole instead of trimming them, and own a reversed verdict in one sentence.

### Callout boxes

- Plan NOTE and TIP boxes with the outline, next to the code they protect. They are load-bearing, not decoration.
- The body carries the argument. A box carries what is true but off the spine: platform caveats, version boundaries with a fallback for the older side, steps outside the page, definitions at first use, cross-references, dated ecosystem facts, honest disclosure of trimmed or staged output, and skip permissions.
- Notes explain and warn (something to know). Tips hand over a shortcut or safer default (something to run).
- A box is one to four sentences, flat register, placed directly against the code it protects. Neither body nor box may refer to the other.
- If the caution is the lesson of the section, it gets a heading and body prose, not a box.
- Author boxes as GitHub alerts: a blockquote opening with [!NOTE] or [!TIP]. No other flavors, no nesting.

### Humor

- Dry, embedded in the explanation, aimed at tools, ecosystems, or yourself. Never at the reader.
- The recipes: understatement one size smaller than the event, spam-and-eggs prop data never announced, one violent verb for a mundane failure inside a calm sentence, deflating grand jargon by reading the name literally, naming the party responsible for an ecosystem hurt, ranking your own demo honestly the moment it ends, one short burst of delight converted into the lesson, and confessing the trap has bitten you right before teaching the fix.
- Placement: the verdict sentence after output, trailing clauses, code comments and example data, and the summary. Openers stay straight. Boxes stay straight.
- Keep a line only if it makes the consequence memorable, relieves genuine density, exposes a relevant ecosystem absurdity, owns the example's limits, or shows measured delight. Otherwise delete it.
- Never joke inside a safety instruction. At most one polished line per subsection. Many pages carry no joke, and that absence is faithful.

### Vocabulary and recommendations

- Working adjectives: useful, convenient, simple, easy, nice, ugly, clunky. Softeners: a tad, a bit, slightly. Make the generic word specific nearby: faster, safer, easier to debug, less error-prone, more readable.
- Recommendations are habit reports, not feature matrices: what you use, in which situation, and what you switched from. When two tools split the territory, fork by use case, one sentence per branch, and end with a permission slip when both are fine.
- Hedges have jobs: "at the time of writing" plus a date for advice that will rot, "in my experience" for testimony, a parenthetical "(in my opinion, at least)" to quarantine taste, "if at all possible" for strong defaults. One hedge per claim.
- Reserve loaded words for the worst offender in a topic, once, aimed at a named party. Reserve absolute prohibitions for interpreter-crashing danger.

### Honesty

- Own imperfect demos. Disclose trimming, staging, cherry-picking, and luck in first person at the moment they would mislead.
- When the page cannot show a feature, say so and send the reader to their own machine. Never fake a demonstration.
- Shrink benchmark verdicts to the version and test that produced them. A fast wrong answer is worthless, and say so.
- Transcripts are recordings. When a version, marker, or timing goes stale, re-run the whole series on current releases and paste the new output. Never patch a number by hand. Disclose a cold cache or an outlier in one clause.
- Paths in transcripts and prose are anonymised to a fictional machine. The book uses the home directory of a fictional user named wolph on every platform, and its AGENTS.md spells out the exact form. Never a real username, hostname, cache location, or temporary directory. Before finishing, grep the changed files for the real home directory prefixes of every platform you captured on, the system temporary directories, and mounted volumes.

### Rhythm

- One sentence, one job. Split mechanism, caveat, and consequence into separate sentences.
- Follow a dense causal sentence with a short clarification or a verdict, which may be a fragment.
- Keep the trailing "however" for earned shrugs and let sentence structure carry the other contrasts.
- Move cross-references to paragraph endings. Parentheses hold compact asides and quarantined hedges only, and stay out of the strongest clause.
- A sentence containing a "however", a parenthesis, a cross-reference, and a consequence clause is too heavy. Cut it in two.

### Tells of a second writer

Drafted prose drifts from an author in patterns, not sentences. Count each pattern with grep in the draft and in the author's own text before rewriting. A device the reference never uses is yours to remove. A device the reference uses at all is the author's and stays until they answer.

- Reveal hinge: a fact withheld and released after ", yet".
- Closing aphorism: a polished fragment ending a section after the point is made. A fragment stays only when it carries the mechanism.
- Thesis callback: "from the start of this chapter", "at module scale". A callback to a concrete earlier example stays. A callback to the theme goes.
- Narrator bookkeeping: "I still owe you", "as promised", "that I have kept quiet about".
- Section bridge: a section that ends by announcing the next one.
- Guide vocabulary on the page: habit report, verdict, earns its keep, read back, load-bearing, spine. These words are for the editor, never for the reader.
- Coined metaphor system: label, rung, ladder where the author says "points to". The author's plain phrase wins.
- Reference-manual register: attribute inventories that no transcript on the page shows.
- Thesis-first opener: a section that opens on the theme instead of the reader's situation.
- Trailer copy: "the stakes go up", "watch X", "while you watch", "see who wins".
- Self-interview and question lists: a question answered in a fragment, or an opener listing the questions the section will answer. Voicing the reader's question and answering it in full sentences is the author's move and stays.
- Frame phrases and unbounded superlatives: "the honest way to think about", "let me be precise", "three weeks from now", "better than anything else in the language".
- Contraction drought: the reference contracts and the draft does not. Count both. The settled rule: contract the negatives (don't, doesn't, can't), leave "it is", "that is", and "you are" as the reference leaves them.
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
- Summary habit fork: quote the body's "I" sentences verbatim. Never paraphrase one into the summary.
- Thesis word: a plain adjective worn into a system by repetition (a section title, the opening, five verdicts, the summary). Count any adjective in a heading that recurs in more than three verdicts, in both texts. Show the author every place with what each option produces. They decide which places keep it.
- Undefined acronym at first use where the reference defined it with a link (LBYL, EAFP). Restore the reference definition instead of writing a box.
- Edition commentary: "the earlier edition", "the original lesson", a box naming editions. A read-back that refers to a lesson the page never sets up is a missing restoration, not a deletion.
- Back-pointer: two chapters each saying the other owns a topic, so nobody covers it. Grep the target branch for this chapter's number and the previous chapter for promises made to this one before trusting or dropping a pointer.
- Verification that ends in a box: an undemonstrated version claim that, once run on every supported version, differs across them becomes a version caveat with a fallback, not a cut.

### Avoid in prose

- Marketing language: seamless, powerful, game-changing, effortless. Benefits without failure modes.
- Universal claims without a named boundary, unexplained imperatives, fake neutrality.
- Formula signposting: "in this section", "as you can see", "it should be noted". Trust the heading and start with the problem.
- Stacked concession markers, previews and recaps, sentences that teach two mechanisms.
- Jokes in consecutive paragraphs, memes, internet slang, explained punchlines.

### Before finishing prose

- Verify the chain: problem, mechanism, example, read-back, caveat in place, owned recommendation, handoff.
- Verify the boxes: planned, typed by the note-versus-tip rule, one breath long, placed against their code.
- Replace vague "this" and generic praise with the actual object and the specific benefit.
- Sweep for the tells of a second writer, count contractions against the reference, and read the first and last sentence of every section.
- Check that every "I" sentence is the author's, every path is on the fictional machine, and every cross-reference uses the current title.
- Run the punctuation and spelling scan last.

## Security

- Validate and sanitize at system boundaries (user input, API responses, file reads). Trust internal code.
  Why: boundary validation catches malicious input early. Internal validation is redundant noise.
- Never hardcode credentials, tokens, or keys. Never log sensitive data. Use environment variables or secret managers.
  Why: hardcoded secrets leak via git history, logs, and error messages. A secret-blocking hook catches file-level issues but not inline code.
- Use established cryptography libraries only (cryptography, bcrypt, argon2). No MD5/SHA1 for security purposes.
  Why: custom crypto is virtually always broken. Weak hashes are trivially reversible.

## Git

- Default branch is always `master`, never `main` — for every repo, whether created, renamed, or configured.
  Why: personal convention; GitHub's post-2020 `main` default was never a choice the user made.

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

## Background Agents

- A spawned agent is not running until its output proves it. Require a progress file as its first action, verify the file exists within a minute, and start a Monitor on it that reports each step and flags ten minutes of silence.
  Why: a teammate spawn can appear on the roster as "running" while it never started. Trusting the roster cost the user two hours of waiting on a dead agent (mt940 compat audit, 2026-09-07).
- On every user turn while an agent runs, check its progress before answering. Never wait passively for a completion notification.
  Why: the notification never arrives for an agent that died at spawn.

## Error Handling

- Read the error. Understand root cause. Fix the actual problem.
  Why: retrying the same command hoping for a different result is wasted cycles.
- Never retry a failed command without changing something first.
  Why: if the input, state, or approach hasn't changed, the output won't either.

## Tooling Awareness

- Python files are auto-formatted by a ruff hook on every edit (where configured). Do not manually run ruff or format Python code.
  Why: an automatic post-edit hook handles this. Manual formatting creates duplicate work.
- Editing .env, .pem, .key, credentials, or secrets files is blocked by a pre-edit hook. Ask the user for explicit approval before attempting.
  Why: prevents accidental credential exposure. The hook will deny the edit regardless.
- Prefer uv over pip. Prefer ruff over black/isort. Prefer pytest for testing.
  Why: these are the user's standard Python tools across projects.
- Never use snap to install anything — not as a fallback, not when suggested by error messages. Use brew, official installer scripts, git, or npm instead.
  Why: user convention; snap is unwanted on all systems.
- Background monitoring or automation must not create the default tmux server. Unless the user explicitly asks to use their interactive server, use a dedicated socket such as `tmux -L agent-<task>`.
  Why: a headless process can become the default server owner and leave every later interactive tmux session with the wrong macOS privacy context.
