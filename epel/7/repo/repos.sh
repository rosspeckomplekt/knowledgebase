<% if localmirror then repotype = localrepos else repotype = upstreamrepos end -%>
REPOS=`cat << EOF
<% repotype.each do | name, repo | -%>
[<%= name %>]
name=<%= name %>
baseurl=<%= repo.baseurl %>
description=<%= if defined?(repo.description) then repo.description else 'No description specified' end %>
enabled=<%= if defined?(repo.enabled) then repo.enabled else 1 end %>
skip_if_unavailable=<%= if defined?(repo.skip_if_unavailable) then repo.skip_if_unavailable else 1 end %>
gpgcheck=<%= if defined?(repo.gpgcheck) then repo.gpgcheck else 0 end %>
priority=<%= if defined?(repo.priority) then repo.priority else 10 end %>

<% end -%>
EOF`

REPOSERVER=<%= repoconfig.reposerver %>
REPOPATH=<%= repoconfig.repopath %>

<% if networks.pri.ip == repoconfig.reposerver && localmirror then -%>
# Install necessary packages and enable service
yum -y install createrepo yum-utils yum-plugin-priorities httpd
systemctl enable httpd.service

# Setup directories
if [ ! -d /opt/alces ]; then 
    mkdir -p /opt/alces
fi

cd /opt/alces

if [ ! -d $REPOPATH ] ; then
    mkdir -p $REPOPATH
fi

cd $REPOPATH

# Yum config settings
cat << EOF > yum.conf
[main]
cachedir=/var/cache/yum/\$basearch/\$releasever
keepcache=0
debuglevel=2
logfile=/var/log/yum.log
exactarch=1
obsoletes=1
gpgcheck=1
plugins=1
installonly_limit=5
bugtracker_url=http://bugs.centos.org/set_project.php?project_id=23&ref=http://bugs.centos.org/bug_report_page.php?category=yum
distroverpkg=centos-release
reposdir=/dev/null
EOF

# Add upstream repos to yum.conf
cat << EOF >> yum.conf
<% upstreamrepos.each do | name, repo | -%>
[<%= name %>]
name=<%= name %>
baseurl=<%= repo.baseurl %>
description=<%= if defined?(repo.description) then repo.description else 'No description specified' end %>
enabled=<%= if defined?(repo.enabled) then repo.enabled else 1 end %>
skip_if_unavailable=<%= if defined?(repo.skip_if_unavailable) then repo.skip_if_unavailable else 1 end %>
gpgcheck=<%= if defined?(repo.gpgcheck) then repo.gpgcheck else 0 end %>
priority=<%= if defined?(repo.priority) then repo.priority else 10 end %>

<% end -%>
EOF

# Setup HTTPD server config file
cat << EOF > /etc/httpd/conf.d/repo.conf
<Directory /opt/alces/$REPOPATH/>
    Options Indexes MultiViews FollowSymlinks
    AllowOverride None
    Require all granted
    Order Allow,Deny
    Allow from <%= networks.pri.network %>/255.255.0.0
</Directory>
Alias /repo /opt/alces/$REPOPATH
EOF

systemctl restart httpd.service

# Build repository
reposync -nm --config yum.conf -r centos
mkdir -p centos/LiveOS
## NOTE: Could this URL be ERBified?? ##
curl http://mirror.ox.ac.uk/sites/mirror.centos.org/7/os/x86_64/LiveOS/squashfs.img > centos/LiveOS/squashfs.img

reposync -nm --config yum.conf -r centos-updates
reposync -nm --config yum.conf -r centos-extras
reposync -nm --config yum.conf -r epel

mkdir custom
createrepo -g comps.xml centos
createrepo centos-updates
createrepo centos-extras
createrepo -g comps.xml epel
createrepo custom

<% else -%>
find /etc/yum.repos.d/*.repo -exec mv -fv {} {}.bak \;
echo "$REPOS" > /etc/yum.repos.d/cluster.repo
yum clean all
<% end -%>