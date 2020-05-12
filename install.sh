#!/bin/bash

if grep -q "oh-my-god-zsh" ~/.zshrc; then
    exit 0
fi
echo 'source ~/oh-my-god-zsh/env.sh' >> ~/.zshrc
