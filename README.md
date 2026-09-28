# setup-skillspector

[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/14995/badge)](https://www.bestpractices.dev/projects/14995)

A GitHub Action that installs [NVIDIA SkillSpector](https://github.com/NVIDIA/skillspector) and scans the agent skills in your repository on every push and pull request.

- **One skill or many.** Point it at a skill, or at a directory of skills. Each skill is scanned on its own, so your baseline file still applies.
- **No token, no key.** The action asks for no permissions and no secrets. It runs static analysis unless you turn LLM analysis on.
- **66 packages hash-locked.** SkillSpector 2.12.0 and its 65 dependencies install from a lockfile, wheels only, every hash checked. The upstream install command leaves the dependencies unpinned.
- **Dependabot updates it.** A SkillSpector upgrade arrives as a bump of this action. A `uv tool install git+…@<sha>` line in a workflow is invisible to Dependabot.
- **Linux, macOS, and Windows** GitHub-hosted runners.

There is nothing to install. Add this job to a workflow, for example `.github/workflows/skills.yml`:

```yaml
jobs:
  skillspector:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: svyatov/setup-skillspector@v1
```

The job fails when a skill in `skills/` scores above 50, SkillSpector's `DO NOT INSTALL` threshold. Each skill's report appears in the job log and in the run summary, and a failing skill gets an annotation:

```text
Error: tests/fixtures/fail/risky failed the scan (exit 1)
```

> [!IMPORTANT]
> Pin the action to the full commit SHA of a release, with the tag in a comment: `svyatov/setup-skillspector@<sha> # v1.0.0`. Dependabot still updates a pinned SHA, and a tag can be moved.

## Before and after

The job this action replaces, as it stands in a repository that ships skills:

```yaml
steps:
  - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
  - uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
  - run: uv tool install git+https://github.com/NVIDIA/skillspector.git@89e90872e2ec813bcb137bf6b3145c92e55811ae
  - run: |
      status=0
      for skill in skills/*/; do
        echo "::group::$skill"
        skillspector scan "$skill" --no-llm --format json --baseline .skillspector-baseline.yaml || { echo "::error::skillspector failed on $skill"; status=1; }
        echo "::endgroup::"
      done
      exit "$status"
```

The same job with the action:

```yaml
steps:
  - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
    with:
      persist-credentials: false
  - uses: svyatov/setup-skillspector@v1
```

## Inputs

| Input | Default | What it does |
|---|---|---|
| `path` | `skills` | A skill directory (holds `SKILL.md`), or a directory whose immediate subdirectories are skills. |
| `baseline` | `.skillspector-baseline.yaml` | Baseline of suppressed findings. The default is used only when the file exists; any other value must exist. |
| `llm` | `false` | Run LLM analysis. See [LLM analysis](#llm-analysis). |
| `fail-on-findings` | `false` | Fail on any active finding, not only on a risk score above 50. |
| `fail-on-incomplete` | `false` | Fail when any analysis is partial or incomplete. |
| `scan` | `true` | Set to `false` to only install. `skillspector` stays on `PATH` for later steps. |

## Outputs

| Output | What it holds |
|---|---|
| `version` | The installed SkillSpector version, for example `2.12.0`. |
| `report-dir` | Directory with one Markdown report per scanned skill, named `<skill>.md`. |

## Baseline

A baseline suppresses findings you have reviewed and accepted. Because each skill is scanned on its own, every `path` in a baseline rule is relative to one skill's directory, and one baseline file at the repository root serves all skills.

Generate a starting baseline for one skill, then review every rule and give it a real `reason`:

```bash
skillspector baseline skills/my-skill --no-llm -o .skillspector-baseline.yaml
```

The file format is documented upstream in [`docs/SUPPRESSION.md`](https://github.com/NVIDIA/skillspector/blob/main/docs/SUPPRESSION.md).

## LLM analysis

With `llm: true`, SkillSpector sends the contents of each skill to an LLM provider. Set the provider and its key as `env` on the step, never as inputs:

```yaml
- uses: svyatov/setup-skillspector@v1
  with:
    llm: true
    fail-on-incomplete: true
  env:
    SKILLSPECTOR_PROVIDER: anthropic
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

Without a key, SkillSpector falls back to static analysis and marks the scan partial. Secrets are not available to pull requests from forks, so `fail-on-incomplete: true` fails those. The providers and their variables are listed in the [SkillSpector README](https://github.com/NVIDIA/skillspector#readme).

## Other commands

To run SkillSpector yourself, install it without scanning and call it in a later step:

```yaml
- uses: svyatov/setup-skillspector@v1
  with:
    scan: false
- run: skillspector scan skills/my-skill --no-llm --format sarif --output skillspector.sarif
```

## Versions

Each release of this action installs exactly one SkillSpector version, recorded in [CHANGELOG.md](CHANGELOG.md). A SkillSpector upgrade can add findings, so it ships as a minor release.

## Help

Ask a question or report a defect in [GitHub issues](https://github.com/svyatov/setup-skillspector/issues). Report a vulnerability privately, as described in [SECURITY.md](SECURITY.md). A problem with a finding itself belongs [upstream](https://github.com/NVIDIA/skillspector/issues).

The action is maintained, and it follows SkillSpector releases.

## License

[MIT](LICENSE). SkillSpector itself is Apache-2.0. See [CONTRIBUTING.md](CONTRIBUTING.md) to work on the action.
