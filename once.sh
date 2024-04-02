#! /bin/bash


if [ -d ~/.autojump ]; then
    echo "autojump Installed"
else
    rm -fr /tmp/autojump
    git clone https://github.com/wting/autojump.git /tmp/autojump
    cd /tmp/autojump/
    ./install.py
    cd -
fi



[ -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ] || git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
[ -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ] || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

cp rc/.tigrc ~/
