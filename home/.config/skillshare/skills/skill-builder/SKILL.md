---
name: skill-builder
description: Create or update OpenCode agent skills (SKILL.md). Use when a user asks to add a reusable workflow/instructions bundle, fix skill discovery (name/frontmatter/path), or package a repeatable process into a skill with optional scripts/references/assets.
compatibility: opencode
metadata:
  audience: developers
  domain: opencode-skills
---

# Skill Builder

Build high-quality OpenCode skills that are discoverable, concise, and reusable.

## What a skill is (OpenCode)

- A skill is a folder named after the skill with a required `SKILL.md`.
- Only the YAML frontmatter `name` + `description` are used for discovery.
- The SKILL.md body is loaded on-demand after the skill is selected.

## Where to put it

Default to project-local unless the user explicitly wants global.

- Project: `.opencode/skills/<skill-name>/SKILL.md`
- Global: `~/.config/opencode/skills/<skill-name>/SKILL.md`

OpenCode also discovers Claude-compatible locations:

- `.claude/skills/<skill-name>/SKILL.md`, `~/.claude/skills/<skill-name>/SKILL.md`
- `.agents/skills/<skill-name>/SKILL.md`, `~/.agents/skills/<skill-name>/SKILL.md`

## Naming rules (must pass)

The directory name must match frontmatter `name` and must match:

`^[a-z0-9]+(-[a-z0-9]+)*$`

- 1-64 chars
- lowercase a-z, 0-9, single hyphens only
- no leading/trailing hyphen, no consecutive `--`

## Workflow

### 1) Clarify the skill goal with examples

Get 2-5 concrete prompts the user would say that should trigger the skill. Extract:

- target users (you vs team)
- environment (language/framework/tools)
- constraints (no network, CI-only, security, style)
- expected outputs (files, commands, checklists)

If the user gives no examples, propose 3 candidate triggers and have them pick.

### 2) Decide the right shape (progressive disclosure)

Keep `SKILL.md` lean and procedural. Put details elsewhere.

- Put the minimal workflow + decision rules in `SKILL.md`
- Put long references in `references/` and load them only when needed
- Put deterministic code in `scripts/` (prefer scripts over long code blocks)
- Put templates/boilerplate in `assets/`

Avoid creating extra docs like `README.md`, changelogs, or installation guides.

### 3) Write frontmatter that will be selected correctly

Frontmatter rules:

- Must be the first content in `SKILL.md`
- Must include `name` and `description`
- `description` should include trigger contexts/keywords since it is how agents decide
- Keep `description` 1-1024 chars; specific > clever

### 4) Write the body as an operator playbook

Use imperative language. Optimize for:

- repeatability
- guardrails for fragile steps
- clear stop conditions
- minimal token cost

Good sections:

- "Inputs to collect" (only if needed)
- "Safe defaults" (what to assume)
- "Step-by-step" (numbered, deterministic)
- "Validation" (how to verify success)
- "Failure modes" (common errors + fixes)

Avoid generic explanations the model already knows.

### 5) Validate discovery constraints

Before finishing, verify:

- directory name == frontmatter `name`
- `SKILL.md` is uppercase
- no unknown frontmatter fields relied upon
- skill appears via the `skill` tool (name + description)

### 6) (Optional) Configure permissions

If a user wants to restrict skills, add `permission.skill` patterns in `opencode.json`:

```json
{
  "permission": {
    "skill": {
      "*": "allow",
      "internal-*": "deny",
      "experimental-*": "ask"
    }
  }
}
```

## Minimal new-skill template

```md
---
name: <skill-name>
description: <what it does + when to use it>
---

# <Human Title>

## Safe defaults

## Workflow

## Validation
```

## Editing an existing skill

- Prefer small edits to `description` if the skill is not being selected.
- Move bulky content out of `SKILL.md` into `references/`.
- If the workflow repeats code, add a script and reference it from `SKILL.md`.
