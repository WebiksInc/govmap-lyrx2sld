#!/usr/bin/env bash
#
# Build the docker image and push it to ECR.
#
# Usage:
#   publish.sh --base <ecr-registry-uri> --name <image-name> --version <version> [--profile <aws-profile>]
#
# Example:
#   publish.sh --base 472034923330.dkr.ecr.il-central-1.amazonaws.com --name govmap/lyrx2sld --version 4.0.0
#
# The AWS profile is taken from --profile, then the AWS_PROFILE env var, then the default profile.

set -euo pipefail

usage() {
    sed -n '2,/^$/{s/^# \{0,1\}//p}' "$0"
    exit 1
}

BASE_URI=""
IMAGE_NAME=""
VERSION=""
PROFILE="${AWS_PROFILE:-}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --base)    BASE_URI="$2";   shift 2 ;;
        --name)    IMAGE_NAME="$2"; shift 2 ;;
        --version) VERSION="$2";    shift 2 ;;
        --profile) PROFILE="$2";    shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown argument: $1" >&2; usage ;;
    esac
done

[[ -n "$BASE_URI" ]]   || { echo "Missing required argument: --base" >&2; usage; }
[[ -n "$IMAGE_NAME" ]] || { echo "Missing required argument: --name" >&2; usage; }
[[ -n "$VERSION" ]]    || { echo "Missing required argument: --version" >&2; usage; }

# Registry URI looks like <account>.dkr.ecr.<region>.amazonaws.com
REGION="$(echo "$BASE_URI" | sed -n 's/^[0-9]*\.dkr\.ecr\.\([a-z0-9-]*\)\.amazonaws\.com$/\1/p')"
[[ -n "$REGION" ]] || { echo "Could not extract region from base URI: $BASE_URI" >&2; exit 1; }

AWS_ARGS=(--region "$REGION")
[[ -n "$PROFILE" ]] && AWS_ARGS+=(--profile "$PROFILE")

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FULL_IMAGE="${BASE_URI}/${IMAGE_NAME}:${VERSION}"

echo "Logging in to ${BASE_URI} (region: ${REGION}${PROFILE:+, profile: ${PROFILE}})"
aws ecr get-login-password "${AWS_ARGS[@]}" | docker login --username AWS --password-stdin "$BASE_URI"

echo "Building ${FULL_IMAGE}"
docker build --tag "$FULL_IMAGE" "$REPO_ROOT"

echo "Pushing ${FULL_IMAGE}"
docker push "$FULL_IMAGE"

echo "Done: ${FULL_IMAGE}"
