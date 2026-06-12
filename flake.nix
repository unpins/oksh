{
  description = "oksh (the portable OpenBSD Korn Shell) as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # oksh (the portable OpenBSD ksh, based on the Public Domain Korn Shell) as a
  # single self-contained static binary. Like mksh it has no module system, no
  # autoloaded function tree, and uses no NLS catalogs (no catgets segfault) —
  # but unlike mksh it uses ncurses for terminal handling, so stock
  # pkgsStatic.oksh reads host /usr/share/terminfo at runtime (and keeps a
  # /nix/store ref to it). The only delta vs nixpkgs is therefore:
  #
  #   - embedFallbackTerminfo on ncurses: bakes a curated terminfo fallback so
  #     the line editor works with no /usr/share/terminfo on the host (strace
  #     shows zero /nix/store reads at runtime). Same fix tcsh/dash/nano use.
  #
  # The man-page embed and the Windows/Cosmopolitan build are handled by
  # mkStandaloneFlake and cosmo.nix respectively.
  #
  # Targets:
  #   - Linux (static-musl, every arch).
  #   - macOS (Mach-O, libSystem-only).
  #   - Windows (Cosmopolitan APE): see cosmo.nix.
  outputs = { self, unpins-lib }:
    let
      okshBase = pkgs:
        let
          p = pkgs.pkgsStatic;
          ncursesFB = unpins-lib.lib.embedFallbackTerminfo p.ncurses;
        in
        p.oksh.override { ncurses = ncursesFB; };
    in
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "oksh";
      license = "Public Domain";

      # oksh has -c; exercise the interpreter and a builtin to confirm argv
      # parsing on every ABI (incl. the cosmo APE).
      smoke = [ "-c" "echo unpins-smoke-ok" ];
      smokePattern = "unpins-smoke-ok";

      windowsBuild = import ./cosmo.nix { inherit unpins-lib; };

      build = pkgs: okshBase pkgs;
    };
}
