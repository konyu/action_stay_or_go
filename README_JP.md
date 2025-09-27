# action_stay_or_go GitHub Action

`action_stay_or_go` は、Go / Ruby の依存関係を解析する CLI「stay_or_go」を GitHub Actions 上で実行し、依存ライブラリのスコアレポートを生成する Docker ベースのカスタムアクションです。依存関係のヘルスチェックを CI の一部として自動化したいチーム向けに設計されています。

## 主な特徴
- Go (`go.mod`) と Ruby (`Gemfile`) を自動検出し、人気度やメンテ状況をスコア化
- 設定したしきい値 (`min_score`) 未満のライブラリを検出するとジョブを失敗させ、早期にリスクを発見
- Docker イメージとして配布しているため、実行環境に依存せず同じ結果を再現

## クイックスタート
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
`mode` は `go` と `ruby` に対応しています。両方を検査したい場合はステップを分けてそれぞれ実行してください。

## 必要な権限
- `github_token` には `secrets.GITHUB_TOKEN` もしくは `read:packages` 等の権限を持つ PAT を指定してください。stay_or_go が GitHub API を利用して依存ライブラリの情報を収集します。

## Inputs
| 名前 | 必須 | 既定値 | 説明 |
| --- | --- | --- | --- |
| `github_token` | ✅ | – | GitHub API 呼び出しに利用するトークン。stay_or_go へ `-g` フラグまたは `GITHUB_TOKEN` として渡されます。 |
| `mode` | ✅ | `go` | 解析対象のエコシステム。`go` または `ruby` を指定します。 |
| `input_path` | – | 空文字 | 解析対象のファイルパスを直接指定します（例: `Gemfile`）。未指定時は自動検出します。 |
| `config_path` | – | 空文字 | 重み付けなどを調整する YAML 設定ファイルへのパス。 |
| `verbose` | – | `false` | 詳細ログを有効化します。 |
| `workdir` | – | `.` | stay_or_go を実行する作業ディレクトリ。モノレポでサブディレクトリを解析したい場合に利用します。 |
| `output_path` | – | `stay_or_go_report.tsv` | 生成される TSV レポートの出力パス（相対）。 |
| `min_score` | ✅ | – | 許容する最小スコア。これを下回るライブラリがあるとアクションが失敗します。 |

## Outputs
| 名前 | 説明 |
| --- | --- |
| `report_path` | 生成したレポートファイルへのパス。後続ステップでアップロードや可視化に利用できます。 |

## 応用例
- Ruby プロジェクトでカスタム設定を使う例
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
- 生成レポートを PR コメントに反映したい場合は、`report_path` を受け取って Markdown へ整形し、`actions/github-script` などでコメントを投稿できます。

## ローカル検証
- Docker が利用できる環境なら `docker build` したイメージで `entrypoint.sh` を起動し、GitHub Actions と同じコマンドライン引数で挙動を確認できます。
- ワークフロー全体を試す際は [nektos/act](https://github.com/nektos/act) を使ってローカル実行することも可能です。必要なシークレットや環境変数を用意してください。

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
