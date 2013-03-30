module Mamemose::HTML
  def header_html(title, fullpath)
    html = <<HTML
<!DOCTYPE HTML>
<html>
<head>
<meta http-equiv="Content-Type" content="#{CONTENT_TYPE}" />
<title>#{title}</title>
<style><!--
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
  ws = new WebSocket("ws://#{HOST}:#{WS_PORT}");
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

  def link_list(title, link)
    file = fullpath(link)
    str = filesize(file)
    return "- [#{title}](#{link}) <a class='filename' href=\"javascript:copy('#{docpath(link)}');\">[#{escaped_basename(link)}, #{str}]</a>\n"
  end
end
