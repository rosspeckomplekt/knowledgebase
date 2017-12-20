<% if (config.lustreconfig.type == 'server' rescue false) -%>
yum -y --enablerepo lustre-el7-server --enablerepo e2fsprogs-el7 update
yum -y --enablerepo lustre-el7-server --enablerepo e2fsprogs-el7 install lustre kmod-lustre-osd-ldiskfs

cat << EOF > /etc/modprobe.d/lustre.conf
options lnet networks=<%= config.lustreconfig.networks %>
options ost oss_num_threads=96
options mdt mds_num_threads=96
EOF

<% elsif (config.lustreconfig.type == 'client' rescue false) -%>

yum -y --enablerepo lustre-el7-server --enablerepo e2fsprogs-el7 install lustre-client

cat << EOF > /etc/modprobe.d/lustre.conf
options lnet networks=<%= config.lustreconfig.networks %>
EOF

echo "<%= config.lustreconfig.mountentry %>" >> /etc/fstab

<% end -%>
