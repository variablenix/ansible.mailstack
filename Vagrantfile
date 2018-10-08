# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define "host1" do |host11|
    host1.vm.box = "terrywang/archlinux"
    host1.vm.hostname = 'host1'
    config.ssh.insert_key = false

    host1.vm.network "private_network", type: "dhcp"

    host1.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 4096]
    end
  # Ansible provisioner: mailstack
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "vagrant.yml"
    ansible.compatibility_mode = "2.0"
    ansible.inventory_path = "inventory"
    ansible.become = true
    ansible.host_key_checking = false
    ansible.ask_vault_pass = true
    end
  end

  config.vm.define "host2" do |host2|
    host2.vm.box = "terrywang/archlinux"
    host2.vm.hostname = 'host2'
    config.ssh.insert_key = false

    host2.vm.network "private_network", type: "dhcp"

    host2.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 2048]
    end
  # Ansible provisioner: mailstack
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "vagrant.yml"
    ansible.compatibility_mode = "2.0"
    ansible.inventory_path = "inventory"
    ansible.become = true
    ansible.host_key_checking = false
    ansible.ask_vault_pass = true
    end
  end

    config.vm.define "host3" do |host3|
    host3.vm.box = "terrywang/archlinux"
    host3.vm.hostname = 'host3'
    config.ssh.insert_key = false

    host3.vm.network "private_network", type: "dhcp"

    host3.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 2048]
    end
  # Ansible provisioner: mailstack
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "vagrant.yml"
    ansible.compatibility_mode = "2.0"
    ansible.inventory_path = "inventory"
    ansible.become = true
    ansible.host_key_checking = false
    ansible.ask_vault_pass = true
    end
  end
end
