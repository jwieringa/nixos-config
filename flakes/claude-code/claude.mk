.PHONY: all update-version generate-lock update-hash build update-flake clean commit

all: update-version generate-lock update-hash build update-flake clean commit

# 1) Update claude-code package version
update-version:
	/run/current-system/sw/bin/claude -p "Fetch the latest version of https://www.npmjs.com/package/@anthropic-ai/claude-code. Update package.json and flake.nix with the latest version." --allowedTools "Edit(flake.nix)" "Edit(package.json)" "WebFetch(domain:npmjs.com)"

# 2) Generate package-lock.json
generate-lock:
	/run/current-system/sw/bin/nix-shell -p nodejs --run "npm install --package-lock-only"

# 3) Generate sha256 and update flake.nix
update-hash:
	/run/current-system/sw/bin/nix build .#get-hash 2>&1 | /run/current-system/sw/bin/claude -p "Update flake.nix npmDepsHash with got: sha256" --allowedTools "Edit(flake.nix)"

# 4) Create the build
build:
	/run/current-system/sw/bin/nix build .#claude-code

# 5) Update flake.lock
update-flake:
	/run/current-system/sw/bin/nix flake update

# 6) Clean up build results
clean:
	rm result

# 7) Commit changes
commit:
	git add . && git commit -m "Update claude code to latest version"
