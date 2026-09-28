# Contributing

Open an issue before a large change, so we can agree on the approach first. Everyone taking part follows the [code of conduct](CODE_OF_CONDUCT.md).

## Pull requests

1. Fork the repository and create a branch named `type/short-description`, for example `fix/windows-path`.
2. Make the change. A change that adds functionality arrives with a test: a fixture under `tests/fixtures/` and a step in the `test` job of `.github/workflows/ci.yml` that proves it.
3. Changes to `action.yml`, `scan.sh`, or a workflow follow GitHub's [secure use reference](https://docs.github.com/en/actions/reference/security/secure-use). CI enforces it with zizmor, actionlint, and shellcheck.
4. Open a pull request against `main` and fill in the template. It merges by squash once CI passes and the maintainer approves.

## Checks

You need [uv](https://docs.astral.sh/uv/), shellcheck, and Docker. CI runs these on every pull request. Run them locally before you push:

```bash
shellcheck scan.sh
uvx zizmor@1.30.1 .
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.12
```

To run the scan script against the fixtures, install SkillSpector from the lockfile first:

```bash
venv=$(mktemp -d)/venv
uv venv --no-config --python 3.13 "$venv"
uv pip install --no-config --require-hashes --no-build --python "$venv" -r requirements.txt
PATH="$venv/bin:$PATH" INPUT_PATH=tests/fixtures/pass bash scan.sh   # exits 0
PATH="$venv/bin:$PATH" INPUT_PATH=tests/fixtures/fail bash scan.sh   # exits 1
```

## Updating SkillSpector

SkillSpector is not on PyPI, so the lockfile installs the wheel attached to its GitHub release.

1. In `requirements.in`, change both version numbers in the wheel URL.
2. Rerun the `uv pip compile` command recorded at the top of `requirements.txt`. Set `--exclude-newer` to the day after the SkillSpector release, so dependencies resolve as they stood when it shipped.
3. Confirm the `skillspector @` line in `requirements.txt` carries the same sha256 as the release asset: `gh release view vX.Y.Z -R NVIDIA/skillspector --json assets --jq '.assets[].digest'`.
4. Add a CHANGELOG entry. A SkillSpector upgrade can add findings to a scan that passed before, so it ships as a minor release of this action.

## Releasing

Release immutability is enabled, so a published release and its tag never change.

1. Move the `[Unreleased]` entries in `CHANGELOG.md` under the new version and merge that to `main`.
2. Publish a GitHub release named and tagged `vX.Y.Z` from `main`.
3. Move the major tag, which has no release of its own: `git tag -f -a -m v1 v1 vX.Y.Z && git push -f origin v1`.

Commits and pull request titles follow [Conventional Commits](https://www.conventionalcommits.org/).

## Governance

One maintainer, Leonid Svyatov, decides what goes into the action and publishes every release. Decisions happen in the open, in issues and pull requests. Only the maintainer has write access, so every contribution arrives as a pull request from a fork.

No succession is arranged. If the maintainer stops, nobody else holds write access, and no organization owns the repository. The MIT license lets anyone fork the action and carry on.
