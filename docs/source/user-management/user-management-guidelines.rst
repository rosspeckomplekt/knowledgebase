.. _user-management-guidelines:

Recommendations for User Management
===================================

Below are guidelines for setting up both a NIS and an IPA server, only one of these should be setup to prevent conflicts and inconsistencies in user management.

NIS Server Setup
----------------

On Master Node
^^^^^^^^^^^^^^

- Create ``/opt/vm/nis.xml`` for deploying the nis VM (:download:`Available here <nis.xml>`)

- Create disk image for the nis VM::

    qemu-img create -f qcow2 nis.qcow2 80G

- Define the VM::

    virsh define nis.xml

.. _deploy-user:

On Controller VM
^^^^^^^^^^^^^^^^

- Create a group for the nis VM (add at least ``nis1`` as a node in the group, set additional groups of ``services,cluster,domain`` allows for more diverse group management)::

    metal configure group nis
    
- Customise ``nis1`` node configuration (set the primary IP address to 10.10.0.4)::

    metal configure node nis1

- Create a deployment file specifically for ``nis1`` at ``/var/lib/metalware/repo/config/nis1.yaml`` with the following content::

    nisconfig:
      is_server: true

- Add the following to ``/var/lib/metalware/repo/config/domain.yaml`` (the nisserver IP should match the one specified for ``nis1``): ::

    nisconfig:
      nisserver: 10.10.0.4
      nisdomain: nis.<%= config.domain %>
      is_server: false
      # specify non-standard user directory [optional]
      users_dir: /users

- Additionally, add the following to the ``setup:`` namespace list in ``/var/lib/metalware/repo/config/domain.yaml``::

    - /opt/alces/install/scripts/02-nis.sh

- Download the ``nis.sh`` script to the above location::

    mkdir -p /opt/alces/install/scripts/
    cd /opt/alces/install/scripts/
    wget -O 02-nis.sh https://raw.githubusercontent.com/alces-software/knowledgebase/master/epel/7/nis/nis.sh

- Follow :ref:`client-deployment` to setup the compute nodes

IPA Server Setup
----------------

On Master Node
^^^^^^^^^^^^^^

- Create ``/opt/vm/ipa.xml`` for deploying the IPA VM (:download:`Available here <ipa.xml>`)

- Create disk image for the IPA VM::

    qemu-img create -f qcow2 IPA.qcow2 80G

- Define the VM::

    virsh define IPA.xml

.. _deploy-user-ipa:

On Controller VM
^^^^^^^^^^^^^^^^

- Create a group for the IPA VM (add at least ``ipa1`` as a node in the group, set additional groups of ``services,cluster,domain`` allowing for more diverse group management)::

    metal configure group ipa

- Customise ``ipa1`` node configuration (set the primary IP address to 10.10.0.4)::

    metal configure node ipa1

- Add the following to ``/var/lib/metalware/repo/config/domain.yaml`` (the ipaserver IP should match the one specified for ``ipa1``)::

    ipaconfig:
      serverip: 10.10.0.4
      servername: ipa1
      insecurepassword: abcdef123
      userdir: /users

- Additionally, add the following to the ``scripts:`` namespace list in ``/var/lib/metalware/repo/config/domain.yaml`` (this script runs the client-side configuration of IPA)::

    - /opt/alces/install/scripts/02-ipa.sh

- Download the ``ipa.sh`` script to the above location::

    mkdir -p /opt/alces/install/scripts/
    cd /opt/alces/install/scripts/
    wget -O 02-ipa.sh https://raw.githubusercontent.com/alces-software/knowledgebase/master/epel/7/ipa/ipa.sh

- Follow :ref:`client-deployment` to setup the IPA node and continue to the next session to configure the IPA server with a script

Setup IPA Server
^^^^^^^^^^^^^^^^

- Download the server configuration script to the controller::

    cd /opt/alces/install/scripts/
    wget http://raw.githubusercontent.com/alces-software/knowledgebase/master/epel/7/ipa/ipa_server.sh

- Render the script for the IPA server::

    metal render /opt/alces/install/scripts/ipa_server.sh ipa1 > /tmp/ipa_server.sh

- Copy the script to the IPA server::

    scp /tmp/ipa_server.sh ipa1:/root/

.. note:: Before launching the script it is currently necessary to disable named on the controller from serving the primary forward and reverse domains such that the IPA installation will work. This can be re-enabled once the IPA script has finished running.

- Launch the script on the IPA server (following any on-screen prompts)::

    ssh ipa1 "/root/ipa_server.sh"

IPA Replica Server Setup
------------------------

For this example, the servers are as follows:

- ``infra01-dom0`` - The IPA server
- ``infra01-domX`` - The server to replicate IPA

Configuring Replica Host (on ``infra01-domX``)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

- Install IPA tools::

    yum -y install ipa-server bind bind-dyndb-ldap ipa-server-dns

- Configure DNS to use ``infra01-dom0`` as nameserver in ``/etc/resolv.conf``


Preparing Server (on ``infra01-dom0``)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

- Add ``infra01-domX`` as a host::

    ipa host-add infra01-domX --password="MyOneTimePassword" --ip-address=10.10.2.51

- Add ``infra01-domX`` to ``ipaservers`` group::

    ipa hostgroup-add-member ipaservers --hosts=infra01-domX

Connecting Replica Host (on ``infra01-domX``)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

- Run the replica installation::

    ipa-replica-install --realm="PRI.CLUSTER.ALCES.NETWORK" --server="infra01-dom0.pri.cluster.alces.network" --domain="pri.cluster.alces.network" --password="MyOneTimePassword"
