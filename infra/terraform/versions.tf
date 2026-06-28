terraform {
  required_version = ">= 1.6"

  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      # 5.7.0+ adds content_file/content_sha256 (keeps script body out of state);
      # 5.8.0+ fixes spurious plan diffs on secret_text bindings.
      version = "~> 5.8"
    }
  }

  # Remote state on Cloudflare R2 (S3-compatible) so local and CI share one state.
  # bucket + endpoints are supplied at init via -backend-config (see infra/README.md)
  # to keep account-specific values out of the repo.
  backend "s3" {
    key    = "scheduler/terraform.tfstate"
    region = "auto"

    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "cloudflare" {
  # Authenticates with the CLOUDFLARE_API_TOKEN environment variable.
  # The token needs the "Workers Scripts: Edit" account permission.
}
