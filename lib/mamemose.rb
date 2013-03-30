require 'rubygems'
require 'webrick'
require 'find'
require 'uri'
require 'redcarpet'
require 'htmlentities'

require 'mamemose/version'

require 'mamemose/path'

require 'mamemose/env'

class HTMLwithSyntaxHighlighter < Redcarpet::Render::XHTML
  def block_code(code, lang)
    code = HTMLEntities.new.encode(code)
    lang ||= "plain"
    return "<pre class='brush: #{lang}'>#{code}</pre>"
  end
end

class Mamemose::Server
  include Mamemose::Path

  def initialize(port)
    @mamemose = WEBrick::HTTPServer.new({ :Port => port ? port.to_i : PORT })
    trap(:INT){finalize}
    trap(:TERM){finalize}
  end

  def start
    @mamemose.start
  end

  def server
    @mamemose.mount_proc('/') do |req, res|
      res['Cache-Control'] = 'no-cache, no-store, must-revalidate'
      res['Pragma'] = 'no-cache'
      res['Expires'] = '0'

      p fullpath(req.path)
      if req.path =~ /^\/search/
        res = req_search(req, res)
      elsif File.directory?(fullpath(req.path))
        res = req_index(req, res)
      elsif File.exists?(fullpath(req.path))
        res = req_file(fullpath(req.path), res, false)
      else
        res.status = WEBrick::HTTPStatus::RC_NOT_FOUND
      end
    end
    start
  end

  def file(filename)
    @mamemose.mount_proc('/') do |req, res|
      res['Cache-Control'] = 'no-cache, no-store, must-revalidate'
      res['Pragma'] = 'no-cache'
      res['Expires'] = '0'
      res = req_file(File.absolute_path(filename), res, true)
      res.content_type = CONTENT_TYPE
    end
    start
  end

private

  def finalize
    Thread::list.each {|t| Thread::kill(t) if t != Thread::current}
    @mamemose.shutdown
  end

  def header_html(title, fullpath)
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
blockquote {
    margin: 1em 3em;
    border: 2px solid #999;
    padding: 0.3em 0;
    background-color: #f3fff3;
}
hr {
    height: 1px;
    border: none;
    border-top: 1px solid black;
}
table {
    padding: 0;
    margin: 1em 2em;
    border-spacing: 0;
    border-collapse: collapse;
}
table tr {
    border-top: 1px solid #cccccc;
    background-color: white;
    margin: 0;
    padding: 0;
}
table tr:nth-child(2n) {
    background-color: #f8f8f8;
}
table tr th {
    font-weight: bold;
    border: 1px solid #cccccc;
    text-align: left;
    margin: 0;
    padding: 6px 13px;
}
table tr td {
    border: 1px solid #cccccc;
    text-align: left;
    margin: 0;
    padding: 6px 13px;
}
table tr th :first-child, table tr td :first-child {
    margin-top: 0;
}
table tr th :last-child, table tr td :last-child {
    margin-bottom: 0;
}
--></style>
<script>
function copy(text) {
  prompt("Copy filepath below:", text);
}
</script>
<script>
(function(){
  var fullpath = "#{fullpath}";
  ws = new WebSocket("ws://localhost:#{WS_PORT}");
  ws.onopen = function() {
    console.log("WebSocket (port=#{WS_PORT}) connected: " + fullpath);
    ws.send(fullpath);
  };
  ws.onmessage = function(evt) {
    console.log("received: " + evt.data);
    if (evt.data == "updated") {
      console.log("update detected. reloading...");
      location.reload();
    }
  };
})();
</script>
#{CUSTOM_HEADER}
</head>
<body>
#{CUSTOM_BODY}
HTML
    return html
  end

  def search_form(path, q="")
    link_str = ""
    uri = ""
    path.split('/').each do |s|
      next if s == ''
      uri += "/" + s
      link_str += File::SEPARATOR + "<a href='#{uri}'>#{s}</a>"
    end
    link_str +=  " <a class='filename' href=\"javascript:copy('#{docpath(uri)}');\">[copy]</a>"
    uri.gsub!('/'+File::basename(uri), "") if File.file?(fullpath(uri))
    link_str = "<a href='/'>#{DOCUMENT_ROOT}</a>" + link_str
    search_form = <<HTML
<form action="/search" method="get">
<input name="path" type="hidden" value="#{uri}" />
<input name="q" type="text" value="#{q}" size="24" />
<input type="submit" value="search" />
</form>
HTML
    return "<div id=\"header\">#{link_str}#{search_form}</div>"
  end

  def footer_html(filepath=nil)
    if filepath
      updated = File.basename(filepath)\
              + " [#{filesize(filepath)}]"\
              + " / Last Updated: "\
              + File.mtime(filepath).strftime("%Y-%m-%d %H:%M:%S")\
              + " / "
    else
      updated = ""
    end
    html = <<HTML
