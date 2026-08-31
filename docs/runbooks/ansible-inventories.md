# Ansible Inventories and Vault Workflow

## Development

`inventory/dev/hosts.yml` targets the two local WSL2 SSH socket ports. The committed inventory contains no private-key path or secret. Copy the generated SSH material to the control node and provide it through the local SSH agent or an ignored inventory override.

```bash
ansible-inventory -i inventory/dev/hosts.yml --graph
ansible linux_nodes -i inventory/dev/hosts.yml -m ping
ansible-playbook -i inventory/dev/hosts.yml playbooks/site.yml
ansible-playbook -i inventory/dev/hosts.yml playbooks/verify.yml
```

## Prod-like

`inventory/prod-like/hosts.yml` uses the reserved `.invalid` namespace so an accidental command cannot reach a real host. Replace the example hosts only in an approved private inventory source.

```bash
ansible-inventory -i inventory/prod-like/hosts.yml --graph
ansible-playbook --syntax-check -i inventory/prod-like/hosts.yml playbooks/site.yml
```

The prod-like variables increase journal retention and file-descriptor limits without weakening SSH controls.

## Vault

The committed `vault.example.yml` contains instructions only. Create an ignored encrypted copy when a real environment requires secrets:

```bash
cp inventory/prod-like/group_vars/vault.example.yml \
  inventory/prod-like/group_vars/vault.yml
ansible-vault encrypt inventory/prod-like/group_vars/vault.yml
ansible-playbook \
  -i inventory/prod-like/hosts.yml \
  --ask-vault-pass \
  playbooks/site.yml
```

Do not pass a vault password on the command line or commit a vault password file. CI should receive the password from an approved secret store and write any temporary password file with mode `0600` before deleting it.

## Validation

```bash
task ansible:inventory
task ansible:syntax
task ansible:lint
```
