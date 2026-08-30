# ADR-0001: Use WSL2 Distributions as the Initial Lab Backend

- Status: Accepted
- Date: 2026-08-30

## Context

The project needs a reproducible multi-node Linux laboratory on a Windows workstation. The environment must support systemd, SSH, Ansible and common networking tools without introducing paid cloud resources.

## Decision

Use one Ubuntu WSL2 distribution as the control node and two imported copies as target nodes. Treat them as isolated lab instances while explicitly documenting that they share the WSL2 kernel.

## Alternatives

- VirtualBox and Vagrant provide stronger VM isolation but add a second virtualization stack and may conflict with Hyper-V-backed WSL2.
- Cloud virtual machines provide realistic networking but create cost, credential and cleanup risks for an early learning stage.
- Docker containers are fast but are less suitable for systemd, boot and host-level administration exercises.

## Consequences

- The lab remains local, inexpensive and scriptable.
- Filesystem, service and user-management exercises remain representative.
- Kernel-level isolation and independent node failure are not proven and must not be claimed.
- A later portability test should run the same Ansible roles against independent virtual machines.
