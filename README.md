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
設定項目は以下の通り

- `DOCUMENT_ROOT`
    - ドキュメントルート
- `PORT`
    - ポート。 http://localhost:PORT/ にアクセス
- `MARKDOWN_PATTERN`
    - Markdown ドキュメントと見なすファイルパターンを正規表現で
- `IGNORE_FILES`
    - 無視するファイル・ディレクトリのリスト。
      文字列の場合はそのものを、正規表現の場合はそれにマッチするものを無視する
- `RECENT_NUM`
    - 「最近更新したファイル」を表示する数
- `RECENT_PATTERN`
    - 「最近更新したファイル」に表示するファイルパターンを正規表現で
- `CUSTOM_HEADER`
    - カスタムヘッダ。 `head` タグの最後に入る
- `CUSTOM_BODY`
    - カスタムボディ。 `body` タグの最初に入る
- `CUSTOM_FOOTER`
    - カスタムフッタ。 `body` タグの最後に入る

設定されなかったらデフォルト値を使います。

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

上記のように設定すると、次のような Markdown ファイル `~/memo/sample.md` は

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

次のように表示される。

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
    - 検索が遅いのはどうしようもないです。ファイル数 3000 くらいまでなら
      まあ使えるかなというのは確認したつもりですが
    - SSD 積んでますか？
- 他の言語もシンタックスハイライトしたいんだけど
    - SyntaxHighlighter の構文ファイルを自分で書いて読み込むようにしましょう
    - Haskell 用のは書きました [gist](https://gist.github.com/3969549)
- reStructuredText 対応して
    - Python で書いてください
- 表を書きたいんだけど
    - 無理。 table タグ書いてください
- 定義リストを書きたいんだけど
    - 同上
