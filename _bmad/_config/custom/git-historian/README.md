# Gloria — Git Repository Archivist

Git history navigator with persistent memory. Gloria reads the story between the commits — navigates epic/story history, identifies struggles and lessons learned, and learns repository-specific patterns over time. No MCP dependencies — pure git CLI.

## Commands

| Code | Command |
|------|---------|
| SC | Scan repository to bootstrap knowledge (run this first) |
| RC | Full epic/story history as narrative arc |
| CM | Quick SHA reference list for a story/epic |
| SA | Lessons learned — what was hard and why |
| CT | Expand context on the last discussed epic/story |
| ME | What I have learned about this repo |

**Dependencies:** Git repository only. No MCP servers required.

---

## Installation

### Option 1: BMAD Installer (Recommended)

During a new BMAD installation or modification, provide this module's path when prompted for custom modules:

```bash
npx bmad install --custom-content /path/to/this/gloria
```

Or during the interactive installer, enter the absolute path to this `gloria/` directory when asked:

```
Path to custom module folder: /path/to/this/gloria
```

The installer will:
- Cache the module source in `_bmad/_config/custom/git-historian/` (for future updates)
- Install the module to `_bmad/git-historian/`
- Compile `gloria.agent.yaml` into the final `.md` format with activation rules
- Copy sidecar template files to `_bmad/_memory/gloria-sidecar/`
- Create `git-historian-gloria.customize.yaml` in `_bmad/_config/agents/` for agent customization
- Register the module in the project's manifest

### Option 2: Manual Installation

Copy the agent and sidecar files directly into your BMAD project:

```bash
# Agent file (mirrors installer target path)
mkdir -p _bmad/git-historian/agents/gloria/
cp agents/gloria/gloria.agent.yaml _bmad/git-historian/agents/gloria/

# Sidecar memory (each project gets its own independent copy)
mkdir -p _bmad/_memory/gloria-sidecar/
cp agents/gloria/gloria-sidecar/*.md _bmad/_memory/gloria-sidecar/
```

### Option 3: Claude Code Command (Optional)

Create `.claude/commands/gloria.md` in your project for `/gloria` invocation:

```markdown
---
description: Summon Gloria - Git Repository Archivist
---

You are now the Gloria agent. Load and embody the agent definition:

1. Read COMPLETE file: `_bmad/git-historian/agents/gloria/gloria.agent.yaml`
2. Read COMPLETE file: `_bmad/_memory/gloria-sidecar/patterns.md`
3. Read COMPLETE file: `_bmad/_memory/gloria-sidecar/conventions.md`
4. Read COMPLETE file: `_bmad/_memory/gloria-sidecar/navigation-hints.md`

Adopt the persona, principles, and communication style defined in the agent YAML.

Present your menu of commands and ask how you can help navigate this repository's history.

$ARGUMENTS
```

---

## Getting Started

After installation:

1. **Run SC first** — `SC` scans the repository to bootstrap Gloria's knowledge of your commit conventions, tag patterns, and project structure
2. **Try RC on a recent epic** — `RC 18` to see narrative history for epic 18
3. **Run SA on a challenging story** — `SA 15-2` to analyze what was hard and why
4. **Check ME anytime** — `ME` to see what Gloria has learned about your repo

**Example interactions:**
- "RC: Show me the history for epic 18"
- "CM: What commits are in story 18-4?"
- "SA: What was hard about story 15-2?"
- "CT: Tell me more about what we just discussed"
- "ME: What have you learned about this repo?"

---

## Sidecar Memory

Each project gets its own independent sidecar memory at `_bmad/_memory/gloria-sidecar/`. These files are blank templates at install time and grow as you use the agent:

| File | Purpose |
|------|---------|
| `patterns.md` | Repeatable lessons from struggles and structural insights about the codebase |
| `conventions.md` | Commit message format, tag scheme, artifact paths, ID notation style |
| `navigation-hints.md` | Useful git commands specific to this repository |

**What Gloria remembers:** Contextual intelligence — why things were hard, how to navigate efficiently, what conventions this repo follows.

**What Gloria does NOT store:** Commit SHAs, diffs, file lists, or git log output. Git is always the source of truth. Sidecar stores insights, not data.

**Write criteria:** Only genuinely repeatable lessons trigger sidecar writes. The SA (Struggle Analysis) command is the primary insight producer. Most RC/CM/CT executions do not update the sidecar.

On updates, the BMAD installer preserves sidecar files that have been modified — your project's accumulated knowledge is never overwritten.

---

## Module Structure

```
gloria/
├── README.md              # This file
├── module.yaml            # BMAD installer manifest (code: git-historian)
└── agents/
    └── gloria/
        ├── gloria.agent.yaml
        └── gloria-sidecar/
            ├── README.md
            ├── patterns.md
            ├── conventions.md
            └── navigation-hints.md
```

## Installed Structure (in target project)

```
_bmad/
├── _config/
│   ├── agents/git-historian-gloria.customize.yaml
│   └── custom/git-historian/              # cached source
├── _memory/gloria-sidecar/                # project-specific memory
│   ├── patterns.md
│   ├── conventions.md
│   └── navigation-hints.md
└── git-historian/agents/gloria/gloria.md  # compiled agent
```
