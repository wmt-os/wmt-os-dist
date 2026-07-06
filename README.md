# WMT OS Packages

External packages and publisher for the [WMT OS](https://github.com/wmt-os/wmt-os) APT repository at [apt.wmt-os.org](https://apt.wmt-os.org/).

The core build system produces the internal packages (kernel, metapackage, `wmt-boot`, `wmt-os-base`). This repository carries additional external packages, plus `publish-deb.sh`, which is the APT repository publishing tool. Each package directory is self-contained, with its own `build-deb.sh`.

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

Requires `apt-utils dpkg gnupg rsync`, and the signing key (`KEYID` in `config.sh`) in gpg.

```bash
./publish-deb.sh path/to/*.deb    # Validate and publish
./publish-deb.sh                  # Reindex and sign (non-destructive / initialize empty repo)
```

The publisher is stateless: the published pool is the authority, delta-synced into `mirror/` each run. Content-addressed names skip when already published and are garbage-collected once nothing depends on them; content-keyed versions skip when the key matches the current version; anything else must be strictly newer. Older or dirty input aborts the whole run untouched. Superseded versions are pruned.
