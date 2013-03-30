conf = File.expand_path("~" + File::SEPARATOR + ".mamemose.rb")
load conf if File.exists?(conf)

HOST= 'localhost' if !defined?(HOST)
DOCUMENT_ROOT = "~/Dropbox/memo" if !defined?(DOCUMENT_ROOT)
PORT = 20000 if !defined?(PORT)
WS_PORT = 20001 if !defined?(WS_PORT)
RECENT_NUM = 10 if !defined?(RECENT_NUM)
RECENT_PATTERN = /.*/ if !defined?(RECENT_PATTERN)
IGNORE_FILES = ['.DS_Store','.AppleDouble','.LSOverride','Icon',/^\./,/~$/,
                '.Spotlight-V100','.Trashes','Thumbs.db','ehthumbs.db',
                'Desktop.ini','$RECYCLE.BIN',/^#/,'MathJax','syntaxhighlighter'] if !defined?(IGNORE_FILES)
MARKDOWN_PATTERN = /\.(md|markdown)$/ if !defined?(MARKDOWN_PATTERN)
INDEX_PATTERN = /^README/i if !defined?(INDEX_PATTERN)
CUSTOM_HEADER = '' if !defined?(CUSTOM_HEADER)
CUSTOM_BODY = '' if !defined?(CUSTOM_BODY)
CUSTOM_FOOTER = '' if !defined?(CUSTOM_FOOTER)

CONTENT_TYPE = "text/html; charset=utf-8"
DIR = File::expand_path(DOCUMENT_ROOT, '/')
