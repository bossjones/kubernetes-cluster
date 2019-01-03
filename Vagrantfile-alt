# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant multi machine configuration

require 'yaml'
config_yml = YAML.load_file(File.open(__dir__ + '/vagrant-config.yml'))

NON_ROOT_USER = 'vagrant'.freeze

Vagrant.configure(2) do |config|
  # set auto update to false if you do NOT want to check the correct additions version when booting this machine
  # config.vbguest.auto_update = true

  config_yml[:vms].each do |name, opts|
    # use the config key as the vm identifier
    config.vm.define name.to_s, autostart: true, primary: true do |vm_config|
      config.ssh.insert_key = false
      vm_config.vm.usable_port_range = (2200..2250)

      # This will be applied to all vms

      # set auto_update to false, if you do NOT want to check the correct
      # additions version when booting this machine
      vm_config.vbguest.auto_update = false

      vm_config.vm.box = opts[:box]
      # config.vm.box_version = opts[:box_version]
      vm_config.vm.hostname = opts[:name]
      vm_config.vm.network :private_network, ip: opts[:eth1]

      config.vm.provider 'virtualbox' do |v|
        # make sure that the name makes sense when seen in the vbox GUI
        v.name = opts[:hostname]

        v.gui = false
        v.name = opts[:name]
        v.customize ['modifyvm', :id, '--groups', '/Ballerina Development']
        v.customize ['modifyvm', :id, '--memory', opts[:mem]]
        v.customize ['modifyvm', :id, '--cpus', opts[:cpu]]
      end

      hostname_with_hyenalab_tld = "#{opts[:hostname]}.bosslab.com"

      aliases = [hostname_with_hyenalab_tld, opts[:hostname]]

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
      vm_config.vm.provision 'shell', inline: $configureBox

      if opts[:type] == 'master'
        vm_config.vm.provision 'shell', inline: $configureMaster
      else
        vm_config.vm.provision 'shell', inline: $configureNode
      end
    end
  end
end
