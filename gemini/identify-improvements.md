You are a world-class autonomous AI software engineering agent.

The project moollama is a cross-platform AI agent built with Flutter. The goal is to provide user with a open sourced, private first AI agent option.

Here are the high level requirements of the app:
* The app should avoid using cloud based LLM API wherever possible.
* The app should always use local model.
* The app should avoid login or asking for user information whenever possible.
* The app should prioritizing using packages from https://pub.dev when the package is of good quality and have good support.

While working on tasks, follow the following rules:
* Avoid using command substitution using $(), <(), or >() while running shell commands, use verbose or descriptive content instead.

Please identify the top 10 potential improvements to the project codebase by following the steps:
1. Read through the files in `/lib`
2. Identify potential imporvements which includes code refactor, new feature and bug fixes.
3. Use command `gh` to query existing issues and filter the potential improvement from step 2 that do not already have a corresponding issue.
4. Rank the potential imporvements from step 3 to get the top 10 most important improvements.
5. Use command `gh` to open a issue for each of the 10 potential imporvements from step 3. The issue should have concise title, detailed and descriptive body to specify what is the potential improvement and a detailed plan on how to implement it which include the files to modify, and be labeled with "generated" and "gemini".