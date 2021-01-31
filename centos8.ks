#   Kickstart file for CentOS 7
#
#   Things to change:
#       * Repo
#       * Hoatname
#       * Password 
#       * Package selection
#       * Authorized SSH public key
#
#   Kickstart Syntax Reference: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Installation_Guide/sect-kickstart-syntax.html
#

install                             # Install OS instead of upgrade
text                                # Use text mode install
url --url=URL                       # Use network installation
shutdown                            # Shutdown after installation

network  --hostname=localhost.local --device=eth0 --bootproto=dhcp --onboot=on

# auth -> authselect
authselect --useshadow --passalgo=sha512
rootpw --iscrypted ENCRYPTED_PASSWORD       # generate using python3. import crypt.crypt; crypt(YOUR_PASSWORD)

selinux --enforcing

timezone Asia/Shanghai --isUtc
keyboard --vckeymap=us --xlayouts='us'
lang en_US

ignoredisk --only-use=vda
zerombr
clearpart --all  
#part /boot/efi --size=200 --fstype="vfat"
part /boot --size=500 --fstype="xfs"
part swap --size 1024 --fstype swap
part / --size=500 --fstype="xfs" --grow

bootloader --append="console=ttyS0 net.ifnames=0" --location=mbr --timeout=1 --boot-drive=vda

%packages --ignoremissing --excludedocs --excludeWeakdeps
@core
@base --nodefaults
bash-completion
dos2unix
deltarpm
ethtool
net-tools
gnupg2
openssh-server
man
mlocate
mtr
policycoreutils-python
rsync
sysstat
tcpdump
tmux
bzip2
unzip
zip
vim-enhanced
-cockpit*
-lshw
-tuned
-polkit
%end


%post --logfile /root/ks-post.log

yum clean all

rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

echo "Configuring SSH server..."
# NOTE: Don't use patch to do it, it might not be present by now.
sed -i "s/#PermitRootLogin yes/PermitRootLogin without-password/;
    s/^PasswordAuthentication yes/PasswordAuthentication no/;
    /^GSSAPIAuthentication yes/d;
    /^GSSAPICleanupCredentials yes/d;
    /^X11Forwarding yes/d;
    s/#UseDNS yes/UseDNS no/" \
    /etc/ssh/sshd_config

echo "Enabling SSH public key authentication..."
mkdir -m 700 /root/.ssh
cat > /root/.ssh/authorized_keys << EOF
YOUR_SSH_PUBKEY
EOF
chmod 600 /root/.ssh/authorized_keys
chcon -R -t home_ssh_t /root/.ssh

echo "Update the old kernel instead of installing a new kernel..."
cat >> /etc/yum.conf << EOF
installonlypkgs=""
EOF

echo "Root prompt eye candy..."
echo "PS1='\[\e[1;31m\]\u@\h \W \\$\[\e[0m\] '" >> /root/.bashrc

echo "Configuring vim & tmux..."
# vim
cat > /root/.vimrc << EOF
set nocompatible
syntax on
set bg=dark
hi Comment ctermfg=237
set t_Co=256
set tabstop=4
set shiftwidth=4
set expandtab
set softtabstop=4
set ai
set showmatch
set hlsearch
set incsearch
set ignorecase
set smartcase
set bs=indent,eol,start
filetype plugin indent on
autocmd FileType sh setlocal shiftwidth=2 tabstop=2 softtabstop=2
EOF
# tmux
cat > /root/.tmux.conf << EOF
set -g pane-border-fg colour238
set -g pane-active-border-fg colour245
set -g status-fg colour245
set -g status-bg colour235
set -g status-justify centre
set -g status-right "%H:%M"
set -g window-status-current-bg colour245
set -g window-status-current-fg colour235
set -g window-status-current-attr "bright"
set -g window-status-bg colour235
set -g window-status-fg colour245
set -g mode-key emacs
set -g default-terminal screen-256color
EOF

%end