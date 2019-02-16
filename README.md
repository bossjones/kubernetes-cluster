# Kubernetes cluster
A vagrant script for setting up a Kubernetes cluster using Kubeadm

## Pre-requisites

 * **[Vagrant 2.1.4+](https://www.vagrantup.com)**
 * **[Virtualbox 5.2.18+](https://www.virtualbox.org)**

## How to Run

Execute the following vagrant command to start a new Kubernetes cluster, this will start one master and two nodes:

```
vagrant up
```

You can also start invidual machines by vagrant up borg-queen-01, vagrant up borg-worker-01 and vagrant up borg-worker-02

If more than two nodes are required, you can edit the servers array in the Vagrantfile

```
servers = [
    {
        :name => "k8s-node-3",
        :type => "node",
        :box => "ubuntu/xenial64",
        :box_version => "20180831.0.0",
        :eth1 => "192.168.205.13",
        :mem => "2048",
        :cpu => "2"
    }
]
 ```

As you can see above, you can also configure IP address, memory and CPU in the servers array.

## Clean-up

Execute the following command to remove the virtual machines created for the Kubernetes cluster.
```
vagrant destroy -f
```

You can destroy individual machines by vagrant destroy borg-worker-01 -f

## Licensing

[Apache License, Version 2.0](http://opensource.org/licenses/Apache-2.0).


## Order of operations
------

`SOURCE:` https://github.com/rootsongjc/kubernetes-vagrant-centos-cluster/blob/master/install.sh

```
echo "deploy kubernetes dashboard"
kubectl apply -f /vagrant/addon/dashboard/kubernetes-dashboard.yaml
echo "create admin role token"
kubectl apply -f /vagrant/yaml/admin-role.yaml
echo "the admin role token is:"
kubectl -n kube-system describe secret `kubectl -n kube-system get secret|grep admin-token|cut -d " " -f1`|grep "token:"|tr -s " "|cut -d " " -f2
echo "login to dashboard with the above token"
echo https://172.17.8.101:`kubectl -n kube-system get svc kubernetes-dashboard -o=jsonpath='{.spec.ports[0].port}'`
echo "install traefik ingress controller"
kubectl apply -f /vagrant/addon/traefik-ingress/
```


# Official CLI Order ( tested )
---
* make allow-scheduling-on-master
* make generate-certs-dashboard
* make apply-certs-dashboard
* make create-dashboard
* make describe-dashboard
* make debug-cluster
* make create-nfs-client
* make create-heapster
* make create-metrics-server
* make create-ingress-nginx
* make create-echoserver
* make create-npd
* make create-prometheus-operator
* make create-efk


* make create-ingress-traefik

# Git Issues to keep track of
---
* https://github.com/kubernetes/dashboard/issues/2723
* https://superuser.com/questions/1356984/why-does-my-linux-system-stutter-unless-i-continuously-drop-caches

# Why does my Linux system stutter unless I continuously drop caches?
SOURCE: https://superuser.com/questions/1356984/why-does-my-linux-system-stutter-unless-i-continuously-drop-caches


# Remove atop from clusters

https://bugs.launchpad.net/fuel/+bug/1530167

```
git config --global user.email "root@$(hostname)"
git config --global user.name "$(hostname)"

Turns out, budget isn't the only variable controlling for packet being squeezed out. There is also time frame, during which everything is supposed to be processed. By default at 4.13 Linux kernel it is 2000 us. So changing the budget after certain value does nothing, if processing takes more than 2000 us. After I've increased net.core.netdev_budget_usecs to 5000 just to test it (sudo sysctl -w net.core.netdev_budget_usecs=5000). And all of the time_squeezes has disappeared. By tweaking this value and netdev_budget, I found out that tweaking netdev_budget has 0 effect on amount of time_squeezed events (on my machine and at relatively low load), but netdev_budget_usecs needed to be at least at 4250 for time_squeezed to disappear. I'm far from being a linux expert, so I don't know if setting this value to the double of the original value might cause any problems, but it seems to work for now.

```
apt-get remove --purge atop -y
apt-get clean
rm -rfv /run/atop
```


# Configure netdata w/ pushover

https://github.com/netdata/netdata/issues/3451
* https://github.com/openshift/origin-aggregated-logging/blob/master/elasticsearch/kibana_ui_objects/k8s-visualizations.json
* https://github.com/openshift/origin-aggregated-logging/blob/master/elasticsearch/index_patterns/com.redhat.viaq-openshift.index-pattern.json
* https://github.com/gregbkr/kubernetes-kargo-logging-monitoring/blob/master/logging/dashboards/elk-v1.json


# To get prometheius-operator to read in nginx pods and scrape correctly

* https://github.com/fromanirh/procwatch/blob/d8e83aebf619ba3088a9a5a2793df1efced11ed3/README.md



# (I think I messed up the readme with a stupid git pull, re-pasting)
---

# RE: Netdata - Alarm "system.softnet_stat" is very strict. #1076

https://github.com/netdata/netdata/issues/1076#issuecomment-367873913

I have the same problem (lots of squeezed events, not other real problems). I've spent lots of time reading lots of docs over the in ternet regarding net_dev_budget at linux network stack, until i found the source code responsible for the time_squeeze: torvalds/lin ux:net/core/dev.c@v4.13#L5572

Turns out, budget isn't the only variable controlling for packet being squeezed out. There is also time frame, during which everythi ng is supposed to be processed. By default at 4.13 Linux kernel it is 2000 us. So changing the budget after certain value does nothi ng, if processing takes more than 2000 us. After I've increased net.core.netdev_budget_usecs to 5000 just to test it (sudo sysctl -w  net.core.netdev_budget_usecs=5000). And all of the time_squeezes has disappeared. By tweaking this value and netdev_budget, I found  out that tweaking netdev_budget has 0 effect on amount of time_squeezed events (on my machine and at relatively low load), but netd ev_budget_usecs needed to be at least at 4250 for time_squeezed to disappear. I'm far from being a linux expert, so I don't know if  setting this value to the double of the original value might cause any problems, but it seems to work for now.

```
net.ipv4.tcp_rmem = 4096 5242880 33554432
net.core.netdev_budget = 60000
net.core.netdev_budget_usecs = 6000
```


# Kibana dashboard sources

* https://github.com/qwe8258/venoodkhatuva12/tree/ea2c169c12e07eec6d7440214179af1122a666d2
* https://github.com/openshift/origin-aggregated-logging/blob/master/elasticsearch/kibana_ui_objects/k8s-visualizations.json
* https://github.com/openshift/origin-aggregated-logging/blob/master/elasticsearch/index_patterns/com.redhat.viaq-openshift.index-pa ttern.json
* https://github.com/gregbkr/kubernetes-kargo-logging-monitoring/blob/master/logging/dashboards/elk-v1.json


# To get prometheius-operator to read in nginx pods and scrape correctly

* https://github.com/fromanirh/procwatch/blob/d8e83aebf619ba3088a9a5a2793df1efced11ed3/README.md
=======
# Remove atop from clusters

https://bugs.launchpad.net/fuel/+bug/1530167

```
git config --global user.email "root@$(hostname)"
git config --global user.name "$(hostname)"


apt-get remove --purge atop -y
apt-get clean
rm -rfv /run/atop
```


# Configure netdata w/ pushover

https://github.com/netdata/netdata/issues/3451
