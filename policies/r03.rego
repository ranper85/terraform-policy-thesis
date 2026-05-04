package terraform.policies.r03

import rego.v1

# CIS Azure Benchmark v3.0.0 - Storage Accounts (Level 1 controls)
# Control 1: Public blob access exposes data to the internet without authentication
# Control 2: Allowing HTTP means data in transit is unencrypted

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "azurerm_storage_account"
	"create" in resource.change.actions
	resource.change.after.allow_nested_items_to_be_public == true
	msg := sprintf(
		"R-03 VIOLATION: Storage account '%s' has public blob access enabled — data is exposed to the internet",
		[resource.address],
	)
}

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "azurerm_storage_account"
	"create" in resource.change.actions
	resource.change.after.https_traffic_only_enabled == false
	msg := sprintf(
		"R-03 VIOLATION: Storage account '%s' allows HTTP traffic — HTTPS must be enforced",
		[resource.address],
	)
}
