# Contribute to this documentation

This guide describes how to make a change to the Enterprise Store
documentation.

Documenting involves running commands in a command-line interface and
syncing code with Git and GitHub. If you're new to these tools, we
recommend you make your first contribution with the help of
[Canonical's Open Documentation Academy](https://documentationacademy.website/).

## Set up your work environment

For security, you must sign your commits. If you haven't already,
configure Git to sign with your GPG or SSH key.

Create a personal fork of the repository on GitHub.

Next, clone your fork onto your local machine:

```bash
git clone git@github.com:<username>/enterprise-store-docs
cd enterprise-store-docs
git remote add upstream git@github.com:canonical-ols/enterprise-store-docs
git fetch upstream
```

If you can't authenticate your GitHub account with SSH, use HTTPS
instead:

```bash
git clone https://github.com/<username>/enterprise-store-docs
cd enterprise-store-docs
git remote add upstream https://github.com/canonical-ols/enterprise-store-docs
git fetch upstream
```

Inside the project directory, set up the documentation environment and
check it:

```bash
cd docs
make install
make run
```

If these commands complete without error, your environment is ready.

## Choose a task

Tasks come in different sizes and complexity. It's important to choose
a task that you have the capacity to finish, and plan accordingly.

Small changes and changes that need no explanation, like fixing
spelling and grammar mistakes or misplaced punctuation, are simple to
incorporate and don't need any planning.

If you intend to make a large or complex change, like a page rewrite or
a bulk edit, the task must be tracked as a GitHub issue. If your task
isn't tracked, create an issue for it.

Once you choose an issue, volunteer for it in the issue's comments. A
maintainer will review your request and assign it to you.

## Draft your work

### Create a branch

Before you begin your work, sync your local copy of the code and create
a new branch:

```bash
git fetch upstream
git switch -c <new-branch-name> upstream/main
```

If your task has no GitHub issue, make the branch name succinct and
memorable, so that you can keep track of your different branches.

If the task has a GitHub issue, start with the ticket ID instead.
Starting with the ID is especially helpful when you're addressing the
issue across multiple branches. For example, if you're working on
GitHub issue #42, and updating the API reference, you could name the
branch `issue-42-api-reference`.

### Write

This project follows the Canonical conventions for documentation tone,
style, accessibility, and formatting. If you're looking for a way to
express something that isn't covered by a convention, explore the
existing documents. They provide a broad base of effective technical
writing.

All documents are in the `docs` directory. Pay attention to how the
directory structure, the document file names, and the `index.rst`
files combine to form the document architecture.

### Test

When you're ready to preview your draft, save all the files you worked
on and build the site locally:

```bash
cd docs
make html
```

If successful, the terminal prints:

```text
build succeeded.
The HTML pages are in docs/_build.
```

Preview your changes in a web browser. Make sure the elements you've
changed render as expected. Double-check nested elements, such as
content inside tabs and admonitions.

If everything looks good, check for problems in your document sources:

```bash
make vale
make spelling
make linkcheck
```

### Commit

Register the changes to your branch with a Git commit:

```bash
git add -A
git commit
```

Format the commit message like this:

```text
docs: <brief description of change>
```

Keep the message short, at 80 characters or less, so other contributors
and the project maintainers can see the gist of what you did.

Commit early and often. It's normal to make multiple commits for a
single piece of work, especially when you come back to review it later.
It's a good habit that keeps your changes safe.

## Review with the team

### Send for review

When you've committed your draft and you're ready to have it reviewed,
push it to your fork:

```bash
git push -u origin <branch-name>
```

Then, open a pull request (PR) for it on GitHub. Give the PR a title
using the same message format as the commit. If your branch has more
than one commit, reuse the message from the first.

### Address quality concerns

Before the PR is merged, it must pass all automatic checks, and it
needs approval from a maintainer.

Each PR builds a preview of the documentation on Read the Docs. For
safety, it's a good idea to manually verify that the preview looks
identical to your local build.

If there are any issues in your branch that your local testing didn't
catch, then the automatic checks will fail. To address these issues,
review the logs in the failed checks. The error messages in the logs
will have remedies and hints for what needs fixing.

When the maintainers review the PR, they may suggest improvements.
Address them in follow-up commits to your branch, the same way you
committed and pushed changes while drafting. If you feel a particular
point should go in a different direction than what they suggest,
discuss it with the maintainer in the PR. They'll be happy to explore
alternatives.

### Wrap up the review

Once all suggestions are addressed, the maintainers will approve the
PR. After the PR is approved, there may be a delay before merge. The
maintainers might need time to coordinate the PR with other active
developments.

After approval, don't force-push to your branch. It's difficult for
the maintainers to see whether any additional changes mixed into the
push.

Once the PR is merged, your work is complete.

## Get help and support

Open source contribution can be difficult. Even the most experienced
writers become tangled or have moments of uncertainty.

If you're stuck, or need more information about a task, ask the issue
creator or a maintainer. You can also get community support through
the [Snap Store forum category](https://forum.snapcraft.io/c/store/16).
