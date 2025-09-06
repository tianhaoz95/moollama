You are a world-class autonomous AI software engineering agent.

The project moollama is a cross-platform AI agent built with Flutter. The goal is to provide user with a open sourced, private first AI agent option.

Here are the high level requirements of the app:
* The app should avoid using cloud based LLM API wherever possible.
* The app should always use local model.
* The app should avoid login or asking for user information whenever possible.
* The app should prioritizing using packages from https://pub.dev when the package is of good quality and have good support.

While working on tasks, follow the following rules:
* Avoid using command substitution using $(), <(), or >() while running shell commands, use verbose or descriptive content instead.

Please complete the following task:

## Create issue for top improvements

Please identify the top 3 potential improvements to the project codebase by following the steps:
1. Read through the files in `/lib`
2. Identify potential imporvements which includes code refactor, new feature and bug fixes.
3. Use command `gh` to query existing issues and filter the potential improvement from step 2 that do not already have a corresponding issue.
4. Rank the potential imporvements from step 3 to get the top 3 most important improvement.
5. Use command `gh` to open a issue for each of the 3 potential imporvements from step 3. Do not use command substitution with `gh` command. The issue should have concise title, detailed and descriptive body to specify what is the potential improvement and a plan on how to implement it, and be labeled with "generated" and "gemini".

## Create pull requst addressing open issues

Please create pull request addressing open issue by following the steps:

First use the `gh issue list --label "gemini"` command to find open issues related to the current repository.

For each open issue, do the following:
1. Fetch the issue title and body.
2. Create a branch with name that describes the solution to the issue.
3. Publish the branch.
4. Implement the requirements specified by the issue title and content on the branch created, add unit tests if applicable, and use `flutter test` and `flutter build apk` command to verify the correctness of the implementation, fix any issue if present.
5. Commit the implementation with proper commit message on the branch created.
6. Push the commit.
7. Open a pull request to the main branch using `gh` command. The body of the pull request should specify the issue it targets to close (e.g., Closes #123).
8. Use `gh` command to remove the "gemini" label from the issue to indicate completion.
9. Go back to the main branch to make sure pull requests only depends on main branch.
