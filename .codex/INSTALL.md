# Installing Unravel for Codex

Enable Unravel skills in Codex via native skill discovery.

## Prerequisites

- Git

## Installation

1. **Clone the Unravel repository:**
   ```bash
   git clone https://github.com/waldokilian2/Unravel.git ~/.codex/unravel
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/unravel/skills ~/.agents/skills/unravel
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\unravel" "$env:USERPROFILE\.codex\unravel\skills"
   ```

3. **Restart Codex** to discover the skills.

## Verify

```bash
ls -la ~/.agents/skills/unravel
```

## Updating

```bash
cd ~/.codex/unravel && git pull
```

## Uninstalling

```bash
rm ~/.agents/skills/unravel
rm -rf ~/.codex/unravel
```
