# Advisory (non-blocking) plan-time warnings for the log collection pipelines.
#
# `check` blocks emit WARNINGS (never block) so operators see the detection consequences of a
# disabled pipeline during `terraform plan` without being stopped.
#
# The blocking guards (empty category list while Activity Logs are enabled, and the fully-blind
# state of both pipelines off without acknowledgement) are implemented as variable `validation`
# blocks (see variables.tf). Terraform >= 1.9 allows a variable validation to reference other
# variables, so these cross-variable rules fail early at `terraform validate` without adding a
# resource to state.

check "activity_logs_disabled_warning" {
  assert {
    condition = var.enable_activity_logs
    error_message = join(" ", [
      "Activity Log collection is DISABLED (enable_activity_logs = false).",
      "Control-plane-based Skyhawk detections (administrative, security, policy, health) will be degraded.",
    ])
  }
}

check "flow_logs_disabled_warning" {
  assert {
    condition = var.enable_vnet_flow_logs
    error_message = join(" ", [
      "VNet/NSG flow log collection is DISABLED (enable_vnet_flow_logs = false).",
      "Network-based Skyhawk detections will be degraded.",
    ])
  }
}
