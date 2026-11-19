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
      watchexec --watch content --watch static --watch templates --watch lisp --watch site.el \
        -- ${emacs} -l lisp/site-build.el -f site-build
    '';
  };
}
