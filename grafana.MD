1. ### Installing Grafana:

```
wget -q -O gpg.key https://rpm.grafana.com/gpg.key
sudo rpm --import gpg.key
```

If this fails for some reason then go to  https://rpm.grafana.com/gpg.key and copy the key and store it in gpg.key file. Then do 'sudo rpm --import gpg.key'

2. ### Create /etc/yum.repos.d/grafana.repo with the following content:

```
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt

```

3. ### Install Grafana OSS

```
sudo dnf install grafana -y
```

4. ### Daemon reload
```
systemctl daemon-reload
```

5. ### Start grafana-server
```
systemctl start grafana-server
```

6. ### Enable grafana-server

```
systemctl enable grafana-server
```

7. ### check which port grafana is running on:

Usually it runs on 3000

```
netstat -lntp
```