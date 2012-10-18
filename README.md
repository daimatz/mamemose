Markdown memo server
====

概要
----

理想の Markdown メモツールを探したがなかったので自分で作った。要件としては

- Markdown など軽量マークアップ言語で書かれたドキュメントを
  コマンド操作無しで勝手に HTML に変換してくれる
    - Sphinx などをそのまま使うのはコマンドを打つ手間があるので嫌だった
- 複数マシンで内容を共有できる (Dropbox 等を使ってもよい)
- 使い慣れたエディタを使える
- 検索できる

環境
----

- おもに Mac OS X 10.8 上の Ruby 1.9.3 でテスト
- Ruby 1.8.7 でも動くようにした
- Linux はおそらく大丈夫
- Windows も、こないだ Cygwin 上で試したら動いたのでたぶん動くと思う

### ライブラリ等

RDiscount が必要。

    $ gem install rdiscount

設定
----

同じディレクトリに `conf.rb` という設定ファイルを置くとそれを読みます。
`DOCUMENT_ROOT`, `PORT`, `RECENT_NUMS`, `IGNORE_FILES`, `MARKDOWN_PATTERN`,
`CUSTOM_HEADER`, `CUSTOM_BODY`, `CUSTOM_FOOTER` を設定可能。
設定されなかったらデフォルト値を使います。

### 設定ファイル例

`conf.rb`

    DOCUMENT_ROOT = "~/memo"

    PORT = 8888

    # 通常の Markdown ファイルに加えて .txt ファイルも Markdown と見なす
    MARKDOWN_PATTERN = /\.(md|markdown|txt)$/

    # すべてのページで MathJax が使えるように
    CUSTOM_HEADER = <<HEADER
    <script type="text/javascript"
      src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML">
    </script>
    HEADER

使い方
----

設定ファイルを書いたら以下で起動

    $ nohup ruby memo.rb &

ブラウザから

    http://localhost:PORT/

にアクセスすればおｋ

`DOCUMENT_ROOT` 以下の Markdown で書かれたテキストを勝手にHTMLに変換して表示します。
一覧ページでは Markdown ドキュメントの1行目をタイトルとして読み込みます。

検索
----

Markdown ドキュメントを全文検索して一致したものを表示します。
Markdown ドキュメントでないものはファイル名に一致したものを表示します。
