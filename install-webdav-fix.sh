#!/bin/sh
set -eu

CONTAINER=${CONTAINER:-talebook}
EXPECTED_VERSION=${EXPECTED_VERSION:-v26.09.01}
SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET=/var/www/talebook/webserver/webdav/dav_provider.py
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR=${BACKUP_DIR:-$SRC/backups}
BACKUP="$BACKUP_DIR/dav_provider.py.$STAMP"

command -v docker >/dev/null 2>&1 || { echo '找不到 docker' >&2; exit 1; }
docker inspect "$CONTAINER" >/dev/null 2>&1 || { echo "找不到容器: $CONTAINER" >&2; exit 1; }
mkdir -p "$BACKUP_DIR"
docker cp "$CONTAINER:$TARGET" "$BACKUP"

version=$(docker exec "$CONTAINER" sh -c "sed -n 's/^VERSION = \"\(.*\)\"/\1/p' /var/www/talebook/webserver/version.py" || true)
if [ "$version" != "$EXPECTED_VERSION" ]; then
    echo "Talebook 版本不匹配：检测到 ${version:-unknown}，需要 $EXPECTED_VERSION" >&2
    echo "原文件已备份到: $BACKUP" >&2
    exit 1
fi

# 检查当前文件确实是 Talebook WebDAV provider，避免覆盖错误目标。
docker exec "$CONTAINER" sh -c "grep -q 'class MyBooksDavProvider' '$TARGET'" || {
    echo "目标文件不是预期的 MyBooksDavProvider" >&2
    echo "原文件已备份到: $BACKUP" >&2
    exit 1
}

docker cp "$SRC/dav_provider.py" "$CONTAINER:$TARGET"
docker restart "$CONTAINER" >/dev/null
sleep 5

docker ps --filter "name=^${CONTAINER}$" --format '{{.Names}} {{.Status}}'
echo "WebDAV 修复已安装。"
echo "原文件备份: $BACKUP"
echo "验证: 用客户端访问 /books/reader/，应返回 207，而不是 500。"
