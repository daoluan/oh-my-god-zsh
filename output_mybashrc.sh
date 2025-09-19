#!/bin/bash

# 获取脚本所在目录
SCRIPT_DIR=$(dirname "$0")
BASHRC_TEMPLATE_FILE="$SCRIPT_DIR/misc/mybashrc_template.sh"
BASHRC_FILE="$SCRIPT_DIR/misc/.mybashrc"

# 处理模板内容，用 .bashrc 内容替换 TODO
while IFS= read -r line; do
    if [[ "$line" == "YOUR_SCRIPT_CONTENT" ]]; then
        # 输出 .bashrc 内容
        cat "$BASHRC_FILE"
    else
        # 输出原始行
        echo "$line"
    fi
done < "$BASHRC_TEMPLATE_FILE"