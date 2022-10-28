require("socket")
require("openssl")
require("thread")
require_relative("config.rb")

class Logs
  def initialize
    @file = File.open("server.log", "w")
  end
  def error(msg)
    @file.puts("#{Time.now}: Error (#{msg})")
    puts("Error: #{msg}")
  end
  def connection(msg)
    @file.puts("#{Time.now}: Connection (#{msg})")
    puts("Connection: #{msg}")
  end
  def permission(perm, msg)
    @file.puts("#{Time.now}: Permission-#{perm} (#{msg})")
    puts("Permission-#{perm}: #{msg}")
  end
  def close
    @file.close
  end
  def misc(msg)
    @file.puts("#{Time.now}: Misc (#{msg})")
    puts("Misc: #{msg}")
  end
  def bot(msg)
    @file.puts("#{Time.now}: Bot (#{msg})")
    puts("Bot: #{msg}")
  end
end

log = Logs.new
handler = TCPServer.new($config["port"])
sslContext = OpenSSL::SSL::SSLContext.new
sslContext.cert = OpenSSL::X509::Certificate.new(File.open($config["sslcert"]))
sslContext.key = OpenSSL::PKey::RSA.new(File.open($config["sslkey"]))
sslServer = OpenSSL::SSL::SSLServer.new(handler, sslContext)
log.misc("Server started on port #{$config["port"]}")

loop do
  begin
    Thread.start(sslServer.accept) do |client|
      headers = client.gets
      #if headers.to_s == ""
      # If header doesn't have strings then connection is closed
      if headers.length < 5
        # client.print("HTTP/1.1 400 Bad Request\r\n\r\n")
        client.print("RopeBunny-Daddy~\r\n")
        log.error("Empty request from #{client.peeraddr[3]}")
        client.close
        next
      end
      data = client.read_nonblock(1024)
      # If data contains the word "bot" or "crawler" then it's a bot
      if data.include?("bot") || data.include?("crawler") || data.include?("spider") || headers.include?("robots")
        log.bot("Bot detected Responsing with accept */*")
        client.puts("HTTP/1.1 200 OK\r\n\r\n")
        client.puts("User-Agent: */*\r\nAllow: */*\r\n\r\n")
        client.close
        next
      end

      log.connection("Received data from #{client.peeraddr[2]} : #{headers}")
      #if headers == ""
      #  client.puts("HTTP/1.1 400 Bad Request\r\n\r\n")
      #  client.puts("RopeBunny Server\r\n")
      #  log.error("No headers received from #{client.peeraddr[2]}")
      #  client.close
      #  next
      #end
      # read the data, and look for X-Forwarded and X-Real-IP
      #puts data.inspec
      
      if data.include?("X-Forwarded") || headers.include?("X-Forwarded")
        #puts "X-Forwarded-For"
        #puts data
        #puts data.split("X-Forwarded-For: ")[1].split("
        #")[0]
        ip = data.split("X-Forwarded-For: ")[1].split("
")[0]
        puts "Real IP: #{ip}"
      elsif data.include?("X-Real-IP")
        #puts "X-Real-IP"
        #puts data
        #puts data.split("X-Real-IP: ")[1].split("
        #")[0]
        ip = data.split("X-Real-IP: ")[1].split("
")[0]
        puts "Real IP: #{ip}"
      else
        ip = client.peeraddr[3]
      end

      if headers.include?("#{$blocks}")
        log.permission("Possible Exploit Blocked From #{client.peeraddr[2]}")
        client.close
        next
      end

      # If header has "tea".
      if headers.include?("tea")
        log.misc("Sending tea to #{client.peeraddr[2]}")
        client.puts("HTTP/1.1 200 OK\r\n\r\n")
        client.print File.read("#{$paths["teapot"]}")
        client.close
        next
      end
      if headers =~ /GET/
        file = headers.split[1].gsub(/\/\//, "/")
        fileExtension = file.split(".")[1]
        if $config["binaries"].include?(fileExtension)
          log.permission("file", "File-Requested: #{file} from #{client.peeraddr[2]}")
          if File.exist?("#{$paths["main"]}/#{file}")
            client.print("HTTP/1.1 200 OK\r\n\r\n")
            client.print(File.open("#{$paths["main"]}/#{file}", "rb").read)
            client.close
          else
            client.print("HTTP/1.1 404 Not Found\r\n\r\n")
            log.error("File-Not-Found: #{file} from #{client.peeraddr[2]} : Binary")
            client.close
          end
          next
        end
        if file == "/"
          file = "#{$paths["index"]}"
        elsif file == "/favicon.ico" || file == "/favico.ico"
          file = "#{$paths["favicon"]}"
        end
        if File.exist?("#{$paths["main"]}/#{file}")
          client.print("HTTP/1.1 200 OK\r\n\r\n")
          # Compressio
          data = File.open("#{$paths["main"]}/#{file}", "rb").read
          data = data.gsub(/\s+/, " ") # Remove new-lines
          data = data.gsub(/<!--.*?-->/, "") # Remove any comments (security)
          log.permission("file", "File-Requested: #{file} from #{client.peeraddr[2]}")
          client.print(data)
          client.close
          next
        else
          client.print("HTTP/1.1 404 Not Found\r\n\r\n")
          client.print("#{$err["404"]}")
          log.error("File-Not-Found: #{file} from #{client.peeraddr[2]}")
          client.close
          next
        end 
      end
      if headers =~ /POST/
        client.print("HTTP/1.1 200 OK\r\n\r\n")
        client.print("RopeBunny Server\r\n")
        log.permission("post", "POST request from #{client.peeraddr[2]}")
        client.close
        next
      end
      
    end
  rescue
    # Check if error was cause by a non-ssl connection
    if $!.to_s.include?("http request")
      log.error("Non-SSL connection terminated")
      next
    end
    log.error("Error in main loop : #{$!}")  
  end
end
