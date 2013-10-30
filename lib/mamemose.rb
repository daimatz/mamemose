require 'rubygems'
require 'webrick'
require 'find'
require 'uri'
require 'redcarpet'
require 'htmlentities'
require 'coderay'

require 'mamemose/version'

require 'mamemose/html'
require 'mamemose/path'

require 'mamemose/env'

class HTMLwithSyntaxHighlighter < Redcarpet::Render::XHTML
  def block_code(code, lang)
    lang ||= 'plain'
    CodeRay.scan(code, lang.to_sym).div(:line_numbers => :table)
  end
end

class Mamemose::Server
  include Mamemose::Path
  include Mamemose::HTML

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
    title = str.split(/$/)[0].gsub(/^#*\s*/, '')
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
