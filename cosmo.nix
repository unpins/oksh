# oksh via cosmoStaticCross (= pkgs.pkgsCross.cosmo) for Windows-x86_64.
#
# cosmocc backs fork/job-control/signals, which a Korn shell needs and mingw
# cannot provide. The cosmo cross stdenv auto-apelinks $out/bin/* (ELF -> PE32+,
# rename to <name>.exe) in fixupPhase.
#
# oksh's configure is a hand-written probe script (not autoconf) that compiles
# and *runs* a conftest. nixpkgs already neutralizes that for cross builds
# (substituteInPlace configure --replace "./conftest" "echo"), and cosmo is a
# cross stdenv, so the probe is skipped and configure falls back to its portable
# defaults — which is exactly what we want on the cosmo target.
{ unpins-lib }:
pkgs:
let
  cosmoPkgs = unpins-lib.lib.cosmoStaticCross pkgs;
in
cosmoPkgs.oksh.overrideAttrs (oa: {
  # oksh's portable.h is a per-OS dispatch: each block is gated on platform
  # macros (__linux__, __APPLE__, __NetBSD__, ...). cosmo is a new platform it
  # has never heard of, so it matches none of the branches and falls through to
  # BSD-flavored `#else` arms that reference constants cosmo lacks (e.g.
  # _PW_NAME_LEN := MAXLOGNAME, undeclared). cosmo's libc, however, is
  # deliberately Linux/glibc-shaped (it provides LOGIN_NAME_MAX, the same system
  # headers, etc.), so the right fix is to enroll cosmo in the existing __linux__
  # profile rather than invent a new one. That single change also resolves the
  # earlier edit.c `u_char` parse error: the __linux__ include block pulls in
  # <sys/types.h>, which the line editor relies on transitively.
  #
  # Separately, portable.h's `#ifndef O_EXLOCK / #define O_EXLOCK 0` fallback
  # still misfires on cosmo: cosmo provides O_EXLOCK as `extern const unsigned`
  # (not a macro), so the `#ifndef` can't see it. Defining the macro then poisons
  # cosmo's own declaration (`extern const unsigned 0;`). Skip that fallback on
  # cosmo and keep the real symbol.
  postPatch = (oa.postPatch or "") + ''
    substituteInPlace portable.h \
      --replace-fail 'defined(__linux__) || defined(__CYGWIN__)' \
                     'defined(__linux__) || defined(__COSMOPOLITAN__) || defined(__CYGWIN__)' \
      --replace-fail '#ifndef O_EXLOCK' \
                     '#if !defined(O_EXLOCK) && !defined(__COSMOPOLITAN__)'
  '';
})
