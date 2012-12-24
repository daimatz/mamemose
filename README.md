mamemose: Markdown memo server
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
- できれば GitHub Flavored Markdown でシンタックスハイライトもしてほしい
- できれば LaTeX で数式も書きたい

環境
----

- おもに Mac OS X 10.8 上の Ruby 1.9.3 でテスト
- Ruby 1.8.7 でも動くようにした
- Linux はおそらく大丈夫
- Windows も、こないだ Cygwin 上で試したら動いたのでたぶん動くと思う

インストール方法
----

RubyGems で公開されています。

- <https://rubygems.org/gems/mamemose>

インストールは

```bash
$ gem install mamemose
```

使い方
----

設定ファイル (後述) を書いたら以下で起動

```bash
$ mamemose &> /dev/null &
```

ブラウザから

```
http://localhost:PORT/
```

にアクセスすればおｋ

`DOCUMENT_ROOT` 以下の Markdown で書かれたテキストを勝手にHTMLに変換して表示します。
一覧ページでは Markdown ドキュメントの1行目をタイトルとして読み込みます。

`DOCUMENT_ROOT` を Dropbox 以下のディレクトリに指定しておけば、どのマシンからでも
メモにアクセスできるようになります。

文字コードは UTF-8 で書くようにしてください。

### シンタックスハイライト

