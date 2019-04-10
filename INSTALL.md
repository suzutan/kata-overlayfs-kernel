# kata-container のインストールから guest kernel を作り直して起動するまでの流れ

kata-container 上で overlayfs を使って Docker in Docker をするためのやつ。

## 検証環境

- ContainerLinux stable:2023.5.0 ( kernel 4.19.25 )
- kata-container 1.6.1 ( guest kernel 4.19.24)

## kata-container のインストール

kata-container に必要な prebuild binaries のインストールと docker の runtime 設定を行ってくれる katadocker/kata-deploy があるので、それを使う

```bash
sudo docker run -v /opt/kata:/opt/kata -v /var/run/dbus:/var/run/dbus -v /run/systemd:/run/systemd -v /etc/docker:/etc/docker -it katadocker/kata-deploy kata-deploy-docker install
```

ContainerLinux の Docker は selinux が enable になっているが、kata-runtime は非対応のため、 disable にする

```bash
mkdir -p /etc/systemd/system/docker.service.d/
cat << 'EOL' | sudo tee /etc/systemd/system/docker.service.d/docker-selinux.conf
[Service]
Environment="DOCKER_SELINUX=--selinux-enabled=false"
EOL

sudo systemctl daemon-reload
sudo systemctl restart docker
```

## guest kernel の更新

```bash
docker build -t local-kata-build .
```

docker create local-kata-build
