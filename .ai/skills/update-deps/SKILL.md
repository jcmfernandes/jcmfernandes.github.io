---
name: update-deps
description: Update the pinned Nix (devenv.lock) and Emacs (straight/versions/default.el) dependencies and report what changed.
disable-model-invocation: true
---

Dependabot covers the GitHub Actions; this covers what it can't: nixpkgs (`devenv.lock`) and the Emacs packages pinned
by straight.el (`straight/versions/default.el`). Run every command from the repo root.

## Steps

1. **Baseline.** The working tree must be clean; otherwise stop and report. Create a scratch dir with `mktemp -d` and
   substitute its path for `$WORK` in every command below; a shell variable may not survive between commands. Record
   the tool versions and a build to compare against:

   ```sh
   devenv shell -- sh -c 'emacs --version | head -1; pandoc --version | head -1' > "$WORK/before-versions"
   nix eval --raw "github:NixOS/nixpkgs/$(jq -r '.nodes["nixpkgs-src"].locked.rev' devenv.lock)#devenv.version" >> "$WORK/before-versions"
   devenv tasks run site:build && cp -r public "$WORK/before"
   ```

2. **Nix.** `devenv update`, then record the versions again (same two commands) into `$WORK/after-versions`. The
   devenv version is the one CI installs.

3. **Emacs packages.**

   ```sh
   devenv shell -- emacs -Q --batch -l lisp/site-init.el --eval '(progn (straight-pull-all) (straight-freeze-versions))'
   ```

   `site:deps` notices the changed lockfile and rebuilds the packages on the next task run.

4. **Verify.** `devenv tasks run site:test` is green and `devenv tasks run site:build` succeeds. Then
   `diff -r "$WORK/before" public`: every difference in the generated HTML is explained by a specific update (an Org
   or pandoc release changing markup, say). Run `devenv tasks run site:preview` and check a changed page when a
   difference affects how a page looks.

5. **Report**, per lockfile: old → new revision (`git diff devenv.lock straight/versions/default.el`), the version
   changes from `before-versions`/`after-versions`, test and build results, and each HTML difference with its cause.
   An unchanged lockfile is reported as up to date. Then wait for the go-ahead to commit.

## Committing

One commit per lockfile, titled `build: update nixpkgs` or `build: update Emacs packages`, the body listing the version
changes. A `devenv.lock` change also starts a new Nix cache in CI, so the first deploy after it is slower.
