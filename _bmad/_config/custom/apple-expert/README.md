# Custom BMAD Agents

Custom agents built with the BMB Agent Builder workflow. Each agent is packaged as a standalone BMAD module for installation into any BMAD project.

## Agents

### Siri — Apple Platform Documentation Expert

Validates API choices against Apple documentation, finds WWDC sessions, checks platform compatibility, and maintains project-specific memory of all decisions. Uses the Apple Docs MCP server for live documentation queries.

**Commands:**

| Code | Command |
|------|---------|
| VA | Validate API choice against Apple documentation |
| WD | Find relevant WWDC sessions for a topic |
| SA | Find Apple sample code for implementation patterns |
| CO | Check platform availability and deployment targets |
| AL | Find modern replacements for deprecated APIs |
| NW | Recent updates to a framework or technology |
| LN | Getting started guide + WWDC recommendations |
| ME | What I know about Apple APIs in this project |

**MCP Dependency:** Requires `@kimsungwhee/apple-docs-mcp` — see [MCP Setup](#mcp-setup) below.

---

## Installation

### Option 1: BMAD Installer (Recommended)

During a new BMAD installation or modification, provide this module's path when prompted for custom modules:

```bash
npx bmad install --custom-content /path/to/this/siri
```

Or during the interactive installer, enter the absolute path to this `siri/` directory when asked:

```
Path to custom module folder: /path/to/this/siri
```

The installer will:
- Cache the module source in `_bmad/_config/custom/apple-expert/` (for future updates)
- Install the module to `_bmad/apple-expert/`
- Compile `siri.agent.yaml` into the final `.md` format with activation rules
- Copy sidecar template files to `_bmad/_memory/siri-sidecar/`
- Create `apple-expert-siri.customize.yaml` in `_bmad/_config/agents/` for agent customization
- Register the module in the project's manifest

### Option 2: Manual Installation

Copy the agent and sidecar files directly into your BMAD project:

```bash
# Agent file (mirrors installer target path)
mkdir -p _bmad/apple-expert/agents/siri/
cp agents/siri/siri.agent.yaml _bmad/apple-expert/agents/siri/

# Sidecar memory (each project gets its own independent copy)
mkdir -p _bmad/_memory/siri-sidecar/
cp agents/siri/siri-sidecar/*.md _bmad/_memory/siri-sidecar/
```

### Option 3: Claude Code Command (Optional)

Create `.claude/commands/siri.md` in your project for `/siri` invocation:

```markdown
---
description: Summon Siri - Apple Platform Documentation Expert
---

You are now the Siri agent. Load and embody the agent definition:

1. Read COMPLETE file: `_bmad/apple-expert/agents/siri/siri.agent.yaml`
2. Read COMPLETE file: `_bmad/_memory/siri-sidecar/api-decisions.md`
3. Read COMPLETE file: `_bmad/_memory/siri-sidecar/project-patterns.md`
4. Read COMPLETE file: `_bmad/_memory/siri-sidecar/wwdc-references.md`

Adopt the persona, principles, and communication style defined in the agent YAML.

Present your menu of commands and ask how you can help with Apple platform development.

$ARGUMENTS
```

---

## MCP Setup

Siri requires the Apple Docs MCP server in every project where it is installed.

**Add to Claude Code:**
```bash
claude mcp add apple-docs -- npx -y @kimsungwhee/apple-docs-mcp
```

**Or add manually to `.mcp.json` in project root:**
```json
{
  "mcpServers": {
    "apple-docs": {
      "command": "npx",
      "args": ["-y", "@kimsungwhee/apple-docs-mcp"]
    }
  }
}
```

**Verify:**
```bash
claude mcp list
```

---

## Sidecar Memory

Each project gets its own independent sidecar memory at `_bmad/_memory/siri-sidecar/`. These files are blank templates at install time and grow as you use the agent:

| File | Purpose |
|------|---------|
| `api-decisions.md` | API verdicts (APPROVED / CAUTION / REJECTED) with sources, rationale, and dates |
| `project-patterns.md` | Established framework conventions, architectural decisions, deployment targets |
| `wwdc-references.md` | Catalog of WWDC sessions cited for the project |

The agent uses a three-tier resolution pattern to minimize MCP calls:
1. **Sidecar hit** — verdict already cached locally, zero MCP calls
2. **Sidecar partial** — framework known but specific API not cached, targeted MCP query
3. **Sidecar miss** — no local knowledge, full MCP lookup + write-back

Every MCP interaction writes results back to the appropriate sidecar file. Over time, more queries are served from local memory.

On updates, the BMAD installer preserves sidecar files that have been modified — your project's accumulated knowledge is never overwritten.

---

## Module Structure

```
siri/
├── README.md              # This file
├── module.yaml            # BMAD installer manifest
└── agents/
    └── siri/
        ├── siri.agent.yaml
        └── siri-sidecar/
            ├── README.md
            ├── api-decisions.md
            ├── project-patterns.md
            └── wwdc-references.md
```

## Adding More Custom Agents

To add another agent to this collection:

1. Build the agent with `/bmad-bmb-create-agent`
2. Create a new directory under `agents/` following the same pattern:
   ```
   agents/
   └── my-agent/
       ├── my-agent.agent.yaml
       └── my-agent-sidecar/   # if hasSidecar: true
           └── *.md
   ```
3. The existing `module.yaml` covers all agents in the `agents/` directory — no changes needed unless you want a separate installable module

Alternatively, create a separate module directory with its own `module.yaml` for independent installation.
