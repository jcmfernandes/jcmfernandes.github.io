{ pkgs, config, ... }:

let
  emacs = "emacs -Q --batch";
in
{
  packages = [
    pkgs.emacs-nox
    pkgs.pandoc
    pkgs.git
    pkgs.jq
    pkgs.watchexec
    pkgs.python3
    pkgs.imagemagick
  ];

  # Install pinned Emacs packages. Skipped when the lockfile hasn't changed
  # since the last thaw.
  tasks."site:deps" = {
    cwd = config.devenv.root;
    exec = "${emacs} -l lisp/site-init.el -f site-deps";
    status = "test -f straight/.thawed && cmp -s straight/versions/default.el straight/.thawed";
  };

  tasks."site:test" = {
    cwd = config.devenv.root;
    after = [ "site:deps" ];
    exec = "${emacs} -l test/run.el";
  };

  tasks."site:build" = {
    cwd = config.devenv.root;
    after = [ "site:deps" ];
    input = { drafts = false; };
    exec = ''
      SITE_DRAFTS=$(echo "$DEVENV_TASK_INPUT" | jq -r '.drafts') ${emacs} -l lisp/site-build.el -f site-build
    '';
  };

  # Regenerate static/logo.webp and static/favicon.png from the ASCII art in
  # templates/logo.txt and templates/favicon.txt.
  tasks."site:logo" = {
    cwd = config.devenv.root;
    exec = ''
      export LOGO_FONT=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSansMono.ttf
      bin/make-logo logo templates/logo.txt static/logo.webp \
        "[ SINCE NINETEEN EIGHTY SEVEN : JOÃO MOREIRA FERNANDES ]"
      bin/make-logo icon templates/favicon.txt static/favicon.png
    '';
  };

  # Serve public/ on localhost:8000 and rebuild on change. Ctrl-C stops both.
  tasks."site:preview" = {
    cwd = config.devenv.root;
    after = [ "site:deps" ];
    exec = ''
      export SITE_BASE_URL=http://localhost:8000
      mkdir -p public
      python3 -m http.server --directory public --bind 127.0.0.1 8000 &
      server=$!
      trap 'kill $server' EXIT
      # Watch the whole repo, not individual dirs: a dir that gets deleted and
      # re-created (e.g. by a git checkout) would silently drop its watch.
      # Git-ignored paths (straight/, .devenv/) don't trigger rebuilds. public/
      # is ignored explicitly: once deleted, `/public/' (dirs only) no longer
      # matches it, and its removal would trigger another build.
      watchexec --watch . --ignore public -- ${emacs} -l lisp/site-build.el -f site-build
    '';
  };
}
