# Installing Business Analyst for Codex

Enable business analyst skills in Codex via native skill discovery.

## Prerequisites

- Git

## Installation

1. **Clone the business-analyst repository:**
   ```bash
   git clone https://github.com/waldokilian2/Unravel.git ~/.codex/business-analyst
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/business-analyst/skills ~/.agents/skills/business-analyst
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\business-analyst" "$env:USERPROFILE\.codex\business-analyst\skills"
   ```

3. **Restart Codex** to discover the skills.

## Verify

```bash
ls -la ~/.agents/skills/business-analyst
```

## Updating

```bash
cd ~/.codex/business-analyst && git pull
```

## Uninstalling

```bash
rm ~/.agents/skills/business-analyst
rm -rf ~/.codex/business-analyst
```
