package terraform.policies.r09

import rego.v1

# CIS Azure Benchmark v3.0.0 - Database Services
# Rationale: Publicly accessible databases are exposed to the internet,
# creating a critical attack surface. Azure SQL should only be accessible
# from within approved network paths.

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "azurerm_mssql_firewall_rule"
	"create" in resource.change.actions
	resource.change.after.start_ip_address == "0.0.0.0"
	resource.change.after.end_ip_address == "255.255.255.255"
	msg := sprintf(
		"R-09 VIOLATION: SQL firewall rule '%s' allows access from all IP addresses — restrict to known IP ranges",
		[resource.address],
	)
}

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "azurerm_postgresql_firewall_rule"
	"create" in resource.change.actions
	resource.change.after.start_ip_address == "0.0.0.0"
	resource.change.after.end_ip_address == "255.255.255.255"
	msg := sprintf(
		"R-09 VIOLATION: PostgreSQL firewall rule '%s' allows access from all IP addresses — restrict to known IP ranges",
		[resource.address],
	)
}
