.PHONY: install-vagrant install-vbox docker-config install-p3-tools init clean clean-gitlab fclean hosts hosts-clean help

install-vagrant:
	wget -qO - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null || true
	echo "deb [arch=$$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
	sudo apt update && sudo apt install -y vagrant
	@vagrant --version

install-vbox:
	sudo apt install -y virtualbox virtualbox-dkms
	@vboxmanage --version

rm-kvm:
	@sudo rmmod kvm_intel 2>/dev/null || true
	@sudo rmmod kvm 2>/dev/null || true

docker-config:
	@sudo mkdir -p /root/.docker
	@sudo cp ~/.docker/config.json /root/.docker/config.json 2>/dev/null || echo "Docker config not found, skipping"
	@sudo chmod 600 /root/.docker/config.json 2>/dev/null || true

install-p3-tools:
	@bash p3/scripts/install_tools.sh

init: install-vagrant install-vbox rm-kvm hosts install-p3-tools docker-config

clean:
	@cd p1 2>/dev/null && vagrant destroy -f || true
	@cd p2 2>/dev/null && vagrant destroy -f || true
	@cd p3 2>/dev/null && vagrant destroy -f || true
	@cd bonus 2>/dev/null && vagrant destroy -f || true
	rm -rf p1/.vagrant p2/.vagrant p3/.vagrant bonus/.vagrant
	@vagrant global-status --prune 2>/dev/null || true

clean-gitlab:
	@bash bonus/scripts/clean_gitlab.sh

fclean: clean clean-gitlab hosts-clean
	@sudo apt remove -y vagrant virtualbox virtualbox-dkms 2>/dev/null || true
	@sudo apt autoremove -y 2>/dev/null || true

hosts:
	@grep -q "192.168.56.110.*app1.com" /etc/hosts || echo "192.168.56.110 app1.com app2.com app3.com" | sudo tee -a /etc/hosts > /dev/null

hosts-clean:
	@sudo sed -i '/app1.com/d' /etc/hosts 2>/dev/null || true

help:
	@echo "Available commands:"
	@echo ""
	@echo "  make init               - Complete setup (Vagrant, VirtualBox, P3 tools, Docker config)"
	@echo "  make install-vagrant    - Install Vagrant from official HashiCorp repository"
	@echo "  make install-vbox       - Install VirtualBox"
	@echo "  make install-p3-tools   - Install P3 tools (k3d, kubectl, helm, etc)"
	@echo "  make docker-config      - Copy Docker credentials to /root/.docker/"
	@echo "  make clean              - Destroy all Vagrant VMs"
	@echo "  make clean-gitlab       - Clean up GitLab (bonus section)"
	@echo "  make fclean             - Full cleanup (VMs + Vagrant + VirtualBox + hosts)"
	@echo "  make help               - Show this help message"
	@echo ""
