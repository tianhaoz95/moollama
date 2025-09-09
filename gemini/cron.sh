#!/bin/bash

git fetch origin
git reset --hard origin/main
git checkout main
git branch | grep -v "main" | xargs git branch -D

cat ./gemini/cron-pr.md | gemini --yolo
git fetch origin
git reset --hard origin/main
git checkout main
git branch | grep -v "main" | xargs git branch -D

cat ./gemini/cron-pr-fix.md | gemini --yolo
git fetch origin
git reset --hard origin/main
git checkout main
git branch | grep -v "main" | xargs git branch -D