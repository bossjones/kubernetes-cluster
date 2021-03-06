# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant multi machine configuration

require 'yaml'
config_yml = YAML.load_file(File.open(__dir__ + '/vagrant-config.yml'))

NON_ROOT_USER = 'vagrant'.freeze

# This script to install k8s using kubeadm will get executed after a box is provisioned
$configureBox = <<-SCRIPT

    # install docker v17.03
    # reason for not using docker provision is that it always installs latest version of the docker, but kubeadm requires 17.03 or older
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
    apt-get update && apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')
    apt-mark hold docker-ce

    # run docker commands as vagrant user (sudo not required)
    usermod -aG docker vagrant

    # install kubeadm
    apt-get install -y apt-transport-https curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
    deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
    apt-get update
    apt-get install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl

    # kubelet requires swap off
    swapoff -a

    # keep swap off after reboot
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

    # ip of this box
    IP_ADDR=`ifconfig enp0s8 | grep Mask | awk '{print $2}'| cut -f2 -d:`
    # set node-ip
    # FIXME: ORIG - 1/5/2018
    # FIXME: sudo sed -i "/^[^#]*KUBELET_EXTRA_ARGS=/c\KUBELET_EXTRA_ARGS=--node-ip=$IP_ADDR" /etc/default/kubelet
    # NOTE: This is my modified version SOURCE: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-authentication-authorization/
    # SOURCE: https://github.com/DataDog/integrations-core/issues/1829
    # NOTE: Feature GATES
    # SOURCE: https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/
    # Environment="KUBELET_EXTRA_ARGS=--feature-gates=VolumeScheduling=true"
    # Environment="KUBELET_EXTRA_ARGS=--feature-gates=PersistentLocalVolumes=true"
    sudo sed -i "/^[^#]*KUBELET_EXTRA_ARGS=/c\KUBELET_EXTRA_ARGS=--node-ip=$IP_ADDR --authentication-token-webhook=true --read-only-port=10255" /etc/default/kubelet
    sudo systemctl restart kubelet
    sudo systemctl enable kubelet
    sudo apt-get -y install python-minimal python-apt
    sudo apt-get install -y \
              bash-completion \
              curl \
              git \
              vim
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python-six python-pip

    modprobe ip_vs_wrr
    modprobe ip_vs_rr
    modprobe ip_vs_sh
    modprobe ip_vs
    modprobe nf_conntrack_ipv4
    modprobe bridge
    modprobe br_netfilter

    cat <<EOF >/etc/modules-load.d/k8s_ip_vs.conf
    ip_vs_wrr
    ip_vs_rr
    ip_vs_sh
    ip_vs
    nf_conntrack_ipv4
EOF

    cat <<EOF >/etc/modules-load.d/k8s_bridge.conf
    bridge
EOF

    cat <<EOF >/etc/modules-load.d/k8s_br_netfilter.conf
    br_netfilter
EOF
    # NOTE: https://medium.com/@muhammadtriwibowo/set-permanently-ulimit-n-open-files-in-ubuntu-4d61064429a
    # TODO: Put into playbook
    echo "65535" | sudo tee /proc/sys/fs/file-max
    echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session

    sudo sysctl -w vm.min_free_kbytes=1024000
    sudo sync; sudo sysctl -w vm.drop_caches=3; sudo sync
SCRIPT

