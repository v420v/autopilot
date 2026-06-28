# infra — Cloudflare Workers scheduler

GitHub Actions is a great executor but a poor scheduler: its `schedule:` cron is
best-effort and drops most short-interval ticks (a `*/15` cron really fires
roughly once an hour). So scheduling lives here, on **Cloudflare Workers Cron
Triggers**, while execution stays on GitHub Actions.

A single Worker ([`scheduler/src/index.ts`](scheduler/src/index.ts)) has cron triggers.
When one fires, the Worker calls the GitHub [`workflow_dispatch` API][dispatch]
for the workflows mapped to that cron — reliably, on time. The workflows are
otherwise unchanged: their GitHub `schedule:` triggers were removed (Cloudflare
is now the only scheduler), but `workflow_dispatch` and the `workflow_run` chains
remain.

| Cron (UTC) | Dispatches |
| --- | --- |
| `*/15 * * * *` | resolve-conflicts, review-prs, address-review, slack |
| `0 18 * * *` (03:00 JST) | suggest-issues → chains to implement → review → address |

## Layout

```
infra/
  scheduler/             the Worker (TypeScript, compiled to JS for upload)
    src/index.ts         source of truth (strictly typed)
    dist/index.js        build output Terraform uploads (gitignored)
    package.json         tsc + @cloudflare/workers-types
  terraform/             deploys the Worker + its cron triggers
```

## Deploy

Prerequisites: a Cloudflare account and a GitHub PAT. `nix develop` provides the
`terraform` and `node` CLIs (or install Terraform ≥ 1.6 and Node ≥ 20 yourself).

1. **GitHub token** — fine-grained PAT scoped to this repo with **Actions: Read
   and write** (or a classic PAT with `repo` + `workflow`). The Worker uses it to
   dispatch workflows. You can reuse the repo's existing `GH_TOKEN` value.

2. **Cloudflare API token** — create one with the **Workers Scripts: Edit**
   account permission. Note your **Account ID** (dashboard → Workers & Pages, or
   any zone's overview pane).

3. **Build the Worker** (TypeScript → `dist/index.js`, which Terraform uploads):

   ```sh
   cd infra/scheduler
   npm ci
   npm run build
   ```

4. **Configure & apply:**

   ```sh
   cd ../terraform
   cp terraform.tfvars.example terraform.tfvars   # set cloudflare_account_id
   export CLOUDFLARE_API_TOKEN=...                 # Cloudflare token (step 2)
   export TF_VAR_github_token=...                  # GitHub PAT (step 1)
   terraform init
   terraform plan
   terraform apply
   ```

## Verify

- `npx wrangler tail autopilot-scheduler` — live logs; each cron tick prints
  `dispatched <workflow> …` (npx fetches wrangler on demand; or use the
  dashboard → the Worker → Logs).
- Dashboard → Workers & Pages → `autopilot-scheduler` → Settings → Triggers shows
  the cron schedules; **Cron Events** lets you fire one manually.
- After a tick, the runs appear under the repo's **Actions** tab marked
  "triggered via workflow_dispatch".

## Notes

- **Cutover order:** apply Terraform and confirm a dispatch works *before* merging
  the workflow changes that drop the GitHub `schedule:` triggers, so there's no
  scheduling gap. A brief overlap is harmless — each workflow's skip-guard drops a
  duplicate tick if a run is already active.
- The `github_token` is stored as a Worker `secret_text` binding, so it lands in
  Terraform state. Keep state private (local `*.tfstate` is gitignored here; use
  an encrypted remote backend if you share it).
- After editing `scheduler/src/index.ts`, run `npm run build` so `dist/index.js`
  (and thus `content_sha256`) changes — the next `terraform apply` redeploys.
  Keep the cron strings in `src/index.ts` and `terraform/main.tf` in sync.

[dispatch]: https://docs.github.com/en/rest/actions/workflows#create-a-workflow-dispatch-event
