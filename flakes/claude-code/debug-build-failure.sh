#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

echo "=== Claude Code Build Failure Debug Script ==="

# Check for claude command early
if ! command -v claude >/dev/null 2>&1; then
    echo "ERROR: claude command not found. Please install Claude Code first."
    echo "Visit: https://claude.ai/download"
    exit 1
fi

echo "Running Claude in headless mode to debug build failures..."

# Create a debug prompt for Claude
cat > debug_prompt.md << 'EOF'
I'm debugging a failed Claude Code update process. The build process involves:

1. Updating package.json with latest @anthropic-ai/claude-code version
2. Generating package-lock.json with npm install --package-lock-only
3. Building with nix to get the correct npmDepsHash 
4. Updating flake.nix with the new hash
5. Running nix build .#claude-code to verify the build works
6. Updating flake.lock

IMPORTANT: Keep running `go run make.go all` repeatedly until ALL errors are resolved and the command completes successfully without any failures. Do not stop after the first attempt - continue fixing issues and re-running until everything works.

Please analyze any error logs and build failures, then fix the issues found.
Common issues to check:
- Package dependency conflicts in package.json
- Build failures in flake.nix 
- Hash mismatches in npmDepsHash
- Nix expression syntax errors
- Go build issues in make.go
- Missing or incorrect dependencies

Your task is not complete until `go run make.go all` runs successfully from start to finish with no errors.
EOF

# Run Claude in headless mode to debug and fix issues
echo "Running Claude to analyze and fix build issues..."
claude -p "$(cat debug_prompt.md)" --allowedTools "Edit(make.go)" > claude_output.log 2>&1

# Create PR description from Claude's output
echo "## Claude Code Debug Session" > claude_pr_description.md
echo "" >> claude_pr_description.md
echo "Claude automatically debugged and fixed the following build issues:" >> claude_pr_description.md
echo "" >> claude_pr_description.md
echo "\`\`\`" >> claude_pr_description.md
cat claude_output.log >> claude_pr_description.md
echo "\`\`\`" >> claude_pr_description.md

echo "=== Debug script completed successfully ==="

# Clean up
rm -f debug_prompt.md
