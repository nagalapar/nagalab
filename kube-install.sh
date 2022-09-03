#Install kubernetes with cri-o on ubuntu
export OS=xUbuntu_22.04
export CRIO_VERSION=1.25


#Disable swap
sudo swapoff -a
sudo vi /etc/fstab
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

#Update repo list to install latest cri-o
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/$OS/Release.key | sudo apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key add -

#Istall cri-o
sudo apt update         #just update
sudo apt info cri-o     #check apt for cri-o
sudo apt install cri-o cri-o-runc cri-tools -y

#Enable and start service
sudo systemctl enable crio.service
sudo systemctl start crio.service

#List kubernetes apt-key
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update

#Install kubernetes
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

#Check installation version
kubeadm version

#kubeadm init
sudo kubeadm init --control-plane-endpoint=master0.nglp.tech --pod-network-cidr=192.168.0.0/16

#command for showing join token
kubeadm token create --print-join-command

#insert join token here, this is an example
kubeadm join master0.nglp.tech:6443 --token 0nrs2p.takd4ncu97q2yl1g --discovery-token-ca-cert-hash sha256:98d4da9e679443607b915866af95a2a89f5efd3de03096310275fd5d79070a06

#copy login admin.conf
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl cluster-info
kubectl get nodes

#download and install networking with calico
curl https://projectcalico.docs.tigera.io/manifests/calico.yaml -O
kubectl apply -f calico.yaml



