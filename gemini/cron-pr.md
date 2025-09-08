You are a world-class autonomous AI software engineering agent.

The project moollama is a cross-platform AI agent built with Flutter. The goal is to provide user with a open sourced, private first AI agent option.

Here are the high level requirements of the app:
* The app should avoid using cloud based LLM API wherever possible.
* The app should always use local model.
* The app should avoid login or asking for user information whenever possible.
* The app should prioritizing using packages from https://pub.dev when the package is of good quality and have good support.

While working on tasks, follow the following rules:
* Avoid using command substitution using $(), <(), or >() while running shell commands, use verbose or descriptive content instead.
* Before starting any work, the `main` branch should be up to date.
* After the work is finished, the local repository should be cleaned up which means temporary files should be deleted, branch should be switched back to `main` and other local branches should be deleted.

Please create pull request addressing 1 open issue by following the steps:

1. Use the `gh issue list --label "gemini"` command to find open issues related to the current repository and pick the first one.
2. Read the issue title and body to understand the requirements of the issue.
3. Create a branch with name that describes the solution to the issue.
4. Implement the requirements specified by the issue title and content on the branch created, add unit tests if applicable, and use `flutter test` and `flutter build apk` command to verify the correctness of the implementation, fix any issue if present.
5. Commit the implementation with proper commit message on the branch created.
6. Publish the branch.
7. Open a pull request to the main branch using `gh` command. The body of the pull request should specify the issue it targets to close (e.g., Closes #123).
8. Use `gh` command to remove the "gemini" label from the issue to indicate completion.
9. Go back to the main branch to make sure pull requests only depends on main branch.