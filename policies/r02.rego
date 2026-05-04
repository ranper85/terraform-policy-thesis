package terraform.policies.r02

import rego.v1

# CIS Azure Benchmark v3.0.0 - Storage Accounts
# Rationale: Premium storage costs significantly more than Standard
# and is not appropriate for development environments.

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "azurerm_storage_account"
	"create" in resource.change.actions
	resource.change.after.account_tier == "Premium"
	msg := sprintf(
		"R-02 VIOLATION: Storage account '%s' uses Premium tier — not permitted in dev environment",
		[resource.address],
	)
}
