# Project Instructions

Sage is a native Swift iOS expense tracker. Follow the existing architecture and
UI conventions; inspect the relevant code before choosing an implementation.

These instructions apply the prompting recommendations in the
[GPT-6 Astra guide](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-6-astra).

## Initiative and Follow-Through

- Treat requests such as "can you fix" or "help me implement" as instructions to
  do the work, unless the user is explicitly asking for an explanation or plan.
- Carry authorized work through implementation, appropriate verification, and a
  clear report of the outcome. Do not stop at a proposal or partial solution.
- Make reasonable assumptions for routine, reversible decisions. Ask a focused
  question when the answer would materially change scope or correctness and
  cannot be inferred from the project or conversation.
- Complete independent, authorized preparation before asking for approval of an
  action that needs it. Do not add approval pauses for ordinary local edits or
  read-only inspection.
- Get explicit authorization before committing, pushing, publishing, deploying,
  or performing destructive actions. Preserve unrelated worktree changes.

## Instructions and Skills

- Follow system and developer instructions first. Explicit user instructions
  take precedence over project and skill guidelines.
- Load only relevant skills and check their instructions for conflicts with the
  task and this project's native Swift implementation.
- If a skill causes a pause, an approval request, unfinished work, or a departure
  from the user's intent, link to the exact `SKILL.md`, quote the relevant
  instruction, and explain its effect. Distinguish requirements from your own
  interpretation of guidance.

## Communication

- State the main point early, using plain language and concise paragraphs.
  Include technical detail when it helps explain the change or a decision.
- Use lists for parallel items or steps; avoid nested lists, unnecessary tables,
  stock phrases, and repetitive summaries.
- Give brief progress updates for meaningful discoveries, edits, or blockers.
  Finish with the outcome, checks performed, and any unresolved limitations.

## Main Thread and Subagents

- Keep work in the main agent thread whenever possible, including research,
  planning, implementation, review, and verification.
- Do not launch subagents or delegate work to other agents unless the user
  explicitly requests their use in the prompt. Task complexity, potential time
  savings, available tools, and skill recommendations are not authorization.
- Without an explicit request for subagents, use tools directly in the main
  thread. Independent tool calls may still run in parallel without subagents.
- When subagents are explicitly requested, limit delegation to the requested
  scope and keep other work in the main thread. Give each agent clear context
  and an expected result, avoid overlapping edits or duplicated work, and review
  its results before using them.

## Testing and Verification

- Prefer the smallest correct change and tests that verify meaningful behavior.
  Do not add tests that merely mirror reversible, low-impact implementation.
- Run checks appropriate to the affected code and complete required checks.
  Broaden or repeat testing only for new edits, failures, or unresolved concerns.
- For iOS build and test conventions, use `.github/workflows/ios.yml` as the
  reference: `FinanceTracker.xcodeproj`, scheme `FinanceTracker`, and an available
  iPhone simulator. Target relevant tests when the scope permits.
- For documentation-only changes, review the diff and run `git diff --check`;
  an app build is unnecessary unless the change also affects build behavior.
- Report what actually ran. If verification is blocked, describe the blocker
  without claiming the checks passed.
