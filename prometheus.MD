1. ### Download prometheus:

```
wget https://github.com/prometheus/prometheus/releases/download/v3.13.1/prometheus-3.13.1.linux-amd64.tar.gz
```
2. ### Uncompress the data

```
tar -xf prometheus-3.13.1.linux-amd64.tar.gz
```

3. ### Rename the uncompressed directory

```
mv prometheus-3.13.1.linux-amd64 prometheus
```

4. ### Create a systemd service for prometheus:

```
vim /etc/systemd/system/prometheus.service
```
And add the below content:

```
[Unit]
Description=Prometheus Monitoring System
Documentation=https://prometheus.io/docs/introduction/overview
After=network-online.target

[Service]
ExecStart=/opt/prometheus/prometheus  --config.file=/opt/prometheus/prometheus.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

5. ### Daemon reload:

```
systemctl daemon-reload 
```

5. ### Start Prometheus:

```
systemctl start prometheus
```

6. ### Check status of Prometheus:

```
systemctl status prometheus
```
Should be Active: active (running)

7. ### Enable Prometheus
```
systemctl enable prometheus
```

8. ### check which port prometheus is running on:
usually it runs on 9090

```
netstat -lntp
```
9. ### Alertmanager systemd 

```
[Unit]
Description=Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
WorkingDirectory=/opt/alertmanager/
ExecStart=/opt/alertmanager/alertmanager --config.file=/opt/alertmanager/alertmanager.yml

[Install]
WantedBy=multi-user.target
```