[コード部分に GitHub Flavored Markdown の記法](http://github.github.com/github-flavored-markdown/)
を使い、シンタックスハイライトに
[SyntaxHighlighter](http://alexgorbatchev.com/SyntaxHighlighter/)
を使うことができます。設定例を参照。

### 数式

[MathJax](http://www.mathjax.org/) を使うと数式も書けます。設定例を参照。

設定
----

ホームディレクトリに `.mamemose.rb` という設定ファイルを置くとそれを読みます。
設定項目は以下の通りで、
設定されなかったらデフォルト値を使います。

- `DOCUMENT_ROOT`
    - ドキュメントルート。デフォルトは `~/Dropbox/memo`
- `PORT`
    - ポート。 http://localhost:PORT/ にアクセス。デフォルトは 20000
- `MARKDOWN_PATTERN`
    - Markdown ドキュメントと見なすファイルパターンを正規表現で。デフォルトは `/\.(md|markdown)$/`
- `INDEX_PATTERN`
    - 一覧ページ表示時に自動的に読み込むファイルパターンを正規表現で。
      これにマッチするファイルは1つのディレクトリに複数置かないほうがいいです。
      デフォルトは `/^README/`
- `RECENT_NUM`
    - 「最近更新したファイル」を表示する数。デフォルトは 10
- `RECENT_PATTERN`
    - 「最近更新したファイル」に表示するファイルパターンを正規表現で。
       デフォルトは `/.*/`、つまり任意のファイルにマッチします。
- `CUSTOM_HEADER`
    - カスタムヘッダ。 `head` タグの最後に入る。デフォルトは空文字列。
- `CUSTOM_BODY`
    - カスタムボディ。 `body` タグの最初に入る。デフォルトは空文字列。
- `CUSTOM_FOOTER`
    - カスタムフッタ。 `body` タグの最後に入る。デフォルトは空文字列。
- `IGNORE_FILES`
    - 無視するファイル・ディレクトリのリスト。
      文字列の場合はそのものを、正規表現の場合はそれにマッチするものを無視する。
      デフォルトは以下の通り。

```ruby
['_Store','.AppleDouble','.LSOverride','Icon',/^\./,/~$/,
 '.Spotlight-V100','.Trashes','Thumbs.db','ehthumbs.db',
 'Desktop.ini','$RECYCLE.BIN',/^#/,'MathJax','syntaxhighlighter']
```

### 設定ファイル例

`~/.mamemose.rb`

```ruby
DOCUMENT_ROOT = "~/memo"

PORT = 8888

# 通常の Markdown ファイルに加えて .txt ファイルも Markdown と見なす
MARKDOWN_PATTERN = /\.(md|markdown|txt)$/

# 最近更新したファイル一覧がジャマ
RECENT_NUM = 0

# 最近更新したファイル一覧に出すものを Markdown ドキュメントだけにする
# RECENT_PATTERN = MARKDOWN_PATTERN

# すべてのページで MathJax が使えるように
CUSTOM_HEADER = <<HEADER
<script type="text/javascript"
  src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML">
</script>
HEADER

# すべてのページで SyntaxHighlighter が使えるように
host = "http://alexgorbatchev.com/pub/sh/current" # 変数も使えます
CUSTOM_FOOTER = <<FOOTER
<link href="#{host}/styles/shCoreDefault.css" rel="stylesheet" type="text/css" />
<script src="#{host}/scripts/shCore.js" type="text/javascript"></script>
<script src="#{host}/scripts/shAutoloader.js" type="text/javascript"></script>
<script type="text/javascript">
SyntaxHighlighter.autoloader(
'AS3 as3 #{host}/scripts/shBrushAS3.js',
'AppleScript applescript #{host}/scripts/shBrushAppleScript.js',
'Bash bash #{host}/scripts/shBrushBash.js',
'CSharp csharp #{host}/scripts/shBrushCSharp.js',
'ColdFusion coldfusion #{host}/scripts/shBrushColdFusion.js',
'Cpp cpp #{host}/scripts/shBrushCpp.js',
'Css css #{host}/scripts/shBrushCss.js',
'Delphi delphi #{host}/scripts/shBrushDelphi.js',
'Diff diff #{host}/scripts/shBrushDiff.js',
'Erlang erlang #{host}/scripts/shBrushErlang.js',
'Groovy groovy #{host}/scripts/shBrushGroovy.js',
'JScript jscript #{host}/scripts/shBrushJScript.js',
'Java java #{host}/scripts/shBrushJava.js',
'JavaFX javafx #{host}/scripts/shBrushJavaFX.js',
'Perl perl #{host}/scripts/shBrushPerl.js',
'Php php #{host}/scripts/shBrushPhp.js',
'Plain plain #{host}/scripts/shBrushPlain.js',
'PowerShell powershell #{host}/scripts/shBrushPowerShell.js',
'Python python #{host}/scripts/shBrushPython.js',
'Ruby ruby #{host}/scripts/shBrushRuby.js',
'Sass sass #{host}/scripts/shBrushSass.js',
'Scala scala #{host}/scripts/shBrushScala.js',
'Sql sql #{host}/scripts/shBrushSql.js',
'Vb vb #{host}/scripts/shBrushVb.js',
'Xml xml #{host}/scripts/shBrushXml.js'
);
SyntaxHighlighter.all();
</script>
FOOTER
```

### 使用例

上記のように設定ファイルを書いたとする。
次のような Markdown ファイル `~/memo/sample.md` を書くと、

    数列
    ====

    問題
    ----

    和の公式
    $$ \sum\_{k=1}^n k = \frac{1}{2}n(n+1) $$
    を計算する関数を C++ で実装せよ。

    解答
    ----

    ```cpp
    int f(int n) {
      int ret = 0;
      for (int k = 1; k <= n; k++) {
        ret += k;
      }
      return ret;
    }
    ```

一覧ページ (http://localhost:8888/) では次のように表示される。

![](https://raw.github.com/daimatz/mamemose/master/index.png)

またこのファイルの表示 (http://localhost:8888/sample.md) は次のようになる。

![](https://raw.github.com/daimatz/mamemose/master/sample.png)

MathJax と SyntaxHighlighter はローカルにダウンロードして使うのが親切だと思います。

検索
----

Markdown ドキュメントを全文検索して一致したものを表示します。
Markdown ドキュメントでないものはファイル名に一致したものを表示します。

FAQ と予想されるもの
----

- 遅いよ
    - 一覧ページでは「最近更新したファイル」を表示するために
      そのディレクトリ以下の全ファイルを舐めているので遅いです。
      `RECENT_NUM = 0` にしてください。
    - 検索が遅いのはどうしようもないです。 5KB 〜 10KB くらいのメモが 3000 件くらいまでなら
      まあ使えるかなというのは確認したつもりですが
    - SSD 積んでますか？
- 他の言語もシンタックスハイライトしたいんだけど
    - SyntaxHighlighter の構文ファイルを自分で書いて読み込むようにしましょう
    - Haskell 用のは書きました [gist](https://gist.github.com/3969549)
- reStructuredText 対応して
    - Python で書いてください
- 表、テーブル、 table を書きたいんだけど
    - **実は書けました。** 以下のようにします。

```
Name    |   Age
--------|------
Fred    |   29
Jim     |   47
Harry   |   32
```

- 定義リストを書きたいんだけど
    - 無理らしいです。 HTML 直接書いてください。
