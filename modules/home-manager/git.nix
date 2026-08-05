{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      branch.sort = "-committerdate";

      commit.verbose = true;

      "color \"diff\"" = {
        oldMoved = 201;
        newMoved = "magenta";
      };

      core.excludesFile = "~/.config/git/ignore";

      delta = {
        line-numbers = true;
        navigate = true;
        keep-plus-minus-markers = true;
        file-style = "yellow bold";
        file-decoration-style = "white ul";
        hyperlinks = true;
      };

      diff = {
        algorithm = "histogram";
        mnemonicPrefix = true;
        renames = true;
        colorMoved = "default";
        colorMovedWS = "allow-indentation-change";
      };

      fetch = {
        prune = true;
        pruneTags = true;
        tags = true;
      };

      init.defaultBranch = "master";

      interactive.singleKey = true;

      push = {
        autoSetupRemote = true;
        followTags = true;
      };

      pull.rebase = true;

      rebase.autoStash = true;

      status = {
        branch = true;
        showStash = true;
        showUntrackedFiles = "all";
      };

      tag.sort = "-taggerdate";

      "url \"git@github.com:\"" = {
        insteadOf = "gh:";
      };
    };
  };

  xdg.configFile."git/ignore".text = "";
}
