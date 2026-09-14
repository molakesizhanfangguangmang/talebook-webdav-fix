#!/bin/sh
# WebDAV 已经把文件写完后由 dav_provider.py 调用。
# 多个连续 PUT 合并成一次桥扫描；桥本身还有文件锁，重复触发也不会并发写。
set -eu

DATA=/data/.reading-progress-bridge
LOCK=/var/tmp/reading-progress-bridge/event-trigger.lock
mkdir -p "$(dirname "$LOCK")"

# 给 book.db / JSON 的原子替换和后续请求留一点时间。
sleep "${RPB_EVENT_DEBOUNCE:-5}"

if mkdir "$LOCK" 2>/dev/null; then
    trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT INT TERM
    exec python3 "$DATA/bridge.py" sync >>/var/tmp/reading-progress-bridge/run.log 2>&1
fi

# 已有一次触发在处理，交给它；五分钟兜底会再检查。
exit 0
