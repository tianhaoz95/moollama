```bash
cat gemini/work-on-issues.md | gemini --yolo
```

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
*/30 * * * * cat \
/home/tianhaoz/project/moollama/gemini/cron-improvement.md | \
/home/tianhaoz/.nvm/versions/node/v22.19.0/bin/gemini \
  -m gemini-2.5-flash \
  --include-directories /home/tianhaoz/project/moollama \
  --yolo  \
>> /tmp/gemini_job.log 2>&1
```
