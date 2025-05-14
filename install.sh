#!/bin/bash

if grep -q "oh-my-god-zsh" ~/.zshrc; then
    exit 0
fi

# echo multi line to .zshrc
cat <<EOF >> ~/.zshrc
source ~/oh-my-god-zsh/env.sh
if [ -f ~/.mybashrc ];
    source ~/.mybashrc
fi
EOF

pip3 install pipreqs
