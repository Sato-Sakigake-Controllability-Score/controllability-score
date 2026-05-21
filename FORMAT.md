# Formatter

このリポジトリでは MATLAB コードの formatter として MISS_HIT を使います。

## Setup

```sh
python3 -m pip install -r requirements-dev.txt
```

## Commands

```sh
make format        # .m ファイルを整形する
make format-check  # CI 用: 整形が必要なファイルがないか確認する
```

`make format` はコードを書いたあとにローカルで実行します。
`make format-check` は GitHub Actions でも実行されます。
