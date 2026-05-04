package terraform.policies.r07

import rego.v1

# CIS Azure Benchmark v3.0.0 - Logging and Monitoring
# Rationale: Mandatory tags enable cost tracking and observability.
# Directly addresses the logging/monitoring gap identified by Verdet et al. (2025).

required_tags := ["environment", "owner", "cost-center"]

deny contains msg if {
	some resource in input.resource_changes
	"create" in resource.change.actions
	some required_tag in required_tags
	not resource.change.after.tags[required_tag]
	msg := sprintf(
		"R-07 VIOLATION: Resource '%s' is missing required tag '%s' — all resources must have: %v",
		[resource.address, required_tag, required_tags],
	)
}
