$config = {
  "port" => 8080,
  "sslkey" => 'ssl/server.key',
  "sslcert" => 'ssl/server.crt',
  "binaries" => ["ico", "png", "jpeg", "jpg", "gif"]
}
$paths = {
  "main" => "src",
  "index" => "index.html",
  "favicon" => "favicon.ico",
  "teapot" => "src/teapot.html",
}
$err = {
  "404" => "<html><head><title>404 Not Found</title></head><body><h1 style='text-align: center'>Sowwy this doesn't exist!</h1></body></html>",
}
$blocks = [
  "/wp-",
  "/.env",
  "/.bashrc",
  "/etc",
  "/passwd"
]
