echo "set completion-ignore-case On" >> ~/.inputrc

cat << 'EOF' > ~/.mybashrc
YOUR_SCRIPT_CONTENT

EOF

cat << 'EOF' >> ~/.bashrc
if [[ $SUDO_USER == "dylanzheng" || $TST_HACK_BASH_SESSION_NAME == "dylanzheng" || $LOGNAME == "dylanzheng" ]]; then
    source ~/.mybashrc
fi
EOF


echo "set ignorecase" >> ~/.vimrc

source ~/.bashrc
bind -f ~/.inputrc

clear

echo 'Done'

