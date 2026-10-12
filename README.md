# nas-im-bridge

<img src="mobile/web/icon.png" alt="IM Bridge generic phone icon" width="96">

**0.1.0** · [更新记录](CHANGELOG.md) · [Linux / NAS 部署](docs/linux-deployment.md) · [客户端适配](docs/qq-deployment.md)

把自己服务器上的桌面聊天客户端，变成适合 iPhone 竖屏使用的触控网页。

默认适配 **Linux QQ**，支持原生 **x86_64 / AMD64 和 ARM64** Docker 部署，包含高清画面、会话动画、侧滑返回、图片粘贴和可选消息推送。

这是独立的第三方工具，与腾讯及其关联公司没有关联，未获其授权或认可。客户端名称仅用于说明兼容性；项目使用自己的中性名称和通用手机图标，不包含企鹅或其他官方标识。

## 功能

- iPhone 竖屏与最高 3 倍高清绘制，会话列表与聊天文字采用独立比例。
- 完整画面就绪后切换会话，220 毫秒匀速过渡；边缘右滑返回，短距离滑动回弹。
- 合成图层滚动，复用高清像素；下一帧解码期间仍可滑动上一幅完整画面。
- 群聊只显示聊天区域，排除公告和成员侧栏，切换前后校验裁切范围。
- WebSocket 增量传输、滚动行复用和逐帧确认，断线后自动降级并重试。
- 文字发送立即清空已提交内容，保留后续输入，支持失败恢复与幂等请求。
- 照片、文件和剪贴板图片粘贴，发送前核对聊天对象。
- 客户端搜索、长按菜单、图片查看器、弹出窗口和完整桌面入口。
- 可选 Web Push、测试通知和内容预览开关，默认隐藏通知正文。
- 添加到主屏幕、独立网页登录、可选内网 IP HTTPS 配置。

## 快速安装

需要 64 位 Linux、Docker Engine、Compose v2 和 Bash。建议至少 4 GB 内存，并为镜像、构建缓存和账号数据预留磁盘空间。不需要宿主机桌面或 GPU。

```sh
git clone https://github.com/robavionix/nas-im-bridge.git
cd nas-im-bridge
bash scripts/setup.sh /absolute/path/im-bridge
cd /absolute/path/im-bridge
bash doctor.sh
docker compose up -d --build
docker compose ps
```

安装脚本默认选择 QQ 适配器，生成随机网页登录密码并保存在部署目录的 `.env` 中，拒绝覆盖已有目录。以 root 运行时，明确设置数据所属普通用户的 `PUID` / `PGID`，详见 [Linux / NAS 部署](docs/linux-deployment.md)。

为 `127.0.0.1:5805` 配置 HTTPS 反向代理或隧道，转发 Host、Origin 和 WebSocket Upgrade。**纯 HTTP 无法使用安全登录 Cookie。**

1. 通过自己的 HTTPS 地址打开 `/index.html`，使用 `.env` 中的 `WEB_PASSWORD` 登录网页。
2. 在远程桌面中完成官方客户端登录。
3. 打开 `/mobile/` 使用手机视图。Safari 可通过“分享 → 添加到主屏幕”创建入口。

客户端安装包由本机 Docker 构建从官方地址下载，固定版本与 SHA-256 校验值。仓库不包含安装包、账号数据或重新分发的客户端镜像。

## 内网 HTTPS

```sh
CHAT_ROOT=/absolute/path/im-bridge \
LAN_IP=192.168.1.20 LAN_CIDR=192.168.1.0/24 LAN_PORT=5844 \
bash scripts/setup-lan.sh
```

将示例 IP 和网段改为自己的网络。通过已经可信的 HTTPS 入口打开 `/mobile/lan-setup.html`，按说明安装根证书，并在 iPhone“设置 → 通用 → 关于本机 → 证书信任设置”开启完全信任。证书与私钥留在自己的部署目录，不提交到仓库。

## 可选消息推送

在部署目录创建 `config/mobile/push/settings.json`：

```json
{"origin":"https://chat.example.com"}
```

改为自己的公网 HTTPS origin，目录权限设为 `700`，文件权限设为 `600`，所有者与容器 `PUID` / `PGID` 一致，然后运行 `docker compose restart chat`。服务自动生成 VAPID 密钥。

iPhone 从主屏幕打开公网入口，在菜单开启“消息推送”，允许系统通知，再发送测试通知。内网 IP 入口不提供推送开关。实际来信依赖客户端产生标准桌面通知；静音会话、客户端焦点和手机通知设置会影响显示。测试通知只验证推送通道。

公网 origin 改变后，需要更新配置并重新添加和订阅网页。升级时保留 `config/mobile/push/`。

## 升级与数据隔离

源码与部署目录分开。升级前备份 `.env`、Compose、`config/`、证书和自定义网页资产，先在独立目录检查新版，再合并到原部署。不要用源码整目录覆盖账号数据目录。

本项目从 `nas-chat-mobile` 独立发布，使用自己的镜像名、容器名、网页存储键和 Cookie 前缀。新旧部署同时运行时，使用不同的 `HTTP_PORT`、HTTPS 入口和数据目录。

## 开发检查

```sh
python -m pip install -r mobile/requirements.txt
python -m unittest discover -s tests -p 'test_*.py'
for test in tests/*.cjs; do node "$test"; done
bash tests/test_deploy.sh
bash tests/test_lan.sh
```

这些测试不向真实联系人或推送端点发送消息。安装测试检查默认客户端、文件权限、私密文件排除、拒绝覆盖已有部署和架构校验。

## 工作原理与限制

手机通过 HTTPS 连接 nginx。Python 服务通过 X11 截取官方桌面客户端画面，执行点击、滚动、剪贴板和键盘操作，推送监听标准桌面通知，不读取聊天数据库或客户端通信协议。

- 一套部署对应一个共享桌面，多台手机会操作同一客户端。
- 界面由桌面截图生成，网络、远端响应和图片解码仍影响等待时间。
- 客户端升级可能改变布局、发送行为和通知，需要单独验证。
- 图片粘贴依赖 iOS 和来源 App 是否提供图片，无法粘贴时可用“＋”。
- 原生 amd64 / arm64 基础来自已验证的上游项目，具体 NAS 型号、内核和浏览器仍需实机检查。首版独立发布的检查范围见 [部署文档](docs/linux-deployment.md#验证范围)。

## 来源、标识与许可证

基于 [nas-chat-mobile 0.5.4](https://github.com/robavionix/nas-chat-mobile/tree/9a8d8f1) 的 QQ 适配代码独立发布，保留原作者版权声明，采用 [MIT License](LICENSE)。图标是上游原创的通用手机与消息线条图案，不含客户端商标图形。私人图标、截图、密码、证书和地址不在本仓库中。

第三方组件与客户端有各自的许可证和使用条款，本项目的 MIT 许可证不授予这些组件或商标的权利。请仅操作自己的账号，不用于群发、营销、监控他人或收集他人信息。软件按现状提供，详见许可证。

感谢 [LinuxServer](https://github.com/linuxserver/docker-baseimage-selkies) 与 [Selkies](https://github.com/selkies-project/selkies) 提供桌面基础。
