#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx

mkdir -p /var/www/aej
cat <<HTML >/var/www/aej/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>AEJ Slim</title>
</head>
<body>
  <h1>AEJ Slim frontend</h1>
  <p>Instance: $(hostname)</p>
  <p>Serving via Nginx on port 5173</p>
</body>
</html>
HTML

cat <<'NGINX' >/etc/nginx/sites-available/aej-5173
server {
    listen 5173 default_server;
    listen [::]:5173 default_server;
    root /var/www/aej;
    index index.html;
    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/aej-5173 /etc/nginx/sites-enabled/aej-5173
if [ -f /etc/nginx/sites-enabled/default ]; then
  rm /etc/nginx/sites-enabled/default
fi

systemctl enable nginx
systemctl restart nginx
