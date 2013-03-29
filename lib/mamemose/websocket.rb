require 'em-websocket'
require 'thread'

require 'mamemose/version'

require 'mamemose/path'
require 'mamemose/util'

require 'mamemose/env'

class Mamemose::WebSocket::Server
  include Mamemose::Path
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

      ws.onmessage { |uri|
        # receive url from client
        if File.exists?(fullpath(uri))
          # connections are managed as tuple of (socket, url, mtime_cache)
          con = {:ws => ws, :uri => uri, :mtime_cache => get_mtime(uri)}
          @mutex.synchronize do
            @connections.push(con) unless @connections.index(con)
            debug(@tag, "added path to watch: #{uri}. now watch #{uris.to_s}")
          end
        end
      }

      ws.onclose {
        debug(@tag, "closed.")
        # when a connection is closed, delete it from @connections
        @mutex.synchronize do
          @connections.delete_if { |con| con[:ws] == ws }
          debug(@tag, "closed and removed path. now watch #{uris.to_s}")
        end
      }
    end
  end

  def watcher
    loop do
      # gather uris to watch using mutex
      watch_uris = []
      @mutex.synchronize do
        watch_uris = uris
      end

      # gather mtimes of watch_uris
      mtimes = {}
      watch_uris.uniq.each do |uri|
        if File.exists?(fullpath(uri))
          # get mtime
          mtimes[uri] = get_mtime(uri)
        else
          # file no longer exists. remove the entry
          @mutex.synchronize do
            @connections.delete_if { |con| con[:uri] == uri }
            debug(@tag, "detected deletion: #{uri} and updated the list. now watch #{uris.to_s}")
          end
        end
      end

      # push notification if watching file is updated
      to_notify = []
      @mutex.synchronize do
        @connections.each do |con|
          uri = con[:uri]
          if con[:mtime_cache] < mtimes[uri]
            debug(@tag, "detected update: #{uri}. pushing...")
            con[:mtime_cache] = mtimes[uri]
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

  def uris
    @connections.map{ |con| con[:uri] }
  end

  def get_mtime(uri)
    File.mtime(fullpath(uri)) if File.exists?(fullpath(uri))
  end
end
