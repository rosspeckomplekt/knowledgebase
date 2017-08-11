.. _06-deployment-example:

Deployment Example
==================

.. _client-deployment:

Client Deployment Example
-------------------------

- Start the deployment VM listening for PXE requests::

    metal hunter -i eth0

- Boot up the client node

- The deployment VM will print a line when the node has connected, when this happens enter the hostname for the system (this should be a hostname that exists in the nodelist mentioned earlier)

- Once the hostname has been added the previous metal command can be cancelled (with ctrl-c)

- Add the host entry for the node::

    metal hosts node_name

- Generate DHCP entry for the node::

    metal dhcp -t default

- Start the deployment VM serving installation files to the node (replace slave01 with the hostname of the client node)::

    metal build slave01

.. note:: If building multiple systems the genders group can be specified instead of the node hostname. For example, all compute nodes can be built with ``metal build -g nodes``.

- The client node can be rebooted and it will begin an automatic installation of CentOS 7

- The ``metal build`` will automatically exit when the client installation has completed

- Passwordless SSH should now work to the client node

.. _deployment-kickstart:

Configuring Alternative Kickstart Profile
-----------------------------------------

In this example, a CentOS 6 kickstart profile is configured. This method should be transferrable to other operating systems with little modification to the general practice.

- Download the boot files to the ``PXE_BOOT`` directory::

    PXE_BOOT=/var/lib/tftpboot/boot/
    curl http://mirror.ox.ac.uk/sites/mirror.centos.org/6/os/x86_64/images/pxeboot/initrd.img > “$PXE_BOOT/centos6-initrd.img”
    curl http://mirror.ox.ac.uk/sites/mirror.centos.org/6/os/x86_64/images/pxeboot/vmlinuz > “$PXE_BOOT/centos6-kernel”

- Create ``/var/lib/metalware/repo/pxelinux/centos6`` template PXE boot file for the OS::

   DEFAULT menu
    PROMPT 0
    MENU TITLE PXE Menu
    TIMEOUT 5
    TOTALTIMEOUT 5
    <%= alces.firstboot ? "ONTIMEOUT INSTALL" : "ONTIMEOUT local"%>

    LABEL INSTALL
         KERNEL boot/centos6-kernel
            APPEND initrd=boot/centos6-initrd.img ksdevice=<%= networks.pri.interface %> ks=<%= alces.kickstart_url %> network ks.sendmac _ALCES_BASE_HOSTNAME=<%= alces.nodename %> <%= kernelappendoptions %>
            IPAPPEND 2

    LABEL local
         MENU LABEL (local)
         MENU DEFAULT
         LOCALBOOT 0

- Create ``/var/lib/metalware/repo/kickstart/centos6`` template file for kickstart installations of the OS::

    #!/bin/bash
    ##(c)2017 Alces Software Ltd. HPC Consulting Build Suite
    ## vim: set filetype=kickstart :

    network --onboot yes --device <%= networks.pri.interface %> --bootproto dhcp --noipv6

    #MISC
    text
    reboot
    skipx
    install

    #SECURITY
    firewall --enabled
    firstboot --disable
    selinux --disabled

    #AUTH
    auth  --useshadow  --enablemd5
    rootpw --iscrypted <%= encrypted_root_password %>

    #LOCALIZATION
    keyboard uk
    lang en_GB
    timezone  Europe/London

    #REPOS
    url --url=http://mirror.ox.ac.uk/sites/mirror.centos.org/6/os/x86_64/

    #DISK
    %include /tmp/disk.part

    #PRESCRIPT
    %pre
    set -x -v
    exec 1>/tmp/ks-pre.log 2>&1

    DISKFILE=/tmp/disk.part
    bootloaderappend="console=tty0 console=ttyS1,115200n8"
    cat > $DISKFILE << EOF
    <%= disksetup %>
    EOF

    #PACKAGES
    %packages --ignoremissing

    vim
    emacs
    xauth
    xhost
    xdpyinfo
    xterm
    xclock
    tigervnc-server
    ntpdate
    vconfig
    bridge-utils
    patch
    tcl-devel
    gettext

    #POSTSCRIPTS
    %post --nochroot
    set -x -v
    exec 1>/mnt/sysimage/root/ks-post-nochroot.log 2>&1

    ntpdate 0.centos.pool.ntp.org

    %post
    set -x -v
    exec 1>/root/ks-post.log 2>&1

    # Example of using rendered Metalware file; this file itself also uses other
    # rendered files.
    curl <%= alces.files.main.first.url %> | /bin/bash | tee /tmp/metalware-default-output

    curl <%= alces.build_complete_url %>

- When building nodes, use the new template files by specifying them as arguments to the ``metal build`` command::

    metal build -k centos6 -p centos6 slave01