# Opt-out safety controls for the log collection pipelines.
#
# This file holds the advisory warnings and the hard-failure guards that govern disabling the
# Activity Log pipeline (enable_activity_logs) and the Flow Log pipeline (enable_vnet_flow_logs).
#
# Two distinct mechanisms are used deliberately:
#   - `check` blocks emit WARNINGS (non-blocking) so operators see the detection consequences of a
#     disabled pipeline during `terraform plan` without being stopped.
#   - `terraform_data` preconditions emit ERRORS (blocking) for states that must not be applied
#     silently: an empty category list while Activity Logs are enabled, and the fully-blind state
#     (both pipelines off) without explicit acknowledgement. These are cross-variable rules, which a
#     single variable `validation` block cannot express.

# --- Advisory warnings (non-blocking) ------------------------------------------------------------

check "activity_logs_disabled_warning" {
  assert {
    condition = var.enable_activity_logs
    error_message = join(" ", [
      "Activity/Audit/Sign-in log collection is DISABLED (enable_activity_logs = false).",
      "Identity- and control-plane-based Skyhawk detections will be degraded.",
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

# --- Hard-failure guards (blocking) --------------------------------------------------------------

resource "terraform_data" "log_opt_out_guards" {
  input = {
    enable_activity_logs          = var.enable_activity_logs
    enable_vnet_flow_logs         = var.enable_vnet_flow_logs
    acknowledge_no_log_collection = var.acknowledge_no_log_collection
    activity_log_categories       = var.activity_log_categories
  }

  lifecycle {
    precondition {
      # At least one category must be selected when Activity Logs are enabled.
      condition = !var.enable_activity_logs || length(var.activity_log_categories) > 0
      error_message = join(" ", [
        "activity_log_categories must not be empty when enable_activity_logs = true.",
        "Select at least one category, or set enable_activity_logs = false to disable the pipeline.",
      ])
    }

    precondition {
      # Refuse a fully-blind posture (both pipelines off) unless explicitly acknowledged.
      condition = var.enable_activity_logs || var.enable_vnet_flow_logs || var.acknowledge_no_log_collection
      error_message = join(" ", [
        "Both enable_activity_logs and enable_vnet_flow_logs are false: NO security telemetry would",
        "reach Skyhawk for this tenant. If this is intentional, set acknowledge_no_log_collection = true",
        "to proceed.",
      ])
    }
  }
}
