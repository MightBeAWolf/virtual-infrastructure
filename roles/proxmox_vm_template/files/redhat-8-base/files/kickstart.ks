#version=RHEL8
# Use graphical install
graphical


%packages
@^workstation-product-environment
@standard
@development
# LDAP/SSS/Identity dependecies
sudo
openldap-clients
sssd
sssd-ldap
sssd-tools
oddjob-mkhomedir
openssl-perl

# Virtuoso & Calibre Dependencies
ksh
tcsh
gcc
redhat-lsb.x86_64
libXScrnSaver
libnsl
libXp
boost
libgfortran
compat-openssl10
pcre2-utf16
pcre2-utf32

# Various development dependencies 
podman
vim
cmake
freetype-devel
fontconfig-devel 
libxcb-devel 
libxkbcommon-devel 
yum-utils
nfs-utils
curl
git
unzip

# VM Utilities
qemu-guest-agent
cloud-init
spice-vdagent

# For automatic updates
dnf-automatic
python3-tracer
%end

# Keyboard layouts
keyboard --xlayouts='us'
# System language
lang en_US.UTF-8

# Configure the use of SSSD/OpenLDAP
authselect select sssd with-mkhomedir --force

# Network information
network --bootproto=dhcp --ipv6=auto --activate

bootloader --append="rhgb quiet crashkernel=1G-4G:192M,4G-64G:256M,64G-:512M"

# Run the Setup Agent on first boot
firstboot --disable

# Redhat system registration
rhsm --organization=16531086 --activation-key=Base_EDA_Workstation

# Intended system purpose
syspurpose --role="Red Hat Enterprise Linux Workstation" --sla="Self-Support" --usage="Production"

# System timezone
timezone America/Los_Angeles --isUtc

# Root password
rootpw --iscrypted $6$KpqW9nj3oWI1DLzK$a.Bnpr68rxZu21CLFaCHcso4P7q2EOw20Jrp1ZwbqyIOAzbSL6LJt7YD7NZSggtisFBLRTk3N./A9HgFzXDaJ1

# User Creation
user --name="${var.guest_username}" --password="${var.guest_password}"

reboot
zerombr
clearpart --all --initlabel
autopart
firstboot --disable
selinux --enforcing
firewall --enabled --ssh


%post --nochroot
# Define target root
ROOT="/mnt/sysimage"

# Enable cloud-init and related services for the installed system
chroot $ROOT /bin/systemctl enable cloud-init
chroot $ROOT /bin/systemctl enable cloud-config
chroot $ROOT /bin/systemctl enable cloud-final
chroot $ROOT /bin/systemctl enable cloud-init-local
chroot $ROOT /bin/systemctl enable spice-vdagent

#Enable LDAP/SSSD
chroot $ROOT /bin/systemctl enable oddjobd
chroot $ROOT /bin/systemctl enable sssd

# Set up passwordless sudo
mkdir -p $ROOT/etc/sudoers.d
echo "${var.guest_username} ALL=(ALL) NOPASSWD: ALL" > $ROOT/etc/sudoers.d/${var.guest_username}
chown 0:0  $ROOT/etc/sudoers.d/${var.guest_username}
chmod 0440 $ROOT/etc/sudoers.d/${var.guest_username}
%end

