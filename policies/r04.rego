package terraform.policies.r04

import rego.v1

# CIS Azure Benchmark v3.0.0 - Identity and Access Management
# Rationale: Owner and Contributor roles grant full control over Azure
# resources, violating the principle of least privilege.

denied_roles := ["Owner", "Contributor"]

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "azurerm_role_assignment"
	"create" in resource.change.actions
	role := resource.change.after.role_definition_name
	role in denied_roles
	msg := sprintf(
		"R-04 VIOLATION: Role assignment '%s' uses overly permissive role '%s' — use least-privilege roles such as Reader",
		[resource.address, role],
	)
}
