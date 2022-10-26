require "socket"
require "openssl"
require "json"

Paths = {
  "keys" => "ssl"
}
# Set the SSL certificate and key
# New TCP server with SSL

server = TCPServer.new(8080)
ssl_context = OpenSSL::SSL::SSLContext.new
ssl_context.cert = OpenSSL::X509::Certificate.new(File.open("#{Paths["keys"]}/server.crt").read)
ssl_context.key = OpenSSL::PKey::RSA.new(File.open("#{Paths["keys"]}/server.key").read)
ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE

#ssl_context.ssl_version = :TLSv1

# ssl_context.ciphers = "ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW"

ssl_server = OpenSSL::SSL::SSLServer.new(server, ssl_context)
ssl_server.start_immediately = true
loop do
  # SSL_accept returned=1 errno=0 peeraddr=(null) state=error: tlsv1 alert unknown ca (OpenSSL::SSL::SSLError)
  # Fix this error
  #ssl_client = ssl_server.accept
  #request = ssl_client.gets
  # Parse request as a HTTP request
  #puts request
  #ssl_client.print "HTTP/1.0 200 OK\r\n\r\n"
  #ssl_client.close
  # Try Catch
  begin
    Thread.start(ssl_server.accept) do |client|
      request = client.gets
      full_request = client.read_nonblock(1024)
      puts "#{client.peeraddr[2]}:#{client.peeraddr[1]} #{request}"

      # Parse request as a HTTP request
      #puts request
      ### client.print "HTTP/1.0 200 OK\r\n\r\n"
      # if request is GET
      #
        if request =~ /GET/
          # Send Favico
          # Read the file being requested
          # Sent favicon <link rel="icon" type="image/x-icon" href="src/img/favicon.ico"
          #client.print "<link rel=\"icon\" type=\"image/x-icon\" href=\"src/favicon.ico\">"
          filename = request.split[1].gsub(/\/\//, "/")
          #puts "GET #{filename} from #{client.peeraddr[2]}"
          # If filename is .ico, .png, .jpg then send the file as binary
          if filename.include?('ico') || filename.include?('png') || filename.include?('jpg') || filename.include?("gif")
            puts "Sending #{filename} Image as binary"
            client.print "HTTP/1.0 200 OK\r\n\r\n"
            client.print File.open("src/#{filename}", "rb").read
            client.close
            next

          end
          if filename == "/"
            filename = "/index.html"
          end
          # If request is favicon request then set filename to favicon
          if filename.include? "favicon"
            filename = "/favicon.ico"
          end
          if filename == "/owo"
            client.print "HTTP/1.0 200 OK\r\n\r\n"
            # Send an owo message
            client.print "<title>owo</title>"
            client.print "<style>body{background-color: #000000; color: #FFFFFF; text-align: center;}</style><h1>owo</h1>"
            client.puts "Hewwo #{client.peeraddr[2]}, I'm a server!"
            puts "Said OwO to #{client.peeraddr[2]}"
            client.close
            next
          end
          if filename == "/naughty"
            client.print "HTTP/1.0 200 OK\r\n\r\n"
            client.print "<title>Naughty Naughty Little Toy~</title>"
            client.print "<style>body{background-color: #000000; color: #FFFFFF; text-align: center;}</style><h1>Naughty Naughty Little Toy~</h1>"
            client.print "<p> what ever will I do with you~? </p>"
            puts "#{client.peeraddr[2]} is feeling naughty~"
            client.close
            next
          end
          if filename == "/tea"
            client.print "HTTP/1.0 418 I'm a teapot\r\n\r\n"
            client.print "<title> I'm a teapot </title>"
            puts "418: I'm a teapot From(#{client.peeraddr[2]})"
            client.close
            next
          end

          if File.exist?("src/#{filename}")
            client.print "HTTP/1.0 200 OK\r\n\r\n"
            # client.print("<link rel=\"icon\" type=\"image/x-icon\" href=\"src/favicon.ico\">\r\n")
            file = File.open("src/#{filename}", "r")
            # Send file to the client
            file = file.read
            client.puts file.gsub!(/\s+/, ' ')

            puts "200 Ok: #{filename} : #{client.peeraddr[2]}"
          else
            # If request is only / then send index.html
            client.print "HTTP/1.0 404 Not Found\r\n\r\n"
            file = File.open("src/404.html", "r")
            client.puts file.read
            file.close
            puts "404 Not Found: #{filename} : #{client.peeraddr[2]}"
            # Send a 404 error to the client
            #client.puts "404 Not Found"
          end
      end

      # if request is POST
      if request =~ /POST/
        client.print "HTTP/1.0 403 FORBIDDEN\r\n\r\n"
        # Read the data that was been sent from the POST request
        data = client.read_nonblock(1024)
        client.print "Blocked { #{data} }"
        puts "POST from #{client.peeraddr[2]} (Blocked)"
      end
      client.close
    end
    rescue 
      puts "Error : #{$!}"
    end
end
