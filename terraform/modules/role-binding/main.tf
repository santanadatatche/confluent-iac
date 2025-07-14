terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.32.0"
    }
  }
}

resource "confluent_role_binding" "this" {
  principal = var.service_account_id
  role_name  = var.role_name
  crn_pattern = var.crn_pattern
}

# Add delay to ensure role binding is propagated
resource "time_sleep" "wait_for_role_binding" {
  depends_on = [confluent_role_binding.this]
  create_duration = "30s"
}