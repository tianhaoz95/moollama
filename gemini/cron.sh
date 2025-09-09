#!/bin/bash

git fetch origin
git reset --hard origin/main
git checkout main
git branch | grep -v "main" | xargs git branch -D

issue_count=$(gh issue list --search "label:gemini" --limit 1 | wc -l)

if [ "$issue_count" -gt 0 ]; then
  cat ./gemini/cron-pr.md | gemini --yolo
  git fetch origin
  git reset --hard origin/main
  git checkout main
  git branch | grep -v "main" | xargs git branch -D
else
  echo "No gemini labeled issue found!"
fi

pr_count=$(gh pr list --search "label:wip" --limit 1 | wc -l)

if [ "$pr_count" -gt 0 ]; then
  cat ./gemini/cron-pr-fix.md | gemini --yolo
  git fetch origin
  git reset --hard origin/main
  git checkout main
  git branch | grep -v "main" | xargs git branch -D
else
  echo "No wip pull request found!"
fi