#{CUSTOM_FOOTER}
<footer>
#{updated}
<a href="https://github.com/daimatz/mamemose">mamemose: Markdown memo server</a>
</footer>
</body>
</html>
HTML
    return html
  end

  def req_search(req, res)
    query = req.query
    path = fullpath(query["path"])
    q = URI.decode(query["q"])
    q = q.force_encoding('utf-8') if q.respond_to?(:force_encoding)

    found = find(path, q)

    title = "Search #{q} in #{showpath(query['path'])}"
    title = title.force_encoding('utf-8') if title.respond_to?(:force_encoding)
    body = title + "\n====\n"
    found.reject{|key, value| value == []}.sort.each do |key, value|
      body += "\n### in <a href='#{uri(key)}'>#{escape(uri(key))}</a>\n"
      value.each {|v| body += link_list(v[0], v[1])}
    end

    res.body = header_html(title, path)\
             + search_form(uri(path), q)\
             + markdown(body)\
             + footer_html
    res.content_type = CONTENT_TYPE
    return res
  end

  def req_index(req, res)
    directory = fullpath(req.path)
    title = "Index of #{showpath(req.path)}"
    body = title + "\n====\n"

    recent = recent_files(directory)
    fs = directory_files(directory)

    body += "\nRecent:\n---\n" if RECENT_NUM > 0
    recent.each {|i| body += link_list(i[0], i[1])}

    body += "\nDirectories:\n----\n"
    fs[:dirs].each {|i| body += link_list(i[0], i[1])}

    body += "\nMarkdown documents:\n----\n"
    fs[:markdowns].each {|i| body += link_list(i[0], i[1])}

    body += "\nOther files:\n----\n"
    fs[:others].each {|i| body += link_list(i[0], i[1])}

    if index = indexfile(directory)
      body += "\n\n"
      body += File.read(index)
    end

    res.body = header_html(title, directory)\
             + search_form(uri(req.path))\
             + markdown(body)\
             + footer_html(index)
    res.content_type = CONTENT_TYPE
    return res
  end

  def req_file(filename, res, fileonly)
    open(filename) do |file|
      if markdown?(filename)
        str = file.read
        title = get_title(filename, str)
        body = header_html(title, filename)
        body += search_form(uri(filename)) if !fileonly
        body += markdown(str) + footer_html(filename)
        res.body = body
        res.content_type = CONTENT_TYPE
      else
        res.body = file.read
        res.content_type = WEBrick::HTTPUtils.mime_type(filename, WEBrick::HTTPUtils::DefaultMimeTypes)
        res.content_length = File.stat(filename).size
      end
    end
    return res
  end

  def find(directory, query)
    found = {}
    Find.find(directory) do |file|
      Find.prune if ignore?(file)
      dir = File::dirname(file)
      found[dir] = [] if !found[dir]
      if markdown?(file)
        open(file) do |f|
          c = f.read + "\n" + file
          found[dir] << [get_title(file,c), uri(file)] if !query.split(' ').map{|s| /#{s}/mi =~ c }.include?(nil)
        end
      elsif !query.split(' ').map{|s| /#{s}/ =~ File.basename(file)}.include?(nil)
        found[dir] << [get_title(file),uri(file)]
      end
    end
    return found
  end

  def recent_files(directory)
    recent = []
    if RECENT_NUM > 0 then
      Find.find(directory) do |file|
        Find.prune if ignore?(file)
        recent << file if File.file?(file) && file =~ RECENT_PATTERN
      end
      recent = recent.sort_by{|file| File.mtime(file)}.reverse.slice(0,RECENT_NUM)
      recent = recent.map{|file|
        if markdown?(file) then
          [get_title(file, open(file).read), uri(file)]
        else
          [escaped_basename(file), uri(file)]
        end
      }
    else
      recent = []
    end
    return recent
  end

  def directory_files(directory)
    dirs = []
    markdowns = []
    others = []
    Dir.entries(directory).each do |i|
      next if ignore?(i)
      link = uri(File.join(directory, i))
      if File.directory?(fullpath(link)) then
        dirs << [escaped_basename(link) + File::SEPARATOR, link]
      elsif markdown?(link)
        File.open(fullpath(link)) do |f|
          markdowns << [get_title(link, f.read), link]
        end
      else
        others << [escaped_basename(link), link]
      end
    end
    return {:dirs=>dirs, :markdowns=>markdowns, :others=>others}
  end

  def link_list(title, link)
    file = fullpath(link)
    str = filesize(file)
    return "- [#{title}](#{link}) <a class='filename' href=\"javascript:copy('#{docpath(link)}');\">[#{escaped_basename(link)}, #{str}]</a>\n"
  end

  def filesize(file)
    File.file?(file) ? sprintf("%.1fKB", File.size(file) / 1024.0) : "dir"
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
    return escaped_basename(filename) if !markdown?(filename)
    title = str.split(/$/)[0]
    return title =~ /^\s*$/ ? escaped_basename(filename) : title
  end

  def indexfile(dir)
    Dir.entries(dir).each do |f|
      if f =~ INDEX_PATTERN && markdown?(f)
        return dir + File::SEPARATOR + f
      end
    end
    return nil
  end

  def markdown(text)
    markdown = Redcarpet::Markdown.new(HTMLwithSyntaxHighlighter,
                                       {:strikethrough => true,
                                         :autolink => true,
                                         :fenced_code_blocks => true,
                                         :tables => true})
    markdown.render(text)
  end
end
