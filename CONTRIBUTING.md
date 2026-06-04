# Contributing

Thanks for your interest in KBee. This project spans an algorithm oracle,
FPAA bring-up on Anadigm silicon, and an ASIC reference path + other future implementation aspirations.

## Before you start

1. Read [`docs/REPO_LAYOUT.md`](docs/REPO_LAYOUT.md) for canonical paths.
1. Check [`THIRD_PARTY.md`](THIRD_PARTY.md) — you need your own AD2 + hardware for FPAA work.
1. Run tests: `nix develop -c run-kbee-tests`
1. Format sources: `nix develop -c format-kbee`
1. Pre-push checks: `nix develop -c check-kbee` (formatting + SPDX/copyright headers)
1. Install git hooks (optional): `nix develop -c install-git-hooks` — `pre-push` runs `check-kbee`

## Pull requests

- Keep changes focused; match existing style (LF line endings, see `.gitattributes`).
- Algorithm or test changes: update `python/kbee.py` and/or regenerate refs with
  `nix develop -c gen-kbee-refs` when W=8 tables change.
- FPAA docs: follow [`docs/ad2-conventions.md`](docs/ad2-conventions.md) (Hold-before-Bypass, clocks, etc.).
- Do not commit Anadigm CHM conversions or `.hypothesis/` cache.

## Licensing

By contributing, you agree that:

- **Software** contributions are under [LGPL-3.0-or-later](LICENSE).
- **Hardware design** contributions are under [CERN-OHL-W-2.0-or-later](LICENSE-HARDWARE).
- **Documentation** contributions are under [CC BY-SA 4.0-or-later](LICENSE-DOCUMENTATION).

## Developer Certificate of Origin (DCO)

To ensure that you have the right to submit your contributions under the project's licenses, we enforce the [Developer Certificate of Origin (DCO)](https://developercertificate.org/).

All **new** commits (from the first external contribution onward) must include a
`Signed-off-by` line indicating your agreement to the DCO. Initial import history
on `main` predates this policy. You can add the line automatically with the
`-s` or `--signoff` flag:

```bash
git commit -s -m "Your commit message"
```

## Questions

- [Issues](https://codeberg.org/Karoshibee/kbee/issues) — bugs and design questions.
- [SECURITY.md](SECURITY.md) — how to report security-sensitive findings.
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) — community standards.
