# siri-sidecar

Persistent memory for the **Siri** Apple Platform Documentation Expert agent.

## Files

- **api-decisions.md**: Record of API verdicts (APPROVED/CAUTION/REJECTED) with sources, rationale, min targets, and dates
- **project-patterns.md**: Established Apple framework conventions, architectural decisions, and deployment targets
- **wwdc-references.md**: Catalog of cited WWDC sessions relevant to the project

## Required MCP Server

Siri requires the Apple Docs MCP server for live documentation queries.

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

Expected: `apple-docs: npx -y @kimsungwhee/apple-docs-mcp - ✓ Connected`

## Runtime Access

Agent accesses these at: `{project-root}/_bmad/_memory/siri-sidecar/`

## Growth Pattern

These files grow as Siri validates APIs, discovers patterns, and cites WWDC sessions. Every MCP interaction writes back to the appropriate file. Over time, more queries are served from local memory (three-tier resolution: sidecar hit > sidecar partial > MCP miss).
