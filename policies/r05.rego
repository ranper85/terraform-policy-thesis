package terraform.policies.r05

import rego.v1

# CIS Azure Benchmark v3.0.0 - Networking
# Rationale: SSH (22) and RDP (3389) open to 0.0.0.0/0 allow anyone
# on the internet to attempt to connect to your VMs.

open_to_internet := {"0.0.0.0/0", "*", "::/0"}

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "azurerm_network_security_rule"
	"create" in resource.change.actions
	rule := resource.change.after
	rule.direction == "Inbound"
	rule.access == "Allow"
	rule.destination_port_range == "22"
	rule.source_address_prefix in open_to_internet
	msg := sprintf(
		"R-05 VIOLATION: Network rule '%s' exposes SSH (port 22) to the internet (%s) — restrict to known IP ranges",
		[resource.address, rule.source_address_prefix],
	)
}

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "azurerm_network_security_rule"
	"create" in resource.change.actions
	rule := resource.change.after
	rule.direction == "Inbound"
	rule.access == "Allow"
	rule.destination_port_range == "3389"
	rule.source_address_prefix in open_to_internet
	msg := sprintf(
		"R-05 VIOLATION: Network rule '%s' exposes RDP (port 3389) to the internet (%s) — restrict to known IP ranges",
		[resource.address, rule.source_address_prefix],
	)
}
