# WMT OS Dist

Publishing tools and external packages for [WMT OS](https://github.com/wmt-os/wmt-os).

* APT repository: [apt.wmt-os.org](https://apt.wmt-os.org/)
* Disk images: [releases.wmt-os.org](https://releases.wmt-os.org/)

The core build system produces the internal packages (kernel, metapackage, `wmt-boot`, `wmt-os-base`). This repository carries `publish-deb.sh` and `publish-img.sh`, the APT repository and disk image publishers, plus external packages under `packages/`. Each package directory is self-contained, with its own `build-deb.sh`.

## Versioning

Package names establish identity, while version numbers dictate upgrade ordering:

| Package class | Version format |
| :--- | :--- |
| Kernel image (`-<12-hex content id>` in name) | `<stamp>` |
| Other internal, auto-built | `<stamp>+<12-hex content key>` |
| Shadow of Debian package | `<Debian version>+wmtosN` |
| Backport of newer upstream | `<new version>-1~wmtosN` |
| Own upstream (like `xf86-video-wmt`) | its own `x.y.z` |

Devices pin the archive at priority 1001 so our packages always take precedence over Debian.

## Publishing

### APT repository (`publish-deb.sh`)

Requires: `apt-utils dpkg gnupg rsync`, and the signing key (`KEYID` in `config.sh`) in gpg.

```bash
./publish-deb.sh path/to/*.deb    # Validate and publish
./publish-deb.sh                  # Reindex and sign (non-destructive / initialize empty)
```

The published pool is the authority, delta-synced into `mirror/` each run. Content-addressed names skip when already published and are garbage-collected once nothing depends on them; content-keyed versions skip when the key matches the current version; anything else must be strictly newer. Older or dirty input aborts the whole run untouched. Superseded versions are pruned, and a no-argument run reindexes the repository.

### Disk images (`publish-img.sh`)

Requires: `rsync`

```bash
./publish-img.sh path/to/*.img.xz    # Validate and publish (including .sha256)
./publish-img.sh                     # Relink latest (non-destructive / initialize empty)
```

The published site is the authority, listed rather than mirrored, and only new images transfer. Images publish alongside their `.sha256` from the build, checked and carried verbatim. Published names are immutable; an identical republish is skipped, and a differing one aborts the whole run untouched. `latest/` holds a symlink per image name, datestamp stripped, pointing at the newest. Nothing is pruned; deletion is manual, and a no-argument run relinks `latest`.
