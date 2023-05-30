macaddress for VFs will be random. For intel nics, when the
nic is bound to vfio-pci driver, everytime the mac address is
queried by the application (using pci address), a junk mac will
be returned. Having mac hardcoded in the pod does not help in
testing the life-cycle, as the mac address change should re-route
the packets to the new instance of testpmd.

fpr this reason, a custom mac address generator unitity is
integrated with sriov-cni as a temp solution, until there is
cluster wide solution for this problem.
