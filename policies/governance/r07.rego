package terraform.policies.r07

import rego.v1

# CIS Azure Benchmark v6.0.0 - Logging and Monitoring
# Rationale: Mandatory tags enable cost tracking and observability.
# Directly addresses the logging/monitoring gap identified by Verdet et al. (2025).

required_tags := ["environment", "owner", "cost-center"]

# These Azure resource types do not support tags — exclude them from the check
tag_exempt_types := {
	"azurerm_key_vault_access_policy",
	"azurerm_key_vault_key",
	"azurerm_mssql_firewall_rule",
	"azurerm_network_security_rule",
	"azurerm_role_assignment",
	"azurerm_subnet",
}

deny contains msg if {
	some resource in input.resource_changes
	"create" in resource.change.actions
	not tag_exempt_types[resource.type]
	some required_tag in required_tags
	not resource.change.after.tags[required_tag]
	msg := sprintf(
		"R-07 VIOLATION: Resource '%s' is missing required tag '%s' — all resources must have: %v",
		[resource.address, required_tag, required_tags],
	)
}
