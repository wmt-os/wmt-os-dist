# WMT OS Dist

Publishing tools and external packages for [WMT OS](https://wmt-os.org/).

* APT repository: [apt.wmt-os.org](https://apt.wmt-os.org/)
* Disk images: [releases.wmt-os.org](https://releases.wmt-os.org/)

The publishing tools are `publish-deb.sh` for packages and `publish-img.sh` for disk images. External packages live under `packages/`, each built by `build-deb.sh` from its `conf`, either by rebuilding a Debian source package or by packaging an upstream release that carries its own `debian/`. The internal packages (kernel, metapackage, `wmt-boot`, `wmt-os-base`, `wmt-platform-wm8505`) come from the core build system instead. `check-deb.sh` compares the published rebuilds against Debian's current versions.

## Versioning

Package names establish identity, and versions decide upgrade order:

| Package class | Version format |
| :--- | :--- |
| Kernel image (`-<12-hex content id>` in name) | `<stamp>` |
| Other internal, auto-built | `<stamp>+<12-hex content key>` |
| Shadow of Debian package | `<Debian version>+wmtosN` |
| Backport of newer upstream | `<new version>-1~wmtosN` |
| Own upstream (like `xf86-video-wmt`) | `<upstream version>-N` |

The `+wmtosN` marker sits ahead of any `+debXuY` extension, keeping rebuilds against Debian security updates newer than what they replace. Devices pin the archive at priority 990 so our packages always take precedence over Debian.

## Publishing

### APT repository (`publish-deb.sh`)

Requires: `apt-utils dpkg gnupg rsync` and the signing key (`KEYID` in `config.sh`) in gpg.

```bash
./publish-deb.sh path/to/*.deb    # Validate and publish
./publish-deb.sh                  # Reindex and sign (non-destructive)
```

The remote archive is the authority, and each run syncs it into `mirror/` first. Kernels are named by content, so an already published kernel is skipped, and one that nothing depends on is deleted. A package whose version carries a content key is skipped when the key matches the published version. Anything else must be strictly newer to publish, and an older or dirty build aborts the whole run before the archive is touched. Superseded versions are pruned, and a run with no arguments reindexes and signs the repository.

### Disk images (`publish-img.sh`)

Requires: `rsync`

```bash
./publish-img.sh path/to/*.img.xz    # Validate and publish (including .sha256)
```

The image publisher lists the site rather than mirroring it, and only new images transfer. Each image is published with its `.sha256` from the build, checked for the right name. Published names are immutable, so an identical republish is skipped and a differing one aborts the whole run before anything transfers. Nothing is ever pruned, so deletion is manual.

## License

MIT - see [LICENSE.md](LICENSE.md).
