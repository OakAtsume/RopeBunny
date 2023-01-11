require("socket")
require("json")
require("openssl")
require("thread")
require("../libs/PanelUtils.rb")

Crypto = Cryptography.new
Handler = Request.new
Config = JSON.parse(File.read("../configs/Adminpanel.json"))
FireLock = FireLockUtils.new(Config["FireLock"]["db"])

TcpServer = TCPServer.new(Config["Server"]["Port"])
sslC = OpenSSL::SSL::SSLContext.new
sslC.cert = OpenSSL::X509::Certificate.new(File.read(Config["Server"]["sslCert"]))
sslC.key = OpenSSL::PKey::RSA.new(File.read(Config["Server"]["sslKey"]))
sslC.verify_mode = OpenSSL::SSL::VERIFY_NONE
sslC.options = OpenSSL::SSL::OP_NO_SSLv2 | OpenSSL::SSL::OP_NO_SSLv3

Server = OpenSSL::SSL::SSLServer.new(TcpServer, sslC)
Log("Socket: #{Config["Server"]["Port"]}")

loop do
  begin
    Thread.start(Server.accept) do |client|
      begin
        request = client.readpartial(Config["Server"]["maxReadBuffer"])
        request = Handler.parseHeader(request)
        if request.nil?
          client.close
          next
        end
      rescue => exception
        Log("Error: #{exception} : #{client}")
        next
      end
      ip = client.peeraddr[3]
      Log("Request: #{ip} : #{request["User-Agent"]} : #{request["Path"]}")
      if FireLock.isIpLocked(ip) || FireLock.isUaLocked(request["User-Agent"]) || FireLock.isPathLocked(request["Path"])
        Log("FireLock: #{ip} : #{request["User-Agent"]} : (Triggered)")
        page = File.read(Config["Paths"]["error"]["FireLock"])
        page = page.gsub(/<\/body>/, "<p>You have been blocked from accessing this site.</p></br><code>#{JSON.pretty_generate(request)}</code></body>")
        client.print("HTTP/1.1 403 Forbidden\r\n")
        client.print("Content-Type: text/html\r\n")
        client.print("Content-Length: #{page.size}\r\n")
        client.print("Connection: close\r\n\r\n")
        client.print(page)
        client.close
        if !FireLock.isIpLocked(ip)
          FireLock.add("IPs", ip)
          FireLock.refresh
        end
        next
      end
      if request["Cookie"] != nil && request["Path"] == "/index.html"
        cookieData = Handler.parseCookies(request["Cookie"])
        if !cookieData["token"].nil? || !cookieData["user"].nil?
          if File.exist?("#{Config["Database"]}/#{cookieData["user"]}.json")
            user = JSON.parse(File.read("#{Config["Database"]}/#{cookieData["user"]}.json"))
            if user["Token"] == cookieData["token"]
              Log("Auth: #{ip} : #{request["User-Agent"]} : (Success)")
              # Redirect to dashboard
              client.print("HTTP/1.1 302 Found\r\n")
              client.print("Location: /dashboard\r\n")
              client.print("Connection: close\r\n\r\n")
              client.close
              next
            else
              Log("Auth: #{ip} : #{request["User-Agent"]} : (Failed)")
              # Redirect to login
              client.print("HTTP/1.1 302 Found\r\n")
              client.print("Location: /login\r\n")
              client.print("Connection: close\r\n\r\n")
              client.close
              next
            end
          end
        end
      end

      if request["Path"] == "/api/auth"
        if request["Method"] != "POST"
          Log("Auth: #{ip} : #{request["User-Agent"]} : (Failed) : (Method Not Allowed)")
          client.print("HTTP/1.1 405 Method Not Allowed\r\n")
          client.print("Connection: close\r\n\r\n")
          client.close
          next
        end
        data = Handler.parseData(request["Body"])
        # Check if data has "username" and "password" keys if not return 400 Bad Request
        if data["username"].nil? || data["password"].nil?
          Log("Auth: #{ip} : #{request["User-Agent"]} : (Failed) : (Bad Request)")
          client.print("HTTP/1.1 400 Bad Request\r\n")
          client.print("Connection: close\r\n\r\n")
          client.close
          next
        end
        if File.exist?("#{Config["Database"]}/#{data["username"]}.json")
          user = JSON.parse(File.read("#{Config["Database"]}/#{data["username"]}.json"))
          if Crypto.check(data["password"], user["Hash"])
            Log("Auth: #{ip} : #{request["User-Agent"]} : (Success) : #{data["username"]}")
            # Redirect to dashboard
            token = Crypto.generateToken(255)
            client.print("HTTP/1.1 302 Found\r\n")
            client.print("Location: /dashboard\r\n")
            client.print("Set-Cookie: token=#{token}; path=/\r\n")
            client.print("Set-Cookie: user=#{data["username"]}; path=/\r\n")
            client.print("Connection: close\r\n\r\n")
            user["Token"] = token
            File.write("#{Config["Database"]}/#{data["username"]}.json", JSON.pretty_generate(user))
            next
          else
            Log("Auth: #{ip} : #{request["User-Agent"]} : (Failed) : #{data["username"]}:#{data["password"]}")
            # Redirect to login
            client.print("HTTP/1.1 302 Found\r\n")
            client.print("Location: /login\r\n")
            client.print("Connection: close\r\n\r\n")
            next
          end
        else
          Log("Auth: #{ip} : #{request["User-Agent"]} : (Failed) : (User Not Found)")
          # Redirect to login
          client.print("HTTP/1.1 302 Found\r\n")
          client.print("Location: /login\r\n")
          client.print("Connection: close\r\n\r\n")
          next
        end
        client.close
        next
      end

      # If request path is /dashboard check if user is logged in
      if request["Path"] == "/dashboard.html"
        if request["Cookie"] != nil
          cookieData = Handler.parseCookies(request["Cookie"])
          if !cookieData["token"].nil? || !cookieData["user"].nil?
            if File.exist?("#{Config["Database"]}/#{cookieData["user"]}.json")
              user = JSON.parse(File.read("#{Config["Database"]}/#{cookieData["user"]}.json"))
              if user["Token"] != cookieData["token"]
                Log("Auth: #{ip} : #{request["User-Agent"]} : (Failed)")
                # Redirect to login
                client.print("HTTP/1.1 302 Found\r\n")
                client.print("Location: /login\r\n")
                client.print("Connection: close\r\n\r\n")
                client.close
                next
              end
            end
          end
        else
          Log("Auth: #{ip} : #{request["User-Agent"]} : (Failed)")
          # Redirect to login
          client.print("HTTP/1.1 302 Found\r\n")
          client.print("Location: /login\r\n")
          client.print("Connection: close\r\n\r\n")
          client.close
          next
        end
        site = File.read("#{Config["Paths"]["root"]}/dashboard.html")
        # For each file in Config["Configs"]
        # Replace the <configs-1>
        #site.gsub!("<configs-1>", Config["Configs"].map { |k, v| "<option value=\"#{k}\">#{k}</option>" }.join(" "))
        configs = ""
        Config["Configs"].each do |file|
          data = File.read("#{file}")
          # configs += "<option value=\"#{file}\">#{file}</option>"
          configs += "<p> #{file} : #{file.size}</p>"
        end
        site.gsub!("[configs-1]", configs)
        puts site

        client.print("HTTP/1.1 200 OK\r\n")
        client.print("Content-Type: text/html\r\n")
        client.print("Content-Length: #{site.size}\r\n")
        client.print("Connection: close\r\n\r\n")
        client.print(site)
        client.close

        next
      end

      # Check if request path is valid and is in src/
      if File.exist?("#{Config["Paths"]["root"]}#{request["Path"]}") # 200 OK
        data = File.read("#{Config["Paths"]["root"]}/#{request["Path"]}")
        data = data.gsub(/<!--.*?-- >/, "")
        data = data.gsub(/\s+/, " ")
        client.print("HTTP/1.1 200 OK\r\n")
        client.print("Content-Type: text/html\r\n")
        client.print("Content-Length: #{data.size}\r\n")
        client.print("Connection: close\r\n\r\n")
        client.print(data)
        client.close
      else # 404 not found
        data = File.read(Config["Paths"]["error"]["404"])
        data = data.gsub(/<\/body>/, "<p>'#{request["Path"]}' Doesn't exist?</p></br><code>#{JSON.pretty_generate(request)}</code></body>")
        client.print("HTTP/1.1 404 Not Found\r\n")
        client.print("Content-Type: text/html\r\n")
        client.print("Content-Length: #{data.size}\r\n")
        client.print("Connection: close\r\n\r\n")
        client.print(data)
        client.close
      end
    end
  rescue => exception
    Log("Error: #{exception}")
  end
end
