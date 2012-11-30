#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

conf = File.expand_path("~" + File::SEPARATOR + ".mamemose.rb")
load conf if File.exists?(conf)

DOCUMENT_ROOT = "~/Dropbox/memo" if !defined?(DOCUMENT_ROOT)
PORT = 20000 if !defined?(PORT)
RECENT_NUM = 10 if !defined?(RECENT_NUM)
RECENT_PATTERN = /.*/ if !defined?(RECENT_PATTERN)
IGNORE_FILES = ['.DS_Store','.AppleDouble','.LSOverride','Icon',/^\./,/~$/,
                '.Spotlight-V100','.Trashes','Thumbs.db','ehthumbs.db',
                'Desktop.ini','$RECYCLE.BIN',/^#/,'MathJax','syntaxhighlighter'] if !defined?(IGNORE_FILES)
MARKDOWN_PATTERN = /\.(md|markdown)$/ if !defined?(MARKDOWN_PATTERN)
CUSTOM_HEADER = '' if !defined?(CUSTOM_HEADER)
CUSTOM_BODY = '' if !defined?(CUSTOM_BODY)
CUSTOM_FOOTER = '' if !defined?(CUSTOM_FOOTER)

require 'rubygems'
require 'webrick'
require 'find'
require 'uri'
require 'redcarpet'
require 'htmlentities'

CONTENT_TYPE = "text/html; charset=utf-8"
DIR = File::expand_path(DOCUMENT_ROOT, '/')

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
    border: 1px solid #090909;
    background-color: #f8f8f8;
    padding: 0.5em;
    margin: 0.5em 1em;
}
code {
    border: 1px solid #cccccc;
    background-color: #f8f8f8;
    padding: 2px 0.5em;
    margin: 0 0.5em;
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
a.filename {
    color: #666666;
}
footer {
    border-top: 1px dotted black;
    padding: 0.5em;
    font-size: 80%;
    text-align: right;
    margin: 5em 0 1em;
}
--></style>
<script>
function copy(text) {
  prompt("Copy filepath below:", text);
}
</script>
#{CUSTOM_HEADER}
</head>
<body>
#{CUSTOM_BODY}
HTML
  link_str = ""
  uri = ""
  path.split('/').each do |s|
    next if s == ''
    uri += "/" + s
    link_str += File::SEPARATOR + "<a href='#{uri}'>#{s}</a>"
  end
  link_str +=  " <a class='filename' href=\"javascript:copy('#{docpath(uri)}');\">[copy]</a>"
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
#{CUSTOM_FOOTER}
<footer>
<a href="https://github.com/daimatz/mamemose">mamemose: Markdown memo server</a>
</footer>
</body>
</html>
HTML
  return html
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
  return "- [#{title}](#{link}) <a class='filename' href=\"javascript:copy('#{docpath(link)}');\">[#{File.basename(link)}, #{str}]</a>\n"
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

class HTMLwithSyntaxHighlighter < Redcarpet::Render::XHTML
  def block_code(code, lang)
    code = HTMLEntities.new.encode(code)
    lang ||= "plain"
    return "<pre class='brush: #{lang}'>#{code}</pre>"
  end
end

def markdown(text)
  markdown = Redcarpet::Markdown.new(HTMLwithSyntaxHighlighter,
                                     {:strikethrough => true,
                                       :autolink => true,
                                       :fenced_code_blocks => true})
  markdown.render(text)
end

server = WEBrick::HTTPServer.new({ :Port => PORT })

server.mount_proc('/') do |req, res|
  res['Cache-Control'] = 'no-cache, no-store, must-revalidate'
  res['Pragma'] = 'no-cache'
  res['Expires'] = '0'
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

    res.body = header_html(title, uri(path), q) + markdown(body) + footer_html
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

      if RECENT_NUM > 0 then
        Find.find(filename) do |file|
          Find.prune if ignore?(file)
          recent << file if File.file?(file) && file =~ RECENT_PATTERN
        end
        recent = recent.sort_by{|file| File.mtime(file)}.reverse.slice(0,RECENT_NUM)
        recent = recent.map{|file|
          if markdown?(file) then
            [get_title(file, open(file).read), uri(file)]
          else [File::basename(file), uri(file)]
          end
        }
      else
        recent = []
      end

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

      body += "\nRecent:\n---\n" if RECENT_NUM > 0
      recent.each {|i| body += link_list(i[0], i[1])}

      body += "\nDirectories:\n----\n"
      dirs.each {|i| body += link_list(i[0], i[1])}

      body += "\nMarkdown documents:\n----\n"
      markdowns.each {|i| body += link_list(i[0], i[1])}

      body += "\nOther files:\n----\n"
      files.each {|i| body += link_list(i[0], i[1])}

      res.body = header_html(title, req.path) + markdown(body) + footer_html
      res.content_type = CONTENT_TYPE

    elsif File.exists?(filename)
      open(filename) do |file|
        if markdown?(req.path)
          str = file.read
          title = get_title(filename, str)
          res.body = header_html(title, req.path) + markdown(str) + footer_html
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
