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
}
