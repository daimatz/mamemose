require 'em-websocket'
require 'thread'

require 'mamemose/version'

require 'mamemose/path'
require 'mamemose/util'

require 'mamemose/env'

class Mamemose::WebSocket::Server
  include Mamemose::Util

  @@update_send_message = "updated"

  def initialize
    @connections = []
    @mutex = Mutex::new
    @tag = "WebSocket"
  end

  def start
    Thread.new do
      debug(@tag, "start watcher...")
      watcher
    end

    EventMachine::WebSocket.start(:host => '0.0.0.0', :port => WS_PORT) do |ws|
      ws.onopen {
        debug(@tag, "connected.")
        ws.send("connected.")
      }

      ws.onmessage { |fullpath|
        # receive url from client
        debug(@tag, "receive: #{fullpath}")
        if File.exists?(fullpath)
          # connections are managed as tuple of (socket, url, mtime_cache)
          con = {:ws => ws, :fullpath => fullpath, :mtime_cache => get_mtime(fullpath)}
          @mutex.synchronize do
            @connections.push(con) unless @connections.index(con)
            debug(@tag, "added path to watch: #{fullpath}. now watch #{fullpaths.to_s}")
          end
        end
      }

      ws.onclose {
        debug(@tag, "closed.")
        # when a connection is closed, delete it from @connections
        @mutex.synchronize do
          @connections.delete_if { |con| con[:ws] == ws }
          debug(@tag, "closed and removed path. now watch #{fullpaths.to_s}")
        end
      }
    end
  end

  def watcher
    loop do
      # gather paths to watch using mutex
      watch_fullpaths = []
      @mutex.synchronize do
        watch_fullpaths = fullpaths
      end

      # gather mtimes of watch_fullpaths
      mtimes = {}
      watch_fullpaths.uniq.each do |fullpath|
        if File.exists?(fullpath)
          # get mtime
          mtimes[fullpath] = get_mtime(fullpath)
        else
          # file no longer exists. remove the entry
          @mutex.synchronize do
            @connections.delete_if { |con| con[:fullpath] == fullpath }
            debug(@tag, "detected deletion: #{fullpath} and updated the list. now watch #{fullpaths.to_s}")
          end
        end
      end

      # push notification if watching file is updated
      to_notify = []
      @mutex.synchronize do
        @connections.each do |con|
          fullpath = con[:fullpath]
          if mtimes[fullpath] && con[:mtime_cache] < mtimes[fullpath]
            debug(@tag, "detected update: #{fullpath}. pushing...")
            con[:mtime_cache] = mtimes[fullpath]
            to_notify << con
          end
        end
      end
      to_notify.each do |con|
        con[:ws].send(@@update_send_message)
      end

      sleep 1
    end
  end

  def fullpaths
    @connections.map{ |con| con[:fullpath] }
  end

  def get_mtime(fullpath)
    File.mtime(fullpath) if File.exists?(fullpath)
  end
end
