# AGENTS.md

Personal site (https://joao.moreirafernandes.com), Phrack-styled, built by a small Emacs Lisp static site generator.
Tools come from devenv (`devenv.nix`); outside `devenv shell`, `emacs` may not be the right binary.

## Commands

```sh
devenv tasks run site:test                       # all ERT tests
devenv tasks run site:build                      # build into public/
devenv tasks run site:build --input drafts=true  # include drafts
devenv tasks run site:preview                    # http://localhost:8000, rebuilds and live-reloads on change
devenv tasks run site:logo                       # regenerate static/logo.webp and static/favicon.png

# One test (or a regexp of test names):
devenv shell -- emacs -Q --batch -l test/site-build-test.el -l test/site-content-test.el \
  --eval '(ert-run-tests-batch-and-exit "site-parse-date")'
```

`site:deps` runs first and installs the pinned Emacs packages (esxml, htmlize) into `straight/` via straight.el. Pins
live in `straight/versions/default.el`; the task is skipped while that file matches `straight/.thawed`.

## Architecture

Pipeline, driven by `site-build-site` in `lisp/site-build.el`:

1. `site-load-config` loads `site.el` (title, author, base URL, repo URL, Babel languages). `SITE_BASE_URL` overrides
   the base URL; `SITE_LIVE_RELOAD=1` enables live reload.
2. `site-collect` reads `content/`: `index.{org,md}` is the home intro, other top-level files are pages,
   `content/posts/` holds posts. Drafts are dropped unless requested. Duplicate URLs are an error.
3. `lisp/site-content.el` reads metadata and renders bodies:
   - Org: `#+TITLE`, `#+DATE`, `#+FILETAGS`, `#+DRAFT`; exported with ox-html. Babel blocks in `site-babel-languages`
     run at build time.
   - Markdown: front matter `title`, `date`, `tags`, `draft`, extracted with pandoc via `lisp/pandoc-meta.tpl`;
     rendered by pandoc with `lisp/alerts.lua`, which turns GitHub alerts (`> [!NOTE]`) into the same divs as Org
     special blocks (`#+begin_note`).
   - Slug = file name minus an optional `YYYY-MM-DD-` prefix. Slugs and tags must match `[a-z0-9-]+`; they become
     directories (`/posts/<slug>/`, `/tags/<tag>/`).
4. `templates/*.el` define `tpl-*` functions returning esxml; `tpl-base` is the shared page shell (nav, logo,
   footer with a link to the built commit).
5. Everything is rendered in memory before `public/` is replaced, so a failing build keeps the previous output.
   `static/` is copied over as-is; `style.css` is linked with a content-hash `?v=` for cache busting.

Tests use `test/fixture/` as a sample site and `site-test--tree` for throwaway trees.

## Deploy

Pushing to `main` runs `.github/workflows/pages.yml`: builds with devenv and deploys to GitHub Pages
(repo `jcmfernandes/jcmfernandes.github.io`, custom domain via a CNAME managed elsewhere). The workflow caches the Nix
store, `~/.cache/nix` and `straight/`, and installs devenv from the nixpkgs revision pinned in `devenv.lock`.
