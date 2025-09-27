# action_stay_or_go GitHub Action

`action_stay_or_go` is a Docker-based custom action that runs the stay_or_go CLI in GitHub Actions to analyze Go and Ruby dependencies and emit a score report. It is designed for teams that want to automate dependency health checks as part of CI.

## Key Features
- Detects Go (`go.mod`) and Ruby (`Gemfile`) dependency manifests and scores their popularity and maintenance health
- Fails the job when any dependency falls below the configured threshold (`min_score`), surfacing risk early
- Ships as a Docker image so you always get the same runtime environment and results

## Quick Start
```yaml
name: stay-or-go
on:
  pull_request:
  push:

jobs:
  dependency-health:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: Run stay_or_go
        uses: konyu/action-stay-or-go@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          mode: go
          min_score: "70"
          output_path: reports/stay_or_go.tsv
      - name: Upload report
        uses: actions/upload-artifact@v4
        with:
          name: stay-or-go-report
          path: reports/stay_or_go.tsv
```
`mode` accepts `go` or `ruby`. If you need to analyze both ecosystems, add separate steps or jobs for each.

## Required Permissions
- Provide `github_token` as `secrets.GITHUB_TOKEN` or a PAT that grants `read:packages` (and other required scopes). stay_or_go queries the GitHub API to collect dependency insights.

## Inputs
| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `github_token` | ✅ | – | Token used for GitHub API calls. Passed to stay_or_go via the `-g` flag or `GITHUB_TOKEN` environment variable. |
| `mode` | ✅ | `go` | Target ecosystem to analyze. Use `go` or `ruby`. |
| `input_path` | – | empty | Explicit path to the file you want to analyze (e.g., `Gemfile`). Auto-detected when omitted. |
| `config_path` | – | empty | Path to a YAML configuration file that tweaks scoring weights. |
| `verbose` | – | `false` | Enables verbose logging. |
| `workdir` | – | `.` | Working directory in which stay_or_go runs. Useful for monorepos. |
| `output_path` | – | `stay_or_go_report.tsv` | Relative path for the generated TSV report. |
| `min_score` | ✅ | – | Minimum acceptable score. The action fails if any dependency scores below this value. |

## Outputs
| Name | Description |
| --- | --- |
| `report_path` | Path to the generated report file, available for upload or further processing. |

## Advanced Usage
- Ruby project with a custom configuration
  ```yaml
  - name: stay_or_go for Ruby
    uses: konyu/action-stay-or-go@v1
    with:
      github_token: ${{ secrets.GITHUB_TOKEN }}
      mode: ruby
      input_path: Gemfile
      config_path: .github/stay_or_go.yml
      min_score: "65"
  ```
- To share the report in a pull request comment, consume `report_path`, convert it to Markdown, and post via `actions/github-script` (or your preferred method).

## Local Testing
- If Docker is available, build the image locally and run `entrypoint.sh` with the same arguments used in GitHub Actions to validate behavior.
- To rehearse the full workflow, run it locally with [nektos/act](https://github.com/nektos/act). Remember to supply the required secrets and environment variables.

## Publishing the GitHub Action

The container image for `action_stay_or_go` is published automatically by the `publish.yml` workflow.

1. Create a semantic version tag on the main branch (for example `git tag v1.2.3`).
2. Push the tag to GitHub with `git push origin v1.2.3`.
3. GitHub Actions builds the image and pushes it to `ghcr.io/konyu/action_stay_or_go` with both `v1.2.3` and the corresponding major tag (e.g. `v1`).

No manual `docker push` is required; tagging and pushing is enough to release a new version.

## License

This project is licensed under the MIT License.

## Reporting Issues

If you encounter issues with the **stay_or_go** CLI tool itself, please report them on [GitHub Issues for stay_or_go](https://github.com/uzumaki-inc/stay_or_go/issues).

If you encounter issues specifically related to the **action_stay_or_go** GitHub Action, please report them on [GitHub Issues for action_stay_or_go](https://github.com/konyu/action-stay-or-go/issues).
