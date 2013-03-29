module Mamemose::Util
  def debug(tag, msg)
    STDERR.puts "#{tag}: #{msg}"
  end
end
