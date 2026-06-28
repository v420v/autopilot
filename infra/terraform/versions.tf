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
}

provider "cloudflare" {
  # Authenticates with the CLOUDFLARE_API_TOKEN environment variable.
  # The token needs the "Workers Scripts: Edit" account permission.
}
