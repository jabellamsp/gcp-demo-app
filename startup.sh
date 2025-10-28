#!/bin/bash
apt-get update
apt-get install -y nginx ssl-cert

INSTANCE_NAME=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/name" -H "Metadata-Flavor: Google")
ZONE=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google" | awk -F/ '{print $4}')

cat > /var/www/html/index.html << HTML
<!DOCTYPE html>
<html>
<head><title>GCP Demo App</title></head>
<body>
<h1>✅ GCP Demo: Secure Web App</h1>
<p><strong>Instance:</strong> $INSTANCE_NAME</p>
<p><strong>Zone:</strong> $ZONE</p>
<p><em>Deployed via Terraform + GitHub CI/CD</em></p>
</body>
</html>
HTML

make-ssl-cert generate-default-snakeoil --force-overwrite
cp /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/nginx-selfsigned.crt
cp /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/nginx-selfsigned.key

cat > /etc/nginx/sites-available/default << NGINX
server {
    listen 80;
    root /var/www/html;
    index index.html;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
server {
    listen 443 ssl;
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    root /var/www/html;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
NGINX

systemctl restart nginx

# Install Ops Agent for monitoring
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install
