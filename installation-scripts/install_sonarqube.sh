#!/bin/bash

# System configuration
sudo cp /etc/sysctl.conf /root/sysctl.conf_backup
cat <<EOT | sudo tee /etc/sysctl.conf
vm.max_map_count=262144
fs.file-max=65536
ulimit -n 65536
ulimit -u 4096
EOT

sudo cp /etc/security/limits.conf /root/sec_limit.conf_backup
cat <<EOT | sudo tee /etc/security/limits.conf
sonarqube   -   nofile   65536
sonarqube   -   nproc    4096
EOT

# Install Java
sudo apt update && sudo apt install -y openjdk-17-jdk
sudo update-alternatives --config java

# Install PostgreSQL
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt install -y postgresql postgresql-contrib

# Configure PostgreSQL
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo -u postgres psql -c "CREATE USER sonar WITH ENCRYPTED PASSWORD 'admin123';"
sudo -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;"

# Install SonarQube
sudo mkdir -p /sonarqube/
cd /sonarqube/
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.7.96285.zip
sudo apt install -y unzip
sudo unzip -o sonarqube-9.9.7.96285.zip -d /opt/
sudo mv /opt/sonarqube-9.9.7.96285/ /opt/sonarqube

# Configure SonarQube user
sudo groupadd sonar
sudo useradd -c "SonarQube - User" -d /opt/sonarqube/ -g sonar sonar
sudo chown sonar:sonar /opt/sonarqube/ -R

# Configure sonar.properties
sudo cp /opt/sonarqube/conf/sonar.properties /root/sonar.properties_backup
cat <<EOT | sudo tee /opt/sonarqube/conf/sonar.properties
sonar.jdbc.username=sonar
sonar.jdbc.password=admin123
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.javaAdditionalOpts=-server
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:+HeapDumpOnOutOfMemoryError
sonar.log.level=INFO
sonar.path.logs=logs
EOT

# Create systemd service
cat <<EOT | sudo tee /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOT

# Start SonarQube
sudo systemctl daemon-reload
sudo systemctl enable sonarqube.service
sudo systemctl start sonarqube.service

# Configure Nginx as reverse proxy
sudo apt install -y nginx
cat <<EOT | sudo tee /etc/nginx/sites-available/sonarqube
server {
    listen 80;
    server_name sonarqube.example.com;

    access_log /var/log/nginx/sonar.access.log;
    error_log /var/log/nginx/sonar.error.log;

    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    location / {
        proxy_pass http://127.0.0.1:9000;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_redirect off;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
    }
}
EOT

sudo ln -s /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/
sudo systemctl enable nginx
sudo systemctl restart nginx