#!/bin/bash
# ports 卸载脚本：移除守护与 CLI，保留登记数据
set -euo pipefail

DEST="$HOME/.local/bin/ports"

if [[ -x "$DEST" ]]; then
  "$DEST" daemon uninstall || true
  rm -f "$DEST"
  echo "✓ 已移除 $DEST"
else
  echo "• 未找到 $DEST，跳过"
fi

echo "✓ 登记数据保留在 ~/.config/ports/（registry.json / events.log）"
echo "  彻底清除请执行：rm -rf ~/.config/ports"
