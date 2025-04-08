---
title: Non-RCI Servers
parent: Computational Resources
---

# Non-RCI Servers

These are smaller, flexible servers that you access via SSH. They're ideal for:
- Getting started with GPUs
- Running small-scale or interactive jobs
- Debugging with PyCharm or Jupyter

## 🔐 VPN & SSH Access

- Use [OpenVPN](https://svti.fel.cvut.cz/docs/#/vpn) (recommended over Tunnelblick on macOS).
- Connect with:  
  ```bash
  ssh username@server_name.felk.cvut.cz
  ```
  Example servers: `duda`, `ptak`. Some machines (like `cmp-grid79`) act as jump hosts.

## 🔑 SSH Keys

- [Generate and manage SSH keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh)
- [Copy SSH key to remote server](https://askubuntu.com/questions/4830/easiest-way-to-copy-ssh-keys-to-another-machine)

## 📁 Data & Storage

- Main locations: `/home`, `/datagrid/personal/username`, and shared `/datagrid/public_datasets`
- Avoid duplicating large datasets; use symbolic links if needed.
- [Storage docs](https://k13133.felk.cvut.cz/cmp/storage)

## ⚙️ Python and Other Software Setup

See [Python environment setup](/docs/python#python-environment-setup).

## 🚀 Running Experiments

- Check GPU usage with `nvidia-smi`
- Set GPU visibility:
  ```bash
  export CUDA_VISIBLE_DEVICES=0  # Or 0,1 or 4,7
  ```
- Use `screen` or `tmux` to keep processes alive after logout:
  ```bash
  screen -S myjob
  Ctrl+A D  # Detach
  screen -r myjob  # Reattach
  ```

## 🐞 Debugging & Remote Tools

- [Remote SSH interpreter (PyCharm)](https://www.jetbrains.com/help/pycharm/configuring-remote-interpreters-via-ssh.html)
- [Multi-hop SSH (if server is behind a jump host)](https://stackoverflow.com/questions/37827685/pycharm-configuring-multi-hop-remote-interpreters-via-ssh)
- [Remote Jupyter setup](https://stackoverflow.com/questions/69244218/how-to-run-a-jupyter-notebook-through-a-remote-server-on-local-machine)

## 🔄 File Sync

- Use PyCharm deployment or:
  ```bash
  rsync -avz myfile.py username@server:/home/username/project/
  scp model.ckpt username@server:/datagrid/personal/username/
  ```
- SSHFS works but can be tricky on macOS.
