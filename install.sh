#!/bin/bash
# ports — 本地端口监控工具安装脚本
# 用法：
#   ./install.sh              安装 CLI + 常驻守护
#   ./install.sh --no-daemon  只装 CLI，不装守护
#   ./install.sh --add-path   同时把 ~/.local/bin 写入 ~/.zshrc 的 PATH
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/bin/ports"
DEST_DIR="$HOME/.local/bin"
DEST="$DEST_DIR/ports"

if [[ ! -f "$SRC" ]]; then
  echo "✗ 未找到 $SRC，请在仓库目录内运行本脚本" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
# 拷贝而非软链：移动硬盘拔掉后 CLI 与守护照常工作
cp "$SRC" "$DEST"
chmod +x "$DEST"
echo "✓ 已安装 $DEST"

# 网页面板文件
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
UI_DIR="$HOME/.local/share/ports"
if [[ -f "$SRC_DIR/bin/ports-ui.html" ]]; then
  mkdir -p "$UI_DIR"
  cp "$SRC_DIR/bin/ports-ui.html" "$UI_DIR/ports-ui.html"
  echo "✓ 已安装网页面板 $UI_DIR/ports-ui.html"
fi

# 双击启动器：放在项目文件夹里，好找好记
LAUNCHER="$SRC_DIR/端口面板.command"
printf '#!/bin/bash\nexec "$HOME/.local/bin/ports" ui\n' > "$LAUNCHER"
chmod +x "$LAUNCHER"
rm -f "$HOME/Applications/端口面板.command"   # 清理旧位置的启动器
echo "✓ 已创建双击启动器 $LAUNCHER"

# PATH 检查
if [[ ":$PATH:" != *":$DEST_DIR:"* ]]; then
  if [[ "${1:-}" == "--add-path" ]]; then
    if grep -q '\.local/bin' "$HOME/.zshrc" 2>/dev/null; then
      echo "• ~/.zshrc 已有 PATH 配置，跳过"
    else
      cat >> "$HOME/.zshrc" <<'EOF'

# >>> ports CLI PATH >>>
export PATH="$HOME/.local/bin:$PATH"
# <<<
EOF
      echo "✓ 已在 ~/.zshrc 追加 PATH，新开终端生效"
    fi
  else
    echo "⚠ $DEST_DIR 不在 PATH 中。将其加入 PATH："
    echo "    ./install.sh --add-path   （自动追加到 ~/.zshrc）"
    echo "  或手动执行： echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
  fi
fi

# 常驻守护（失败不中断安装，守护可能只是启动慢）
if [[ "${1:-}" != "--no-daemon" ]]; then
  if ! "$DEST" daemon install; then
    echo "⚠ 守护安装步骤报失败，请稍后用 ports daemon status 复核；"
    echo "  仍失败可查看 ~/.config/ports/daemon.log"
  fi
fi

echo
echo "安装完成。常用命令："
echo "  ports              实时端口表"
echo "  ports watch        全屏实时视图"
echo "  ports who <端口>    查端口被谁占用"
echo "  ports kill <端口>   结束占用进程"
echo "  ports alloc <名字>  为项目领一个端口"
