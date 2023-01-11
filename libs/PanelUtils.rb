require("json")
require("digest")

def Log(action)
  puts "[#{Time.now}] #{action}"
end

class Request
  def initialize; end

  def parseHeader(request)
    out = {}
    data = request.split("\r\n")
    out["Method"] = data[0].split(" ")[0]
    out["Path"] = data[0].split(" ")[1]
    out["Version"] = data[0].split(" ")[2]
    # Parsing headers
    data.each do |line|
      if line.include? ":"
        out[line.split(":")[0]] = line.split(":")[1]
      end
    end
    # Set the body as the rest of the data
    out["Body"] = data[data.length - 1]
    # Do some correction to the path.
    out["Path"] = autoCorrectPath(out["Path"])
    # If Path is / then set it to /index.html
    if out["Path"] == "/" || out["Path"] == ""
      out["Path"] = "/index.html"
    end
    if out["Path"] == "/login"
      out["Path"] = "/login.html"
    end
    if out["Path"] == "/dashboard"
      out["Path"] = "/dashboard.html"
    end


    return out
  end

  def autoCorrectPath(path)
    # If there's multiple // then correct it
    if path.include? "//"
      path = path.gsub("//", "/")
    end
    # If there's a / at the end of the path then remove it
    if path.end_with? "/"
      path = path[0..-2]
    end
    return path
  end

  def isRawFile(path, rules)
    if path.include? "."
      ext = path.split(".")[1]
    end
  end

  def parseData(data)
    out = {}
    # Make data a string
    data = data.to_s
    data = data.split("&")
    data.each do |line|
      out[line.split("=")[0]] = line.split("=")[1]
    end
    return out
  end

  def parseCookies(data)
    out = {}
    data = data.split("; ")
    data.each do |line|
      out[line.split("=")[0]] = line.split("=")[1]
    end
    # Remove the space in the name of the array Ex: " name" => "name" to "name" => "name"
    out = out.map { |k, v| [k.strip, v] }.to_h

    return out
  end

  def extractIp(request)
    # Check request for any X-Forwarded-For headers

    if (request["X-Forwarded-For"] != nil)
      return request["X-Forwarded-For"]
    else
      return request["Remote-Addr"]
    end
    # Check request for any X-Real-IP headers
    if (request["X-Real-IP"] != nil)
      return request["X-Real-IP"]
    else
      return request["Remote-Addr"]
    end
  end
end

class Cryptography
  def generateToken(size)
    random = Random.new
    output = ""
    size.times do
      output += random.rand(0..9).to_s
    end
    return output
  end

  def encrypt(data)
    return Digest::SHA256.hexdigest(data)
  end

  def check(raw, hash)
    input = Digest::SHA256.hexdigest(raw)
    return input == hash
  end
end

class FireLockUtils
  def initialize(config)
    @db = JSON.parse(File.read(config))
    @@config = config
  end

  def refresh
    @db = JSON.parse(File.read(@@config))
  end

  def isIpLocked(ip)
    return @db["IPs"].include?(ip)
  end

  def isUaLocked(ua)
    return @db["UserAgents"].include?(ua)
  end

  def isPathLocked(path)
    return @db["Paths"].include?(path)
  end

  def add(type, value)
    if type != "IPs" && type != "UserAgents" && type != "Paths"
      raise "Invalid type"
    end
    @db[type].push(value)
    File.write(@@config, JSON.pretty_generate(@db))
  end
end
