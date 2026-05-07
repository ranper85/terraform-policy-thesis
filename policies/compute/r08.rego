package terraform.policies.r08

import rego.v1

# CIS Azure Benchmark v6.0.0 - Virtual Machines
# Rationale: Encryption at rest is the most consistently neglected
# security category in real-world Terraform projects (Verdet et al., 2025).
# Unencrypted managed disks expose data if the underlying storage is compromised.

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "azurerm_managed_disk"
	"create" in resource.change.actions
	not resource.change.after.disk_encryption_set_id
	not resource.change.after.encryption_settings
	msg := sprintf(
		"R-08 VIOLATION: Managed disk '%s' does not have encryption configured — encryption at rest is required",
		[resource.address],
	)
}

# Also check OS disk encryption on VMs
deny contains msg if {
	some resource in input.resource_changes
	resource.type == "azurerm_linux_virtual_machine"
	"create" in resource.change.actions
	some os_disk in resource.change.after.os_disk
	not os_disk.disk_encryption_set_id
	os_disk.encryption_settings == null
	msg := sprintf(
		"R-08 VIOLATION: VM '%s' OS disk does not have encryption configured — encryption at rest is required",
		[resource.address],
	)
}
