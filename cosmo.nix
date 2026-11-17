# oksh via cosmoStaticCross (= pkgs.pkgsCross.cosmo) for Windows-x86_64.
#
# cosmocc backs fork/job-control/signals, which a Korn shell needs and mingw
# cannot provide. The cosmo cross stdenv auto-apelinks $out/bin/* (ELF -> PE32+,
# rename to <name>.exe) in fixupPhase.
#
# oksh's hand-written configure runs a conftest only in its compiler check, which
# nixpkgs neutralizes for cross; the feature probes compile and link, so they work.
{ unpins-lib }:
pkgs:
let
  cosmoPkgs = unpins-lib.lib.cosmoStaticCross pkgs;
in
cosmoPkgs.oksh.overrideAttrs (oa: {
  patches = (oa.patches or [ ]) ++ [
    # Enroll cosmo in portable.h's __linux__ profile (see the patch header).
    ./portable-h-cosmo.patch
    # Windows command lookup: catalog programs install as `<name>.exe`
    # (cmd.exe/PowerShell find them via PATHEXT), but Cosmopolitan does not
    # append an executable suffix during path resolution, so a bare `ls` typed
    # at the oksh prompt never resolves. The patch makes oksh's PATH search
    # retry a missing candidate with `.exe`, keeping a single on-disk name.
    # Only applied here (cosmo build).
    ./findcmd-exe-lookup.patch
  ];
})
