module Mamemose::Path
  # returns escaped characters so that the markdown parser doesn't interpret it has special meaning.
  def escape(text)
    return text.gsub(/[\`*_{}\[\]()#+\-.!]/, "\\\\\\0")
  end

  # returns /-rooted path. eg. /path/to/my_document.md
  def uri(path)
    s = File::expand_path(path).gsub(DIR, "").gsub(File::SEPARATOR, '/')
    return s == '' ? '/' : s
  end

  # returns fullpath. eg. /home/daimatz/Dropbox/memo/path/to/my_document.md
  def fullpath(uri)
    return File.join(DIR, uri.gsub(DIR, '').gsub('/', File::SEPARATOR))
  end

  # returns DOCUMENT_ROOT-rooted path. eg. ~/Dropbox/memo/path/to/my_document.md
  def docpath(uri)
    return File.join(DOCUMENT_ROOT, uri.gsub('/', File::SEPARATOR)).gsub(/#{File::SEPARATOR}$/, "")
  end

  # returns DOCUMENT_ROOT-rooted path, but escaped.  eg. ~/Dropbox/memo/path/to/my\_document.md
  # used in user-viewable (HTML) context.
  def showpath(uri)
    return escape(docpath(uri))
  end

  def escaped_basename(filename)
    return escape(File::basename(filename))
  end
end
