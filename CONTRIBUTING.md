# Contributing

このドキュメントはリポジトリへの参加手順と開発ルールをまとめたものです。

## コード整形 (Formatter)

このリポジトリでは MATLAB コードの整形に MISS_HIT を使用します。以下の手順に従ってください。

### セットアップ

```sh
python3 -m pip install -r requirements-dev.txt
```

### コマンド

```sh
make format        # .m ファイルを整形する
make format-check  # CI 用: 整形が必要なファイルがないか確認する
```

- ローカルでの作業後は `make format` を実行して自動整形してください。
- CI では PR ごとに `make format-check` が実行され、整形が必要なファイルがあると失敗します。
- 文字コードや改行の問題で formatter が失敗することがあります。`miss_hit.cfg` を参照し、プロジェクトの設定（例: `--input-encoding utf-8`, `line_length`）を確認してください。
