# Linux 与 NAS 部署

支持 64 位 Linux x86_64 / amd64 与 ARM64。宿主机需要 Docker Engine、Compose v2 和 Bash，不需要宿主机 Python、X11、GPU 或桌面。

## 准备独立目录

```sh
git clone https://github.com/robavionix/nas-im-bridge.git
cd nas-im-bridge
bash scripts/setup.sh /srv/im-bridge
cd /srv/im-bridge
bash doctor.sh
docker compose up -d --build
docker compose ps
```

路径应改为自己的目录，源码不能充当部署目录。脚本拒绝覆盖任何已有目标，不读取其他部署的账号、密码或通知订阅。以 root 或 sudo 运行时，指定拥有数据的普通用户：

```sh
sudo PUID="$(id -u)" PGID="$(id -g)" bash scripts/setup.sh /srv/im-bridge
```

部署目录包含 Dockerfile、Compose、随机密码 `.env`、启动脚本和 `config/`。只有 `config/mobile/web/` 单独只读挂载供 nginx 使用，其余账号数据保持私有权限。

## 访问

容器只绑定 `127.0.0.1:5805`。通过自己的 HTTPS 代理或隧道访问，转发 Host、Origin 和 WebSocket Upgrade。先打开 `/index.html` 完成客户端登录，再打开 `/mobile/`。

网页登录密码位于 `.env` 的 `WEB_PASSWORD`。安全 Cookie 要求 HTTPS。多个部署应分别设置 `HTTP_PORT` 与 `CONTAINER_NAME`，使用独立数据目录和入口。

## 群晖

在支持 Docker 的机型上安装 Container Manager 或 Docker，通过 SSH 在本地卷运行：

```sh
git clone https://github.com/robavionix/nas-im-bridge.git /volume1/docker/nas-im-bridge
cd /volume1/docker/nas-im-bridge
sudo PUID="$(id -u)" PGID="$(id -g)" bash scripts/setup.sh /volume1/docker/im-bridge
cd /volume1/docker/im-bridge
sudo bash doctor.sh
sudo docker compose up -d --build
```

所选普通用户需要有对应卷的权限。CPU / 内核须满足 Docker 和客户端要求，不能仅凭机型系列判断兼容性。使用旧版独立 `docker-compose` 的系统，应先准备 Compose v2。

## 架构与资源

本机 Docker 选择基础镜像架构，下载对应 amd64 / arm64 官方包并验证架构和 SHA-256。不要设置与宿主机不同的 `DOCKER_DEFAULT_PLATFORM`。

默认 3 倍原生绘制、4200 × 6000 桌面、4 GB 容器内存上限和 1 GB 共享内存。资源有限时可调整 `.env`：

```dotenv
QQ_UI_SCALE=2
DESKTOP_WIDTH=2800
DESKTOP_HEIGHT=4000
```

修改后运行 `docker compose up -d --force-recreate`。手机键盘只改变网页可见区域，不需要横屏。

## 升级与迁移

备份 `.env`、Compose、`config/` 和 `lan-proxy/`。先准备新测试部署并验证，再合并应用脚本、网页文件、Dockerfile 和启动配置。

不要覆盖会话密钥、发送记录、推送密钥和订阅、账号配置、证书或自定义网页资产。新旧项目使用不同服务和网页登录标识，建议独立部署，不要把新启动脚本混进正在使用的旧容器。

跨架构迁移时，在目标机器本机构建，不复制旧架构的 Python 虚拟环境、`push-deps/` 或客户端二进制。

## 验证范围

继承上游 0.5.4 的原生 amd64 / arm64 适配和 iPhone 修正。独立发布检查覆盖 Python / JavaScript 回归、默认 QQ 安装、权限、私密文件排除、拒绝覆盖、架构校验和 Compose 配置。

真实账号发送、主屏幕图标、锁屏通知、iPhone 手势与具体 NAS 型号仍需对应设备验证。`tests/smoke_container.py` 仅用于未登录的临时容器。
