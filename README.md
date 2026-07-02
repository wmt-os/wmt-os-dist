# WMT OS Packages

External packages and the publisher for the [WMT OS](https://github.com/wmt-os/wmt-os) APT repository at [apt.wmt-os.org](https://apt.wmt-os.org/).

The core build system produces the internal packages (kernel, metapackage, `wmt-boot`, `wmt-os-base`). This repository carries everything else the archive ships, plus `publish-deb.sh`, the one tool that touches it. Each package directory is self-contained, with its own `build-deb.sh`. Projects like [xf86-video-wmt](https://github.com/lrussell887/xf86-video-wmt) build in their own repositories and publish here by path.

## Versioning

The name carries identity, the version carries ordering:

| Class | Version |
| :--- | :--- |
| Internal, auto-built | `<stamp>+<12-hex content key>` |
| Shadow of a Debian package | `<Debian version>+wmtosN` |
| Backport of a newer upstream | `<new version>-1~wmtosN` |
| Own upstream (`xf86-video-wmt`) | its own `x.y.z` |

Devices pin the archive at priority 1001 so our packages always take precedence over Debian.

## Publishing

```sh
./publish-deb.sh path/to/*.deb    # gate and publish
./publish-deb.sh                  # reindex and sign; never removes anything
```

Stateless: the published pool is the only ledger, delta-synced into `mirror/` each run. Content-addressed names skip when already published and are garbage-collected once nothing depends on them; content-keyed versions skip when the key matches the current version; anything else must be strictly newer. Older or dirty input aborts the whole run untouched. Superseded versions are pruned.

Requires: `apt-utils dpkg gnupg rsync`, and the signing key (`KEYID` in `config.sh`) in gpg.
