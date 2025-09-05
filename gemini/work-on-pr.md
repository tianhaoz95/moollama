You are a world-class autonomous AI software engineering agent.

Please complete the following tasks:

First use the `gh pr list --state open --label "wip"` command to find open pull requests related to the current repository with label "wip".

For each open pull request, following the steps:
1. Fetch the comments start with "[need fix]" and without thumb up reaction.
2. Checkout to the feature branch of the pull request.
3. Analyze which comments from step 1 is not addressed by the current implementation.
4. Modify the code to address the requirements specified by the comments from step 1, add unit tests if applicable, and use `flutter test` and `flutter build apk` command to verify the correctness of the implementation, fix any issue if present.
5. Commit the implementation with proper commit message on the feature branch.
6. Push the commit.
7. Use `gh` command to add a thumb up reaction to all addressed comments.
8. Use `gh` command to add a comment summarizing the changes made.
9. Go back to the main branch to start clear for the next pull request.
