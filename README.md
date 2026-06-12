# oksh

[oksh](https://github.com/ibara/oksh) — a portable build of the OpenBSD Korn
Shell (`ksh`), itself based on the Public Domain Korn Shell (pdksh). A small,
fast, POSIX-ish shell with a command-line editor, vi/emacs editing modes,
arrays, and job control. A single self-contained binary, built natively for
Linux, macOS, and Windows.

[![CI](https://github.com/unpins/oksh/actions/workflows/oksh.yml/badge.svg)](https://github.com/unpins/oksh/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install oksh`.

## Usage

Run `oksh` with [unpin](https://github.com/unpins/unpin):

```bash
unpin oksh                        # start an interactive shell
unpin oksh script.ksh             # run a script
unpin oksh -c 'echo hello'
```

To install it onto your PATH:

```bash
unpin install oksh
```

oksh is a Korn shell, so the usual ksh features work out of the box — arrays,
`typeset`, arithmetic `$(( ))`, and the `print` builtin:

```ksh
set -A fruit apple banana cherry
echo ${fruit[1]} ${#fruit[*]}     # banana 3
typeset -i n=6; echo $((n * 7))   # 42
```

## Man pages

The oksh manual (`oksh.1`) is embedded, so `unpin man oksh` works offline.

## Build locally

```bash
nix build github:unpins/oksh
./result/bin/oksh -c 'echo hello from oksh'
```

Or run directly:

```bash
nix run github:unpins/oksh -- -c 'echo hello from oksh'
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/oksh/releases) page has standalone binaries for manual download.

## Build notes

- **Self-contained, no data files.** Like mksh, oksh has no module system and no
  autoloaded-function tree. It does use ncurses for terminal handling, so the
  binary carries a curated terminfo fallback (`embedFallbackTerminfo`): the
  command-line editor works with no `/usr/share/terminfo` on the host, and
  `strace` shows zero `/nix/store` reads at runtime. macOS links only
  `libSystem` (`otool -L` confirms).

- **Static linking, every target.** Linux is static-musl on every architecture.

- **Windows via Cosmopolitan.** mingw can't host a Korn shell (no `fork`, job
  control, or POSIX signals), so the Windows binary is built with `cosmocc` into
  an APE PE32+. oksh's portability layer (`portable.h`) dispatches on the host
  OS and had never heard of Cosmopolitan, so it was falling through to BSD
  fallbacks that reference constants cosmo lacks. Since cosmo's libc is
  deliberately Linux/glibc-shaped, the fix enrolls it in the existing `__linux__`
  profile (one extra `defined(__COSMOPOLITAN__)`), plus a small guard so the
  `O_EXLOCK` fallback doesn't collide with cosmo's real declaration. See
  `cosmo.nix`.
