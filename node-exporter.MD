1. ### Install node exporter
```
wget https://github.com/prometheus/node_exporter/releases/download/v1.12.1/node_exporter-1.12.1.linux-amd64.tar.gz
```

2. ### Uncompress

```
 tar -xf node_exporter-1.12.1.linux-amd64.tar.gz

```

3. ### Rename the directory

```
mv node_exporter-1.12.1.linux-amd64 node_exporter
```

4. ### Create a systemd service for node_exporter

```
vim /etc/systemd/system/node_exporter.service
```

```
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/node_exporter/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

5. ### Daemon reload:

```
systemctl daemon-reload 
```

5. ### Start node_exporter:

```
systemctl start node_exporter
```

6. ### Check status of node_exporter:

```
systemctl status node_exporter
```
Should be Active: active (running)

7. ### Enable node_exporter
```
systemctl enable node_exporter
```

8. ### check which port node_exporter is running on:
usually it runs on 9100

```
netstat -lntp
```
