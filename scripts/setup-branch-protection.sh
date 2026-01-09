#!/bin/bash
#
# Setup GitHub branch protection rules for the main branch
# Usage: ./setup-branch-protection.sh [owner/repo]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed. Please install it first."
    echo "Visit: https://cli.github.com/"
    exit 1
fi

# Check if gh CLI is authenticated
if ! gh auth status &> /dev/null; then
    print_error "GitHub CLI is not authenticated. Please run 'gh auth login' first."
    exit 1
fi

print_status "GitHub CLI is authenticated"

# Get repository name
if [ -n "$1" ]; then
    REPO="$1"
else
    # Try to get repo from git remote
    if git remote get-url origin &> /dev/null; then
        REMOTE_URL=$(git remote get-url origin)
        # Extract owner/repo from various URL formats
        if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+/[^/.]+)(\.git)?$ ]]; then
            REPO="${BASH_REMATCH[1]}"
        else
            print_error "Could not parse repository from git remote URL: $REMOTE_URL"
            exit 1
        fi
    else
        print_error "No repository specified and could not detect from git remote."
        echo "Usage: $0 [owner/repo]"
        exit 1
    fi
fi

print_status "Setting up branch protection for repository: $REPO"

# Branch to protect
BRANCH="main"

# Build the JSON payload for branch protection rules
# Using GitHub REST API: PUT /repos/{owner}/{repo}/branches/{branch}/protection
PROTECTION_RULES=$(cat <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["lint", "build-test"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false,
  "lock_branch": false,
  "allow_fork_syncing": false
}
EOF
)

echo "Applying branch protection rules to '$BRANCH' branch..."

# Apply branch protection using gh api
if gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/${REPO}/branches/${BRANCH}/protection" \
    --input - <<< "$PROTECTION_RULES" > /dev/null 2>&1; then

    print_status "Branch protection rules applied successfully!"
    echo ""
    echo "Protection rules configured for '$BRANCH' branch:"
    echo "  - Require pull request before merging: Yes"
    echo "  - Required approvals: 1"
    echo "  - Required status checks: lint, build-test"
    echo "  - Require branches to be up-to-date: Yes"
    echo "  - Require linear history: Yes"
    echo "  - Allow force pushes: No"
    echo "  - Allow deletions: No"
else
    print_error "Failed to apply branch protection rules"
    echo ""
    echo "Attempting to get more details..."
    gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/${REPO}/branches/${BRANCH}/protection" \
        --input - <<< "$PROTECTION_RULES" 2>&1 || true
    exit 1
fi

echo ""
print_status "Branch protection setup complete for $REPO"
