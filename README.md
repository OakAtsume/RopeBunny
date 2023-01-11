# RopeBun (experimental)
Web Server written completly in Ruby using the sockets/openssl libs :D </br>

## Features
* Built-in HTML Compression system </br>
* Built-in anti-comment security </br>
* Fast CSR (Client side rendering) </br>
* Stable, Small, and reliable by design </br>

## Features
* SSR (Server Side rendering system) </br>
* Built-in data parsing utils </br>
* Login data with SHA256 hashing </br>
* Cookie based Auth (with a token generation function) </br>
* Modular! </br>


## Classes
* Cryptography
```ruby
generateToken(token_size) # Ex: generateToken(25)
=> 1687766340791736186065732"
encrypt(raw_data) # Ex: encrypt("I love you!")
=> c22fe0282c7b45b0926fb3e33efd375a5e195c4c838c96075e3877b2ac2b7911 # SHA256 for "I love you!"
check(raw_data, hash) # Ex: check("I love you!", "c22fe0282c7b45b0926fb3e33efd375a5e195c4c838c96075e3877b2ac2b7911")
=> true
```
* Firelock
```ruby
refresh() # Refreshes the Firelock
# Block checks #
isIpLocked(ip)
=> true/false
isUaLocked(UserAgent)
=> true/false
isPathLocked(Path)
=> true/false
add(type, value) # Ex: add("IPs", "0.0.0.0")
=> 0.0.0.0 will be added to the block list
```

* Request
```ruby
# Ex: header = "Blah: 00\r\n\r\nData=1&Data2=2
parseHeader(header)
=> Hash["Blah"]=00, Hash["Body"]="Data=1&Data2=2" # To parse this check bellow*
parseData(data) # Ex: data = Data=1&Data2=2
=> Hash["Data"]=1, Hash["Data2"]=2
parseCookies(cookies) # Ex: cookies = username="blah";
=> Hash["username"]="blah"
extractIp(raw_request)
=> X-Forwarded-Ip: 0.0.0.0
```
