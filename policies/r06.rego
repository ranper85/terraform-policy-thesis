package terraform.policies.r06

import rego.v1

# CIS Azure Benchmark v3.0.0 - Architecture / Data Residency
# Rationale: GDPR requires personal data stays within approved geographic
# boundaries. Sweden-based project — only EU regions permitted.

allowed_regions := {"westeurope", "northeurope", "swedencentral"}

deny contains msg if {
	some resource in input.resource_changes
	"create" in resource.change.actions
	location := resource.change.after.location
	location != null
	location != ""
	not location in allowed_regions
	msg := sprintf(
		"R-06 VIOLATION: Resource '%s' deploys to '%s' — only EU regions are permitted: %v",
		[resource.address, location, allowed_regions],
	)
}
