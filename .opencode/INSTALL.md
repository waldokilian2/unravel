# Installing Unravel for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed
- Git installed

## Installation Steps

### 1. Clone Unravel

```bash
git clone https://github.com/waldokilian2/Unravel.git ~/.config/opencode/unravel
```

### 2. Register the Plugin

```bash
mkdir -p ~/.config/opencode/plugins
rm -f ~/.config/opencode/plugins/unravel.js
ln -s ~/.config/opencode/unravel/.opencode/plugins/unravel.js ~/.config/opencode/plugins/unravel.js
```

### 3. Symlink Skills

```bash
mkdir -p ~/.config/opencode/skills
rm -rf ~/.config/opencode/skills/unravel
ln -s ~/.config/opencode/unravel/skills ~/.config/opencode/skills/unravel
```

### 4. Restart OpenCode

Verify by asking: "What Unravel skills do you have?"

## Usage

Use OpenCode's native `skill` tool to list and load Unravel skills.

## Updating

```bash
cd ~/.config/opencode/unravel
git pull
```

## Tool Mapping

When skills reference Claude Code tools:
- `TodoWrite` → `update_plan`
- `Task` with subagents → `@mention` syntax
- `Skill` tool → OpenCode's native `skill` tool
- File operations → Your native tools
