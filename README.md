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
- できれば GitHub Flavored Markdown でシンタックスハイライトもしてほしい

環境
----

- おもに Mac OS X 10.8 上の Ruby 1.9.3 でテスト
- Ruby 1.8.7 でも動くようにした
- Linux はおそらく大丈夫
- Windows も、こないだ Cygwin 上で試したら動いたのでたぶん動くと思う

### ライブラリ等

Rubygems の Redcarpet と htmlentities が必要。

    $ gem install redcarpet htmlentities

またコード部分に GitHub Flavored Markdown の記法を使い、シンタックスハイライトに
[SyntaxHighlighter](http://alexgorbatchev.com/SyntaxHighlighter/)
を使うことができる。設定例を参照。

設定
----

ホームディレクトリに `.memo.conf.rb` もしくは
`memo.rb` と同じディレクトリに `conf.rb` という設定ファイルを置くとそれを読みます。
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

`~/.memo.conf.rb` もしくは `conf.rb`

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
CUSTOM_FOOTER = <<FOOTER
<link href="http://alexgorbatchev.com/pub/sh/current/styles/shCoreDefault.css" rel="stylesheet" type="text/css" />
<script src="http://alexgorbatchev.com/pub/sh/current/scripts/shCore.js" type="text/javascript"></script>
<script src="http://alexgorbatchev.com/pub/sh/current/scripts/shAutoloader.js" type="text/javascript"></script>
<script type="text/javascript">
SyntaxHighlighter.autoloader(
'AS3 as3 http://alexgorbatchev.com/pub/sh/current/scripts/shBrushAS3.js',
'AppleScript applescript http://alexgorbatchev.com/pub/sh/current/scripts/shBrushAppleScript.js',
'Bash bash http://alexgorbatchev.com/pub/sh/current/scripts/shBrushBash.js',
'CSharp csharp http://alexgorbatchev.com/pub/sh/current/scripts/shBrushCSharp.js',
'ColdFusion coldfusion http://alexgorbatchev.com/pub/sh/current/scripts/shBrushColdFusion.js',
'Cpp cpp http://alexgorbatchev.com/pub/sh/current/scripts/shBrushCpp.js',
'Css css http://alexgorbatchev.com/pub/sh/current/scripts/shBrushCss.js',
'Delphi delphi http://alexgorbatchev.com/pub/sh/current/scripts/shBrushDelphi.js',
'Diff diff http://alexgorbatchev.com/pub/sh/current/scripts/shBrushDiff.js',
'Erlang erlang http://alexgorbatchev.com/pub/sh/current/scripts/shBrushErlang.js',
'Groovy groovy http://alexgorbatchev.com/pub/sh/current/scripts/shBrushGroovy.js',
'JScript jscript http://alexgorbatchev.com/pub/sh/current/scripts/shBrushJScript.js',
'Java java http://alexgorbatchev.com/pub/sh/current/scripts/shBrushJava.js',
'JavaFX javafx http://alexgorbatchev.com/pub/sh/current/scripts/shBrushJavaFX.js',
'Perl perl http://alexgorbatchev.com/pub/sh/current/scripts/shBrushPerl.js',
'Php php http://alexgorbatchev.com/pub/sh/current/scripts/shBrushPhp.js',
'Plain plain http://alexgorbatchev.com/pub/sh/current/scripts/shBrushPlain.js',
'PowerShell powershell http://alexgorbatchev.com/pub/sh/current/scripts/shBrushPowerShell.js',
'Python python http://alexgorbatchev.com/pub/sh/current/scripts/shBrushPython.js',
'Ruby ruby http://alexgorbatchev.com/pub/sh/current/scripts/shBrushRuby.js',
'Sass sass http://alexgorbatchev.com/pub/sh/current/scripts/shBrushSass.js',
'Scala scala http://alexgorbatchev.com/pub/sh/current/scripts/shBrushScala.js',
'Sql sql http://alexgorbatchev.com/pub/sh/current/scripts/shBrushSql.js',
'Vb vb http://alexgorbatchev.com/pub/sh/current/scripts/shBrushVb.js',
'Xml xml http://alexgorbatchev.com/pub/sh/current/scripts/shBrushXml.js'
);
SyntaxHighlighter.all();
</script>
FOOTER
```

使い方
----

設定ファイルを書いたら以下で起動

    $ nohup ruby memo.rb &

ブラウザから

    http://localhost:PORT/

にアクセスすればおｋ

`DOCUMENT_ROOT` 以下の Markdown で書かれたテキストを勝手にHTMLに変換して表示します。
一覧ページでは Markdown ドキュメントの1行目をタイトルとして読み込みます。

`DOCUMENT_ROOT` を Dropbox 以下のディレクトリに指定しておけば、どのマシンからでも
メモにアクセスできるようになります。

検索
----

Markdown ドキュメントを全文検索して一致したものを表示します。
Markdown ドキュメントでないものはファイル名に一致したものを表示します。