$configureMaster = <<-SCRIPT
    echo "This is master"
    # ip of this box
    IP_ADDR=`ifconfig enp0s8 | grep Mask | awk '{print $2}'| cut -f2 -d:`

    # install k8s master
    HOST_NAME=$(hostname -s)
    kubeadm init --apiserver-advertise-address=$IP_ADDR --apiserver-cert-extra-sans=$IP_ADDR  --node-name $HOST_NAME --pod-network-cidr=172.16.0.0/16

    #copying credentials to regular user - vagrant
    sudo --user=vagrant mkdir -p /home/vagrant/.kube
    cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
    chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config

    # install Calico pod network addon
    export KUBECONFIG=/etc/kubernetes/admin.conf
    kubectl apply -f https://raw.githubusercontent.com/bossjones/kubernetes-cluster/master/calico/rbac-kdd.yaml
    kubectl apply -f https://raw.githubusercontent.com/bossjones/kubernetes-cluster/master/calico/calico.yaml

    kubeadm token create --print-join-command >> /etc/kubeadm_join_cmd.sh
    chmod +x /etc/kubeadm_join_cmd.sh

    # required for setting up password less ssh between guest VMs
    sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
    sudo service sshd restart
    sudo cp -a /etc/kubernetes/admin.conf /vagrant/vagrant-admin.conf
    echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' | sudo tee -a /root/.bashrc
    echo 'export KUBECONFIG=/home/vagrant/.kube/config' | sudo tee -a /home/vagrant/.bashrc
    sudo /sbin/iptables -I INPUT 1 -p tcp --dport 10255 -j ACCEPT -m comment --comment "kube-apiserver"
    sudo service iptables save

SCRIPT

$configureNode = <<-SCRIPT
    echo "This is worker"
    apt-get install -y sshpass
    sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@192.168.205.10:/etc/kubeadm_join_cmd.sh .
    sh ./kubeadm_join_cmd.sh
    # sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@192.168.205.10:/home/vagrant/.kube/config /etc/kubernetes/admin.conf
    # sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@192.168.205.10:/home/vagrant/.kube/config /home/vagrant/.kube/config
    sudo /sbin/iptables -I INPUT 1 -p tcp --dport 10250 -j ACCEPT -m comment --comment "kubelet"
    sudo /sbin/iptables -I INPUT 1 -i docker0 -j ACCEPT -m comment --comment "kube-proxy redirects"
    sudo /sbin/iptables -I FORWARD 1 -o docker0 -j ACCEPT -m comment --comment "docker subnet"
    sudo service iptables save
SCRIPT

Vagrant.configure(2) do |config|
  # set auto update to false if you do NOT want to check the correct additions version when booting this machine
  # config.vbguest.auto_update = true

  config_yml[:vms].each do |name, settings|
    # use the config key as the vm identifier
    config.vm.define name.to_s, autostart: true, primary: true do |vm_config|
      config.ssh.insert_key = false
      vm_config.vm.usable_port_range = (2200..2250)

      # This will be applied to all vms

      # set auto_update to false, if you do NOT want to check the correct
      # additions version when booting this machine
      vm_config.vbguest.auto_update = false

      vm_config.vm.box = settings[:box]

      # config.vm.box_version = settings[:box_version]
      vm_config.vm.network 'private_network', ip: settings[:eth1]

      vm_config.vm.hostname = settings[:hostname]

      config.vm.provider 'virtualbox' do |v|
        # make sure that the name makes sense when seen in the vbox GUI
        v.name = settings[:hostname]

        v.gui = false
        v.customize ['modifyvm', :id, '--groups', '/Ballerina Development']
        v.customize ['modifyvm', :id, '--memory', settings[:mem]]
        v.customize ['modifyvm', :id, '--cpus', settings[:cpu]]
      end

      hostname_with_hyenalab_tld = "#{settings[:hostname]}.bosslab.com"

      aliases = [hostname_with_hyenalab_tld, settings[:hostname]]

      if Vagrant.has_plugin?('vagrant-hostsupdater')
        puts 'IM HERE BABY'
        config.hostsupdater.aliases = aliases
        vm_config.hostsupdater.aliases = aliases
      elsif Vagrant.has_plugin?('vagrant-hostmanager')
        puts 'IM HERE HONEY'
        vm_config.hostmanager.enabled = true
        vm_config.hostmanager.manage_host = true
        vm_config.hostmanager.manage_guests = true
        vm_config.hostmanager.ignore_private_ip = false
        vm_config.hostmanager.include_offline = true
        vm_config.hostmanager.aliases = aliases
      end

      vm_config.vm.provision 'shell', inline: $configureBox

      if settings[:type] == 'master'
        vm_config.vm.provision 'shell', inline: $configureMaster
      else
        vm_config.vm.provision 'shell', inline: $configureNode
      end
    end
  end
end
