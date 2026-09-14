# Talebook WebDAV fix

针对 Talebook `v26.09.01` 的 WebDAV 同步修复。

## 修复内容

Talebook 的用户同步目录通过 `MyBooksDavProvider` 创建 `FilesystemProvider`。在 WsgiDAV 4.3.5 下，目录资源创建时没有把用户的文件系统 provider 放回请求环境，导致 `PROPFIND` 目录请求使用外层 provider，出现以下错误：

```text
AttributeError: 'MyBooksDavProvider' object has no attribute 'fs_opts'
```

这个补丁处理了三件事：

- 为用户目录的 `FilesystemProvider` 设置 `fs_opts={}`；
- 让 `/books/reader/...` 生成的资源绑定到当前用户的文件系统 provider；
- 将公开的 `/reader/...` 路径映射到 `/data/reader/<user_id>/`，并设置 provider 的 `share_path`。

## 安装

将仓库克隆到运行 Talebook 的宿主机：

```sh
git clone https://github.com/molakesizhanfangguangmang/talebook-webdav-fix.git
cd talebook-webdav-fix
./install-webdav-fix.sh
```

默认操作名为 `talebook` 的容器，并检查版本必须为 `v26.09.01`。容器名可以覆盖：

```sh
CONTAINER=my-talebook ./install-webdav-fix.sh
```

安装前脚本会把容器内原始文件备份到当前仓库的 `backups/`，然后复制修复文件并重启容器。它不修改 `/data` 下的书库、账号或 WebDAV 同步文件。

## 文件说明

| 文件 | 用途 |
| --- | --- |
| `install-webdav-fix.sh` | 安装脚本 |
| `dav_provider.py` | 修复后的 provider 文件，脚本会把它复制进容器 |
| `dav_provider.py.patch` | 相对原始文件的 unified diff，供审阅改动范围 |
| `SHA256SUMS` | 上述文件的校验和 |

校验下载内容：

```sh
sha256sum -c SHA256SUMS
```

## 验证

使用 WebDAV 客户端访问：

```text
https://你的域名或地址/books/reader/
```

认证成功后，目录请求应返回 `207 Multi-Status`。可以用 curl 做只读验证：

```sh
curl --basic -u '用户名:密码' -X PROPFIND   -H 'Depth: 1'   -H 'Content-Type: application/xml'   --data '<?xml version="1.0"?><propfind xmlns="DAV:"><allprop/></propfind>'   'https://你的域名或地址/books/reader/'
```

不要把真实密码写入脚本、README 或仓库。

## 版本范围

当前 release 只针对 Talebook `v26.09.01`。安装脚本检测到其他版本时会停止，不覆盖目标文件。

这个仓库只包含 WebDAV 修复，不包含备份自动清理或设置页改动。
