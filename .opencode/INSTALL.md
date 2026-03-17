# Installing Business Analyst for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed
- Git installed

## Installation Steps

### 1. Clone Business Analyst

```bash
git clone https://github.com/waldokilian2/Unravel.git ~/.config/opencode/business-analyst
```

### 2. Register the Plugin

```bash
mkdir -p ~/.config/opencode/plugins
rm -f ~/.config/opencode/plugins/business-analyst.js
ln -s ~/.config/opencode/business-analyst/.opencode/plugins/business-analyst.js ~/.config/opencode/plugins/business-analyst.js
```

### 3. Symlink Skills

```bash
mkdir -p ~/.config/opencode/skills
rm -rf ~/.config/opencode/skills/business-analyst
ln -s ~/.config/opencode/business-analyst/skills ~/.config/opencode/skills/business-analyst
```

### 4. Restart OpenCode

Verify by asking: "What business analyst skills do you have?"

## Usage

Use OpenCode's native `skill` tool to list and load business analyst skills.

## Updating

```bash
cd ~/.config/opencode/business-analyst
git pull
```

## Tool Mapping

When skills reference Claude Code tools:
- `TodoWrite` → `update_plan`
- `Task` with subagents → `@mention` syntax
- `Skill` tool → OpenCode's native `skill` tool
- File operations → Your native tools
