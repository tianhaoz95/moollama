```bash
cat gemini/work-on-issues.md | gemini --yolo
```

For `.gemini/settings.json`:

```json
{
  "model": "gemini-2.5-flash",
  "mcpServers": {
    "dart": {
      "command": "dart",
      "args": [
        "mcp-server"
      ]
    }
  }
}
```

```bash
*/30 * * * * cat /home/tianhaoz/project/moollama/gemini/cron-improvement.md | /home/tianhaoz/.nvm/versions/node/v22.19.0/bin/gemini -m gemini-2.5-flash --include-directories /home/tianhaoz/project/moollama --yolo >> /tmp/gemini_job.log 2>&1
```

For `.vscode/settings.json`:

```json
{
    "ego.power-tools": {
        "jobs": [
            {
                "name": "Gemini CLI auto PR creation/update flow",
                "description": "Run Gemini CLI autonomous PR implementation flow every 30 mintues.",
                "time": "* */30 * * * *",
                "action": {
                    "type": "shell",
                    "command": "./gemini/cron.sh",
                    "silent": false,
                    "wait": true
                },
                "button": {
                    "text": "PR create/update"
                }
            }
        ]
    }
}
```