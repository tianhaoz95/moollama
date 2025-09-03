Please complete the following tasks:

## Task 1: improve previous opened pull requests

First use `gh` command to find open pull requests related to the current repository.

For each open pull request, do the following:
1. Fetch the pull request title, body and comments.
2. Checkout the code to the branch of the pull request and pull to make sure local code is up to date.
3. Rebase the codebase with main branch to make sure the code is up to date.
4. Analyze if any of the requirements specified by the pull request title, body and comments are not implemented, implement them and add unit tests if applicable. During the implementation, use `flutter test` and `flutter build apk` command to verify the correctness of the implementation, fix any issue if present.
5. Commit the implementation with proper commit message on the branch created.
6. Push the commit to update the pull request.
7. Leave a comment summarizing the changed maded using the `gh` command.
8. Go back to the main branch to make sure the codebase is clean to work on for the next task.

## Task 2: implement newly added issues

First use `gh` command to find open issues related to the current repository.

For each open issue, do the following:
1. Fetch the issue title and body.
2. Create a branch with name that describes the solution to the issue.
3. Publish the branch.
4. Implement the requirements specified by the issue title and content on the branch created, add unit tests if applicable, and use `flutter test` and `flutter build apk` command to verify the correctness of the implementation, fix any issue if present.
5. Commit the implementation with proper commit message on the branch created.
6. Push the commit.
7. Open a pull request to the main branch using `gh` command.
8. Go back to the main branch to make sure pull requests only depends on main branch.
