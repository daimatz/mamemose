#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

=begin

Markdown memo server

理想の Markdown メモツールを探したがなかったので自分で作った。

  おもに Mac OS X 10.8 上の Ruby 1.9.3 でテスト
  Ruby 1.8.7 でも動くようにした
  Linux はおそらく大丈夫
  Windows も、こないだ Cygwin 上で試したら動いたのでたぶん動くと思う

  RDiscount が必要。

    $ gem install rdiscount

  DOCUMENT_ROOT と PORT を適当に書き換えて、起動

    $ nohup ruby memo.rb &

  ブラウザから

    http://localhost:PORT/

  にアクセスすればおｋ

  DOCUMENT_ROOT 以下の Markdown で書かれたテキストを
  勝手にHTMLに変換して表示します

  一覧ページでは Markdown ドキュメントの1行目をタイトルとして読み込みます。

  検索も作った。
  Markdown ドキュメントを全文検索して一致したものを表示します。
  Markdown ドキュメントでないものはファイル名に一致したを表示します。

=end

DOCUMENT_ROOT = "~/Dropbox/memo"
PORT = 20000
RECENT_NUMS = 10

require 'webrick'
require 'rdiscount'
require 'find'
require 'uri'

CONTENT_TYPE = "text/html; charset=utf-8"
DIR = File::expand_path(DOCUMENT_ROOT, '/')
MARKDOWN_PATTERN = /\.(md|markdown|txt)$/
IGNORE_FILES = ['.DS_Store','.AppleDouble','.LSOverride','Icon',/^\./,/~$/,
                '.Spotlight-V100','.Trashes','Thumbs.db','ehthumbs.db',
                'Desktop.ini','$RECYCLE.BIN',/^#/,'MathJax']

def header_html(title, path, q="")
  html = <<HTML
<!DOCTYPE HTML>
<html>
<head>
<meta http-equiv="Content-Type" content="#{CONTENT_TYPE}" />
<title>#{title}</title>
<style type="text/css"><!--
body {
    margin: auto;
    padding: 0 2em;
    max-width: 80%;
    border-left: 1px solid black;
    border-right: 1px solid black;
    font-size: 100%;
    line-height: 140%;
}
pre {
    border: 1px dotted #090909;
    background-color: #ececec;
    padding: 0.5em;
    margin: 0.5em 1em;
}
code {
    border: 1px dotted #090909;
    background-color: #ececec;
    padding: 2px 0.5em;
    margin: 0 0.5em;
}
pre code {
    border: none;
    background-color: none;
    padding: 0;
    margin: 0;
}
a {
    text-decoration: none;
}
a:link, a:visited, a:hover {
    color: #4444cc;
}
a:hover {
    text-decoration: underline;
}
h1, h2, h3 {
    font-weight: bold;
    color: #2f4f4f;
}
h1 {
    font-size: 200%;
    line-height: 100%;
    margin: 1em 0;
    border-bottom: 1px solid #2f4f4f;
}
h2 {
    font-size: 175%;
    line-height: 100%;
    margin: 1em 0;
    padding-left: 0.5em;
    border-left: 0.5em solid #2f4f4f;
}
h3 {
    font-size: 150%;
    line-height: 100%;
    margin: 1em 0;
}
h4, h5 {
    font-weight: bold;
    color: #000000;
    margin: 1em 0 0.5em;
}
h4 { font-size: 125% }
h5 { font-size: 100% }
p {
    margin: 0.7em 1em;
    text-indent: 1em;
}
div.footnotes {
    padding-top: 1em;
    color: #090909;
}
div#header {
    margin-top: 1em;
    padding-bottom: 1em;
    border-bottom: 1px dotted black;
}
div#header > form {
    display: float;
    float: right;
    text-align: right;
}
span.filename {
    color: #666666;
}
footer {
    border-top: 1px dotted black;
    padding: 0.5em;
    text-align: right;
    margin: 5em 0 1em;
}
--></style>
</head>
<body>
HTML
  link_str = ""
  uri = ""
  path.split('/').each do |s|
    next if s == ''
    uri += "/" + s
    link_str += File::SEPARATOR + "<a href='#{uri}'>#{s}</a>"
  end
  uri.gsub!('/'+File::basename(uri), "") if File.file?(path(uri))
  link_str = "<a href='/'>#{DOCUMENT_ROOT}</a>" + link_str
  search_form = <<HTML
<form action="/search" method="get">
<input name="path" type="hidden" value="#{uri}" />
<input name="q" type="text" value="#{q}" size="24" />
<input type="submit" value="search" />
</form>
HTML
  return html + "<div id=\"header\">#{link_str}#{search_form}</div>"
end

def footer_html
  html = <<HTML
<footer>
<a href="https://gist.github.com/3025885">https://gist.github.com/3025885</a>
</footer>
</body>
</html>
HTML
end

