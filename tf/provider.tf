provider "azurerm" {
  features {
  }
  use_oidc                        = false
  resource_provider_registrations = "none"
  subscription_id                 = "6f81ef09-202c-4e6b-9f7c-1fff436c0fbf"
  environment                     = "public"
  use_msi                         = false
  use_cli                         = true
}
