#!/bin/bash 
#(c)2017 Alces Software Ltd. HPC Consulting Build Suite
#Job ID: <JOB>
#Cluster: <CLUSTER>

if [ -f /root/.alcesconf ]; then
  . /root/.alcesconf
fi

FILES_URL=http://${_ALCES_BUILDSERVER}/epel/files/${_ALCES_CLUSTER}/

yum-config-manager --enable epel

yum -y install ganglia ganglia-web ganglia-gmetad ganglia-gmond
sed -i -e 's/^\s*Require.*$/  Require all granted/g' /etc/httpd/conf.d/ganglia.conf
service httpd restart

curl $FILES_URL/gmetad | envsubst "$_ALCES_KEYS" > /etc/ganglia/gmetad.conf
systemctl enable gmetad
systemctl restart gmetad

curl $FILES_URL/gmond | envsubst "$_ALCES_KEYS" > /etc/ganglia/gmond.conf
systemctl enable gmond
systemctl restart gmond
