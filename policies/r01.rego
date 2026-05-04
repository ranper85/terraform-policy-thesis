package terraform.policies.r01

import rego.v1

# CIS Azure Benchmark v3.0.0 - Virtual Machines
# Rationale: Oversized VMs in development environments are the most
# direct source of unnecessary cloud spend.

allowed_vm_sizes := [
	"Standard_B1s",
	"Standard_B2s",
	"Standard_B1ms",
	"Standard_B2ms",
]

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "azurerm_linux_virtual_machine"
	"create" in resource.change.actions
	size := resource.change.after.size
	not size in allowed_vm_sizes
	msg := sprintf(
		"R-01 VIOLATION: VM '%s' uses disallowed size '%s'. Allowed sizes: %v",
		[resource.address, size, allowed_vm_sizes],
	)
}
