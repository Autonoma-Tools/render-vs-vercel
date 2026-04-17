#!/usr/bin/env bash
#
# render-webhook-relay.sh
#
# Render's deploy webhook cannot POST directly to a repository_dispatch event
# because it needs a GitHub token. This script shows the shape of the relay:
# take a Render "deploy succeeded" payload on stdin and forward it to GitHub.
#
# Typical setup: deploy this as a tiny serverless function (Cloudflare Worker,
# Vercel/Netlify function, AWS Lambda, etc.) and point Render's webhook at it.
# The function reads the Render payload, verifies the Render signature, then
# runs the curl command below.
#
# Required env:
#   GITHUB_TOKEN    — a fine-grained PAT with "Contents: read, Metadata: read,
#                     Actions: write" on Autonoma-Tools/render-vs-vercel
#                     (or your own companion repo).
#   GITHUB_REPO     — owner/repo, e.g. "Autonoma-Tools/render-vs-vercel"
#
# Usage (local test):
#   cat render-payload.json | ./render-webhook-relay.sh

set -euo pipefail

: "${GITHUB_TOKEN:?GITHUB_TOKEN must be set}"
: "${GITHUB_REPO:?GITHUB_REPO must be set (owner/repo)}"

# Read the Render payload from stdin.
PAYLOAD=$(cat)

# Render's deploy webhook schema (2026):
#   { "type": "deploy", "data": { "deploy": { "status": "live",
#     "commit": { "id": "abc123" } }, "service": { "name": "api",
#     "serviceDetails": { "url": "https://my-service-pr-42.onrender.com" } } } }
#
# Only fire on "live" deploys — that's the Render status that means the
# preview is reachable.
STATUS=$(jq -r '.data.deploy.status // empty' <<<"${PAYLOAD}")
if [ "${STATUS}" != "live" ]; then
  echo "Render deploy status is '${STATUS}', skipping."
  exit 0
fi

PREVIEW_URL=$(jq -r '.data.service.serviceDetails.url // empty' <<<"${PAYLOAD}")
COMMIT_SHA=$(jq -r '.data.deploy.commit.id // empty' <<<"${PAYLOAD}")
SERVICE_NAME=$(jq -r '.data.service.name // empty' <<<"${PAYLOAD}")

if [ -z "${PREVIEW_URL}" ]; then
  echo "::error::Could not extract preview URL from Render payload." >&2
  exit 1
fi

# Build the repository_dispatch body. client_payload shows up on the workflow
# as github.event.client_payload.*
DISPATCH_BODY=$(jq -n \
  --arg preview_url "${PREVIEW_URL}" \
  --arg commit_sha  "${COMMIT_SHA}" \
  --arg service     "${SERVICE_NAME}" \
  '{
     event_type: "render-deploy",
     client_payload: {
       preview_url: $preview_url,
       commit_sha:  $commit_sha,
       service:     $service
     }
   }')

echo "Dispatching to GitHub for preview: ${PREVIEW_URL}"

curl --fail --silent --show-error \
  --request POST \
  --header "Accept: application/vnd.github+json" \
  --header "Authorization: Bearer ${GITHUB_TOKEN}" \
  --header "X-GitHub-Api-Version: 2022-11-28" \
  --data "${DISPATCH_BODY}" \
  "https://api.github.com/repos/${GITHUB_REPO}/dispatches"

echo "Dispatched render-deploy event to ${GITHUB_REPO}."
