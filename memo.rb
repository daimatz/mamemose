#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

DOCUMENT_ROOT = "~/Dropbox/memo"
PORT = 2000

require 'webrick'
require 'rdiscount'
require 'find'
require 'uri'

CONTENT_TYPE = "text/html; charset=urf-8"

def header_html(title, path, q="")
  html = <<HTML
<!DOCTYPE HTML>
<html>
<head>
<meta http-equiv="text/html" charset="utf-8" />
<title>#{title}</title>
<style type="text/css"><!--
body {
    margin: auto;
    padding-right: 1em;
    padding-left: 1em;
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
h1 a, h2 a, h3 a, h4 a, h5 a {
    text-decoration: none;
    color: #2f4f4f;
}
h1, h2, h3, h4, h5 {
    font-weight: bold;
    border-bottom: 1px dotted black;
    color: #2f4f4f;
}
h1 {
    font-size: 150%;
    margin-top: 2em;
}
h2 { font-size: 130% }
h3 { font-size: 120% }
h4 {
    font-size: 110%;
    font-style: italic;
}
h5 {
    font-size: 100%;
    font-style: italic;
}
h1.title {
    margin-top: 1ex;
    line-height: 1.2em;
    font-size: 200%;
    font-weight: bold;
    padding-top: 0.2em;
    padding-bottom: 0.2em;
    text-align: left;
    border: none;
}
dt code { font-weight: bold }
dd p { margin-top: 0 }
div.footnotes {
    padding-top: 1em;
    color: #090909;
}

div#header {
    margin-top: 1em;
}
div > form {
    display: float;
    float: right;
    text-align: right;
}
div.navheader table td, div.navfooter table td {
    padding: 0.5em;
}

/* "Return to top */
div.to_top {
    text-align : right ;                /* for IE 6 */
    margin-left : auto ;
    margin-right : 0 ;
}

div.to_top a, div.navheader a , div.navfooter a {
    padding: 0.5em;
    margin: 0.5em;
    border: 1px solid rgba(0,0,0,0.2);
    -webkit-border-radius: 0.5em;
    -moz-border-radius: 0.5em;
    border-radius: 0.5em;
    -webkit-box-shadow: 0 1px 3px rgba(0,0,0,0.5);
    -moz-box-shadow: 0 1px 3px rgba(0,0,0,0.5);
    box-shadow: 0 1px 3px rgba(0,0,0,0.5);
}

/* http://www.hrykozw.com/blog/archives/817 */
*[accesskey]::after {
    text-transform: capitalize;
    content: "[" attr(accesskey) "]";
    margin-left: 0.5em;
    padding: 0.5em;
    color: #000000;
    background: #ffffff;
    font-size: 70%;
    font-weight: bold;
    font-style: normal;
    text-decoration: none;
}

span.filename {
    color: #666666;
}
footer {
    border-top: 1px dotted black;
    padding: 0.5em;
    text-align: right;
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
  uri.gsub!(/\/[^\/]+?\.md$/, "")
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

DIR = File::expand_path(DOCUMENT_ROOT, '/')

def uri(path)
  return File::expand_path(path).gsub(DIR, "").gsub(File::SEPARATOR, '/')
end

def path(uri)
  return File.join(DIR, uri.gsub('/', File::SEPARATOR))
end

def docpath(uri)
  return File.join(DOCUMENT_ROOT, uri.gsub('/', File::SEPARATOR)).gsub(/#{File::SEPARATOR}$/, "")
end

def link_list(title, link)
  file = path(link)
  str = ""
  if File.file?(file)
    str = sprintf("%.1f", File.size(file) / 1024.0) + "KB"
  else
    str = "dir"
  end
  return "- [#{title}](#{link}) <span class='filename'>#{File.basename(link)} [#{str}]</span>\n"
end

server = WEBrick::HTTPServer.new({ :Port => PORT })

server.mount_proc('/') do |req, res|
  if req.path =~ /^\/search/
    query = req.query
    path = path(query["path"])
    q = URI.decode(query["q"]).force_encoding('utf-8')

    found = []
    Find.find(path) do |file|
      if File::file?(file)
        open(file) do |f|
          c = f.read + "\n" + file
          found << [c.split(/$/)[0], uri(file)] if !q.split(' ').map{|s| /#{s}/m =~ c }.include?(nil)
        end
      end
    end

    title = "search #{q} in #{docpath(query['path'])}".force_encoding('utf-8')
    body = title + "\n====\n"
    found.each do |v|
      body += link_list(v[0], v[1])
    end

    res.body = header_html(title, uri(path), q) + RDiscount.new(body).to_html + footer_html

  else

    filename = path(req.path)

    if File.directory?(filename) then
      title = "index of #{docpath(req.path)}"
      body = title + "\n====\n"

      dirs = []
      files = []

      Dir.entries(filename).each do |i|
        next if i =~ /^\.+$/
        link = uri(File.join(filename, i))
        ftitle = ""
        if File.directory?(path(link)) then
          dirs << [File.basename(link) + File::SEPARATOR, link]
        else
          File.open(path(link)) do |f|
            files << [ftitle = f.read.split(/$/)[0], link]
          end
        end
      end

      body += "\ndirectories:\n----\n"
      dirs.each {|i| body += link_list(i[0], i[1])}

      body += "\nfiles:\n----\n"
      files.each {|i| body += link_list(i[0], i[1])}

      res.body = header_html(title, req.path) + RDiscount.new(body).to_html + footer_html
      res.content_type = CONTENT_TYPE

    elsif File.exists?(filename)
      open(filename) do |file|
        if req.path =~ /\.md$/ or req.path =~ /\.markdown$/ then
          str = file.read
          title = str.split(/$/)[0]
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