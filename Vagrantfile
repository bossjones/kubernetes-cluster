# -*- mode: ruby -*-
# vi: set ft=ruby :

servers = [
  {
    name: 'k8s-head',
    type: 'master',
    box: 'ubuntu/xenial64',
    # :box_version => "20180831.0.0",
    eth1: '192.168.205.10',
    mem: '2048',
    cpu: '2'
  },
  {
    name: 'k8s-node-1',
    type: 'node',
    box: 'ubuntu/xenial64',
    # :box_version => "20180831.0.0",
    eth1: '192.168.205.11',
    mem: '2048',
    cpu: '2'
  },
  {
    name: 'k8s-node-2',
    type: 'node',
    box: 'ubuntu/xenial64',
    # :box_version => "20180831.0.0",
    eth1: '192.168.205.12',
    mem: '2048',
    cpu: '2'
  }
]

# This script to install k8s using kubeadm will get executed after a box is provisioned
$configureBox = <<-SCRIPT

    # install docker v17.03
    # reason for not using docker provision is that it always installs latest version of the docker, but kubeadm requires 17.03 or older
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
    apt-get update && apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')

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
    sudo sed -i "/^[^#]*KUBELET_EXTRA_ARGS=/c\KUBELET_EXTRA_ARGS=--node-ip=$IP_ADDR" /etc/default/kubelet
    sudo systemctl restart kubelet
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
    kubectl apply -f https://raw.githubusercontent.com/ecomm-integration-ballerina/kubernetes-cluster/master/calico/rbac-kdd.yaml
    kubectl apply -f https://raw.githubusercontent.com/ecomm-integration-ballerina/kubernetes-cluster/master/calico/calico.yaml

    kubeadm token create --print-join-command >> /etc/kubeadm_join_cmd.sh
    chmod +x /etc/kubeadm_join_cmd.sh

    # required for setting up password less ssh between guest VMs
    sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
    sudo service sshd restart
    sudo cp -a /etc/kubernetes/admin.conf /vagrant/vagrant-admin.conf
    echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' | sudo tee -a /root/.bashrc
    echo 'export KUBECONFIG=/home/vagrant/.kube/config' | sudo tee -a /home/vagrant/.bashrc

SCRIPT

$configureNode = <<-SCRIPT
    echo "This is worker"
    apt-get install -y sshpass
    sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@192.168.205.10:/etc/kubeadm_join_cmd.sh .
    sh ./kubeadm_join_cmd.sh
SCRIPT

Vagrant.configure('2') do |config|
  servers.each do |opts|
    config.vm.define opts[:name] do |vm_config|
      config.ssh.insert_key = false

      vm_config.vm.box = opts[:box]
      # config.vm.box_version = opts[:box_version]
      vm_config.vm.hostname = opts[:name]
      vm_config.vm.network :private_network, ip: opts[:eth1]

      config.vm.provider 'virtualbox' do |v|
        v.name = opts[:name]
        v.customize ['modifyvm', :id, '--groups', '/Ballerina Development']
        v.customize ['modifyvm', :id, '--memory', opts[:mem]]
        v.customize ['modifyvm', :id, '--cpus', opts[:cpu]]
      end

      puts "the value of config is '%s'" % [config]
      puts "the value of vm_config is '%s'" % [vm_config]

      hostname_with_hyenalab_tld = "#{opts[:name]}.bosslab.com"
      puts "the value of hostname_with_hyenalab_tld is '%s'" % [hostname_with_hyenalab_tld]

      aliases = [hostname_with_hyenalab_tld, opts[:name]]

      if Vagrant.has_plugin?('vagrant-hostsupdater')
        vm_config.hostsupdater.aliases = aliases
      elsif Vagrant.has_plugin?('vagrant-hostmanager')
        vm_config.hostmanager.enabled = true
        vm_config.hostmanager.manage_host = true
        vm_config.hostmanager.manage_guests = true
        vm_config.hostmanager.ignore_private_ip = false
        vm_config.hostmanager.include_offline = true
        vm_config.hostmanager.aliases = aliases
      end

      # we cannot use this because we can't install the docker version we want - https://github.com/hashicorp/vagrant/issues/4871
      # config.vm.provision "docker"

      vm_config.vm.provision 'shell', inline: $configureBox

      if opts[:type] == 'master'
        vm_config.vm.provision 'shell', inline: $configureMaster
      else
        vm_config.vm.provision 'shell', inline: $configureNode
      end
    end
  end
end
