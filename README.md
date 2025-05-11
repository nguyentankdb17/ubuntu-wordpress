# ubuntu-wordpress
This repository automates the creation and deployment of a WordPress-ready virtual machine using **Packer** and **Terraform** on a local **KVM/QEMU** environment with **Ubuntu 22.04** as the base OS.

---

## 📁 Folder Structure

```bash
.
├── image-packer/           # Contains Packer templates to build a WordPress pre-configured VM image
└── terraform-template/        # Contains Terraform scripts to launch the VM on KVM using the built image
