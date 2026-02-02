.PHONY: install-vagrant install-vbox init clean fclean help

install-vagrant:
	wget -qO - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null || true
	echo "deb [arch=$$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
	sudo apt update && sudo apt install -y vagrant
	@vagrant --version

install-vbox:
	sudo apt install -y virtualbox virtualbox-dkms
	@vboxmanage --version

init: install-vagrant install-vbox

clean:
	@cd p1 2>/dev/null && vagrant destroy -f || true
	@cd p2 2>/dev/null && vagrant destroy -f || true
	@cd p3 2>/dev/null && vagrant destroy -f || true
	@cd bonus 2>/dev/null && vagrant destroy -f || true
	rm -rf p1/.vagrant p2/.vagrant p3/.vagrant bonus/.vagrant
	vagrant global-status --prune

fclean: clean
	sudo apt remove -y vagrant virtualbox virtualbox-dkms
	sudo apt autoremove -y

help:
	@echo "Available commands:"
	@echo ""
	@echo "  make init               - Install Vagrant AND VirtualBox"
	@echo "  make install-vagrant    - Install Vagrant from official HashiCorp repository"
	@echo "  make install-vbox       - Install VirtualBox"
	@echo "  make clean              - Destroy all Vagrant VMs"
	@echo "  make fclean             - Destroy all VMs AND uninstall Vagrant/VirtualBox"
	@echo "  make help               - Show this help message"
	@echo ""
