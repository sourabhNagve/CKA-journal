set these aliases for faster work, no need to put alot of aliases,as the commands are already small, just add the below.
alias k='kubectl'
alias kn='kubectl config set-context --current --namespace'

export do='--dry-run=client -o yaml'
export now='--force --grace-period=0'
source ~/.bashrc