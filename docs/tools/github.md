---
title: GitHub
parent: Tools & Workflows
---

# GitHub / Git – Basics

Even if you're working solo, it's a good idea to use Git and a platform like [**GitHub**](https://github.com/) or [**GitLab**](https://about.gitlab.com/). These tools help you manage, version, and share code—and for collaborative projects, they’re essential.

Projects on GitHub are managed using the standard [Git](https://en.wikipedia.org/wiki/Git) command-line interface.  
**Git** is a version control system that tracks file changes over time, widely used for collaborative software development.

> 📘 A great overview of Git basics and syncing is available [here](https://www.atlassian.com/git/tutorials/syncing).

---

## Working in Teams

For multi-person projects, a good practice is:
- Protecting the `main` branch
- Requiring **pull requests** for all changes
- Reviewing code before merging to main

This ensures better code quality and helps catch issues early. However, things are typically more relaxed in research codebase, so feel free to do what works for you.

👉 Set up branch protection:  
[GitHub Docs – Protected Branches](https://docs.github.com/en/enterprise-server@3.9/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches#require-linear-history)

Pull requests make it easy to:
- Compare changes
- Discuss code with inline comments
- Approve or request changes

Learn more: [GitHub Pull Requests](https://docs.github.com/en/pull-requests)

## Recommended Git Workflow (PyCharm + GitHub)

### In PyCharm

1. **Create a new branch** from `main` for your feature or task.  
2. Work on that branch, **committing regularly**.  
3. Once the feature is ready, ensure all your changes are committed.  
4. **Fetch** the latest changes from the remote `main` branch.  
5. Update your branch with `main` using **either**:
   - **Merge**: simpler, keeps full commit history  
     → Merge `main` into your branch and resolve conflicts  
   - **Rebase**: preferred for a linear commit history  
     → Rebase your branch onto `main` and resolve any conflicts  
6. **Test** your code after resolving any issues.  
7. **Push** your updated feature branch to the remote repository.


---


### On GitHub

8. Create a **pull request** from your branch to `main`.
9. Assign a reviewer.
10. Fix issues if needed (multiple review rounds are normal).
11. Once approved, **merge** the pull request.

> ✅ If linear history is enforced, GitHub will typically perform a squash-and-rebase behind the scenes (confirm in repo settings).


## Same git + github workflow from console

Great! Here's both a **visual flowchart** (described textually and exportable to an image if needed) and a **Git cheat sheet** tailored to your workflow and documentation style.

```
Start
  ↓
Create feature branch from `main`
  ↓
Work and commit regularly
  ↓
Ready to merge?
  ↓
Fetch latest `main` from remote
  ↓
┌──────────────┐
│ Choose path: │
├──────────────┤
│ Rebase       │──▶ git checkout feature
│              │    git fetch origin
│              │    git rebase origin/main
│              │    # resolve conflicts
│              │    git push --force
│              │
│ Merge        │──▶ git checkout feature
│              │    git fetch origin
│              │    git merge origin/main
│              │    # resolve conflicts
│              │    git push
└──────────────┘
  ↓
Open pull request to `main` on GitHub
  ↓
Assign reviewer
  ↓
Approve & merge
  ↓
Done ✅
```

---

### 🔁 Rebase Workflow (Preferred for Linear History)

```bash
# Work on your branch
git add .                # or specific files
git commit -m "Feature X"

# Before merging
git fetch origin
git checkout my-feature-branch
git rebase origin/main   # reapply your commits on top of latest main

# Resolve conflicts if needed
# Then:
git push --force         # force push is needed after rebase
```

### 🔀 Merge Workflow (if linear history not required)

```bash
git fetch origin
git checkout my-feature-branch
git merge origin/main    # will create a merge commit
git push                 # normal push
```

### 🔃 On GitHub

- Open a Pull Request from `my-feature-branch` → `main`
- Assign reviewer
- Use **"Rebase and merge"** or **"Squash and merge"** if linear history is required
- Done!


---

## Final Notes

There are many valid Git workflows. This one is inspired by experienced developers and tuned for clarity and maintainability.  
It’s not the only way—but it works well for some of us.

*– Not a Git guru, just sharing what’s worked.* 🙂