def uri(path)
  s = File::expand_path(path).gsub(DIR, "").gsub(File::SEPARATOR, '/')
  return s == '' ? '/' : s
end

def path(uri)
  return File.join(DIR, uri.gsub('/', File::SEPARATOR))
end

def docpath(uri)
  return File.join(DOCUMENT_ROOT, uri.gsub('/', File::SEPARATOR)).gsub(/#{File::SEPARATOR}$/, "")
end

def link_list(title, link)
  file = path(link)
  str = File.file?(file) ? sprintf("%.1fKB", File.size(file) / 1024.0) : "dir"
  return "- [#{title}](#{link}) <span class='filename'>#{File.basename(link)} [#{str}]</span>\n"
end

def markdown?(file)
  return file =~ MARKDOWN_PATTERN
end

def ignore?(file)
  file = File::basename(file)
  IGNORE_FILES.each do |s|
    return true if s.class == String && s == file
    return true if s.class == Regexp && s =~ file
  end
  return false
end

def get_title(filename, str="")
  return File::basename(filename) if !markdown?(filename)
  title = str.split(/$/)[0]
  return title =~ /^\s*$/ ? File::basename(filename) : title
end

server = WEBrick::HTTPServer.new({ :Port => PORT })

server.mount_proc('/') do |req, res|
  if req.path =~ /^\/search/
    query = req.query
    path = path(query["path"])
    q = URI.decode(query["q"])
    q = q.force_encoding('utf-8') if q.respond_to?(:force_encoding)

    found = {}
    Find.find(path) do |file|
      Find.prune if ignore?(file)
      dir = File::dirname(file)
      found[dir] = [] if !found[dir]
      if markdown?(file)
        open(file) do |f|
          c = f.read + "\n" + file
          found[dir] << [get_title(file,c), uri(file)] if !q.split(' ').map{|s| /#{s}/mi =~ c }.include?(nil)
        end
      elsif !q.split(' ').map{|s| /#{s}/ =~ File.basename(file)}.include?(nil)
        found[dir] << [get_title(file),uri(file)]
      end
    end

    title = "Search #{q} in #{docpath(query['path'])}"
    title = title.force_encoding('utf-8') if title.respond_to?(:force_encoding)
    body = title + "\n====\n"
    found.reject{|key, value| value == []}.sort.each do |key, value|
      body += "\n### in <a href='#{uri(key)}'>#{uri(key)}\n"
      value.each do |v|
        body += link_list(v[0], v[1])
      end
    end

    res.body = header_html(title, uri(path), q) + RDiscount.new(body).to_html + footer_html
    res.content_type = CONTENT_TYPE

  else

    filename = path(req.path)

    if File.directory?(filename) then
      title = "Index of #{docpath(req.path)}"
      body = title + "\n====\n"

      recent = []
      dirs = []
      markdowns = []
      files = []

      Find.find(filename) do |file|
        Find.prune if ignore?(file)
        recent << file if File.file?(file)
      end
      recent = recent.sort_by{|file| File.mtime(file)}.reverse.slice(0,RECENT_NUMS)
      recent = recent.map{|file|
        if markdown?(file) then
          [get_title(file, open(file).read), uri(file)]
        else [File::basename(file), uri(file)]
        end
      }
      p recent

      Dir.entries(filename).each do |i|
        next if ignore?(i)
        link = uri(File.join(filename, i))
        if File.directory?(path(link)) then
          dirs << [File.basename(link) + File::SEPARATOR, link]
        elsif markdown?(link)
          File.open(path(link)) do |f|
            markdowns << [get_title(link, f.read), link]
          end
        else
          files << [File::basename(link), link]
        end
      end

      body += "\nRecent:\n---\n"
      recent.each {|i| body += link_list(i[0], i[1])}

      body += "\nDirectories:\n----\n"
      dirs.each {|i| body += link_list(i[0], i[1])}

      body += "\nMarkdown documents:\n----\n"
      markdowns.each {|i| body += link_list(i[0], i[1])}

      body += "\nOther files:\n----\n"
      files.each {|i| body += link_list(i[0], i[1])}

      res.body = header_html(title, req.path) + RDiscount.new(body).to_html + footer_html
      res.content_type = CONTENT_TYPE

    elsif File.exists?(filename)
      open(filename) do |file|
        if markdown?(req.path)
          str = file.read
          title = get_title(filename, str)
          res.body = header_html(title, req.path) + RDiscount.new(str).to_html + footer_html
          res.content_type = CONTENT_TYPE
        else
          res.body = file.read
          res.content_type = WEBrick::HTTPUtils.mime_type(req.path, WEBrick::HTTPUtils::DefaultMimeTypes)
          res.content_length = File.stat(filename).size
        end
      end

    else
      res.status = WEBrick::HTTPStatus::RC_NOT_FOUND
    end

  end
end

trap(:INT){server.shutdown}
server.start
