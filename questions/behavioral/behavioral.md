# Behavioral questions

How to prepare answers about your own experience. These are frameworks, not scripts: interviewers
notice memorised stories, and the answer has to be yours.

## BHV-001: How do you structure an answer with the STAR method?

**Level:** junior

STAR keeps a story short and makes your own contribution clear:

- **Situation** — one or two sentences of context: the team, the app, the constraint.
- **Task** — what you were responsible for, or the problem to solve.
- **Action** — the longest part: what _you_ did and why, the options you considered, how you
  worked with others. Say "I" for your part and "we" for the team's.
- **Result** — what changed, with numbers where you have them (crash-free rate, release cadence,
  review time), and what you learned.

Aim for about two minutes. Prepare five to seven stories that each cover several themes (a hard bug,
a conflict, a failure, leading without authority, a trade-off under time pressure) and practise
telling them aloud. If you do not have the perfect example, say so and use the closest real one;
invented details fall apart under follow-up questions.

## BHV-002: "Tell me about yourself."

**Level:** junior

This is a request for a short, relevant summary, not a life story. A structure that works:

1. **Now** — your current role and the kind of mobile work you do (platforms, product type,
   team size).
2. **Highlights** — two achievements that match the job you are interviewing for, each in one
   sentence with a result.
3. **Why this role** — what draws you to this team or product, connected to what you just said.

Keep it to about a minute and a half, and end with something they are likely to ask about. Adjust
the highlights for each company: the same career can be told as a performance story, a
product-ownership story or a platform story.

## BHV-003: Tell me about a production incident you handled.

**Level:** mid

Interviewers look for calm prioritisation, communication and follow-through.

- **Detection and impact**: how you found out (crash reporting, a spike in support tickets) and
  how many users were affected.
- **Mitigation first**: what stopped the damage quickly — halting a staged rollout, turning off a
  feature flag, a server-side fix — before the root-cause fix.
- **Diagnosis**: how you found the cause (symbolicated crash logs, reproducing on a device, bisecting
  commits), and who you involved.
- **Communication**: who you kept informed, and how often.
- **Prevention**: the post-incident changes — a test, a monitor, a release checklist item — and
  that the review was blameless.

Mobile-specific details make the story credible: the fix needed App Review, older versions stayed
affected, or a forced-update mechanism had to be used.

## BHV-004: Tell me about a time you disagreed with a product manager or designer.

**Level:** mid

The interviewer wants to see that you disagree with evidence, respect the other person's goals and
commit once a decision is made.

Show that you:

- understood _their_ goal first (a deadline, a business metric, a user need);
- made the technical cost or risk concrete: performance on old devices, accessibility, platform
  guidelines, maintenance cost, App Store review risk;
- offered alternatives instead of just saying no — a smaller first version, a prototype, an A/B
  test, a phased approach;
- reached a decision together, or escalated respectfully, and then supported it fully.

Avoid stories where the other person is simply wrong and you win. A good ending is a better product
and a working relationship, even when your proposal was not the one chosen.

## BHV-005: Tell me about a technical decision that turned out badly.

**Level:** senior

This tests self-awareness. Choose a real decision with real consequences, not a disguised success.

1. The decision and the reasoning at the time — it should have been reasonable with what you knew.
2. What went wrong and when you noticed.
3. What you did about it: how you limited the damage, migrated away, or explained it to the team.
4. What you changed in how you decide: prototyping before committing, writing down assumptions,
   setting a review date, involving others earlier.

Examples that fit mobile work: adopting a cross-platform or state-management library that the team
later had to replace, an architecture that made testing hard, a dependency that stopped being
maintained, or building a custom solution where a platform API existed.

## BHV-006: How do you balance technical debt against new features?

**Level:** senior

Show that you treat debt as a business decision, not a matter of taste:

- **Make it visible**: keep debt items in the same backlog, each with its cost described in terms
  others understand — slower feature work, crashes, onboarding time, blocked OS adoption (a
  deprecated API with a removal date).
- **Prioritise by impact and urgency**: debt in code that changes often or that blocks a platform
  requirement (a new minimum SDK or target API level) comes first; debt in stable code can wait.
- **Pay it down continuously**: improve code you touch for features, reserve a share of each cycle,
  and attach larger refactors to features that need them.
- **Measure the result**: build times, crash rates, time to ship a typical change.

A concrete story helps: for example, migrating to a new concurrency model or UI framework step by
step while still shipping features.

## BHV-007: How do you mentor other developers and run code reviews?

**Level:** mid

For mentoring, describe how you adapt to the person: pairing on a real task, giving them ownership
of something slightly beyond their current level with support, and explaining _why_ a solution
works so they can apply it elsewhere. Mention how you knew it worked — they shipped a feature on
their own, or started reviewing others' code.

For code reviews, show that reviews are about the code and shared understanding, not gatekeeping:

- Small pull requests with a clear description and screenshots or recordings for UI changes.
- Automate what tools can check (formatting, lint, tests in CI), so humans discuss design and
  correctness.
- Distinguish blocking issues from suggestions, explain the reason, and offer an alternative.
- Respond quickly; a review that waits for days slows the whole team.

## BHV-008: What questions should you ask the interviewer?

**Level:** junior

Ask questions whose answers help you decide, and that show you think about the work:

- How is the mobile team organised, and how does it work with backend and design?
- How often do you release, and what does the release process look like (feature flags, phased
  rollout, how a hotfix ships)?
- What is the testing setup, and what does CI run on each pull request?
- What is the biggest technical challenge in the app right now?
- How do you decide between feature work and technical debt?
- What does success look like for this role after six months?

Avoid questions answered on the company's website, and leave salary and benefits for the recruiter
unless the interviewer brings them up.
