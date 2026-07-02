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
  # but unlike mksh it uses ncurses for terminal handling. The curated
  # fallback-terminfo (so the line editor works with no host /usr/share/terminfo
  # and keeps no /nix/store ref) is baked centrally into every engine ncurses by
  # native-overlay/ncurses.nix, so pkgsStatic.ncurses already carries it — no
  # per-package override here (same for tcsh/dash/nano).
  #
  # The man-page embed and the Windows/Cosmopolitan build are handled by
  # mkStandaloneFlake and cosmo.nix respectively.
  #
  # Targets:
  #   - Linux (static-musl, every arch).
  #   - macOS (Mach-O, libSystem-only).
  #   - Windows (single PE .exe, built via Cosmopolitan): see cosmo.nix.
  outputs = { self, unpins-lib }:
    let
      # Fallback terminfo is baked centrally for every engine ncurses, linux +
      # darwin (native-overlay/ncurses.nix), so p.ncurses already carries it.
      okshBase = pkgs:
        let p = pkgs.pkgsStatic;
        in p.oksh.override { ncurses = p.ncurses; };
    in
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "oksh";

      # Build via the unpin-llvm engine + emit a bitcode multicall module.
      engine = "unpin-llvm";
      multicall = {
        programs = [{ name = "oksh"; }];
      };
      license = "Public Domain";

      # oksh has -c; exercise the interpreter and a builtin to confirm argv
      # parsing on every ABI (incl. the cosmo PE).
      smoke = [ "-c" "echo unpins-smoke-ok" ];
      smokePattern = "unpins-smoke-ok";

      windowsBuild = import ./cosmo.nix { inherit unpins-lib; };

      build = pkgs: okshBase pkgs;
    };
}
