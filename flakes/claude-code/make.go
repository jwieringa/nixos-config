package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"regexp"
)

type NpmPackageInfo struct {
	DistTags struct {
		Latest string `json:"latest"`
	} `json:"dist-tags"`
}

type PackageJSON struct {
	Name         string            `json:"name"`
	Version      string            `json:"version"`
	Private      bool              `json:"private"`
	Dependencies map[string]string `json:"dependencies"`
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run make.go <task>")
		fmt.Println("Tasks: all, update-version, generate-lock, update-hash, build, update-flake, clean, commit")
		os.Exit(1)
	}

	task := os.Args[1]

	switch task {
	case "all":
		runAll()
	case "update-version":
		updateVersion()
	case "generate-lock":
		generateLock()
	case "update-hash":
		updateHash()
	case "build":
		build()
	case "update-flake":
		updateFlake()
	case "clean":
		clean()
	case "commit":
		commit()
	default:
		fmt.Printf("Unknown task: %s\n", task)
		os.Exit(1)
	}
}

func runAll() {
	fmt.Println("Running all tasks...")
	updateVersion()
	generateLock()
	updateHash()
	build()
	updateFlake()
	clean()
	commit()
}

func updateVersion() {
	fmt.Println("Updating claude-code package version...")

	// Fetch latest version from npmjs
	resp, err := http.Get("https://registry.npmjs.org/@anthropic-ai/claude-code")
	if err != nil {
		fmt.Printf("Error fetching package info: %v\n", err)
		os.Exit(1)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Printf("Error reading response: %v\n", err)
		os.Exit(1)
	}

	var packageInfo NpmPackageInfo
	if err := json.Unmarshal(body, &packageInfo); err != nil {
		fmt.Printf("Error parsing package info: %v\n", err)
		os.Exit(1)
	}

	latestVersion := packageInfo.DistTags.Latest
	fmt.Printf("Latest version: %s\n", latestVersion)

	// Update package.json
	updatePackageJSON(latestVersion)

	// Update flake.nix
	updateFlakeNix(latestVersion)
}

func updatePackageJSON(version string) {
	// Read package.json
	data, err := os.ReadFile("package.json")
	if err != nil {
		fmt.Printf("Error reading package.json: %v\n", err)
		os.Exit(1)
	}

	var pkg PackageJSON
	if err := json.Unmarshal(data, &pkg); err != nil {
		fmt.Printf("Error parsing package.json: %v\n", err)
		os.Exit(1)
	}

	// Update version
	pkg.Dependencies["@anthropic-ai/claude-code"] = "^" + version

	// Write back
	output, err := json.MarshalIndent(pkg, "", "  ")
	if err != nil {
		fmt.Printf("Error marshaling package.json: %v\n", err)
		os.Exit(1)
	}

	if err := os.WriteFile("package.json", output, 0644); err != nil {
		fmt.Printf("Error writing package.json: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Updated package.json to version %s\n", version)
}

func updateFlakeNix(version string) {
	// Read flake.nix
	data, err := os.ReadFile("flake.nix")
	if err != nil {
		fmt.Printf("Error reading flake.nix: %v\n", err)
		os.Exit(1)
	}

	content := string(data)

	// Replace version in flake.nix
	versionRegex := regexp.MustCompile(`version = "[^"]+";`)
	content = versionRegex.ReplaceAllString(content, fmt.Sprintf(`version = "%s";`, version))

	if err := os.WriteFile("flake.nix", []byte(content), 0644); err != nil {
		fmt.Printf("Error writing flake.nix: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Updated flake.nix to version %s\n", version)
}

func generateLock() {
	fmt.Println("Generating package-lock.json...")
	cmd := exec.Command("/run/current-system/sw/bin/nix-shell", "-p", "nodejs", "--run", "npm install --package-lock-only")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("Error generating lock file: %v\n", err)
		os.Exit(1)
	}
}

func updateHash() {
	fmt.Println("Updating npmDepsHash...")
	cmd := exec.Command("/run/current-system/sw/bin/nix", "build", ".#get-hash")
	output, err := cmd.CombinedOutput()
	if err != nil {
		// This is expected to fail - we want to capture the hash from the error output
		outputStr := string(output)

		// Extract sha256 hash from the output
		hashRegex := regexp.MustCompile(`got:\s+(sha256-[A-Za-z0-9+/=]+)`)
		matches := hashRegex.FindStringSubmatch(outputStr)

		if len(matches) < 2 {
			fmt.Printf("Could not extract hash from output: %s\n", outputStr)
			os.Exit(1)
		}

		newHash := matches[1]
		fmt.Printf("Got new hash: %s\n", newHash)

		// Update flake.nix with new hash
		data, err := os.ReadFile("flake.nix")
		if err != nil {
			fmt.Printf("Error reading flake.nix: %v\n", err)
			os.Exit(1)
		}

		content := string(data)
		hashRegex = regexp.MustCompile(`npmDepsHash = "[^"]+";`)
		content = hashRegex.ReplaceAllString(content, fmt.Sprintf(`npmDepsHash = "%s";`, newHash))

		if err := os.WriteFile("flake.nix", []byte(content), 0644); err != nil {
			fmt.Printf("Error writing flake.nix: %v\n", err)
			os.Exit(1)
		}

		fmt.Printf("Updated npmDepsHash to %s\n", newHash)
	}
}

func build() {
	fmt.Println("Building claude-code...")
	cmd := exec.Command("/run/current-system/sw/bin/nix", "build", ".#claude-code")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("Error building: %v\n", err)
		os.Exit(1)
	}
}

func updateFlake() {
	fmt.Println("Updating flake.lock...")
	cmd := exec.Command("/run/current-system/sw/bin/nix", "flake", "update")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("Error updating flake: %v\n", err)
		os.Exit(1)
	}
}

func clean() {
	fmt.Println("Cleaning up...")
	if err := os.Remove("result"); err != nil && !os.IsNotExist(err) {
		fmt.Printf("Error removing result: %v\n", err)
		os.Exit(1)
	}
}

func commit() {
	fmt.Println("Committing changes...")

	// Git add

	cmd := exec.Command("git", "add", "flake.nix", "flake.lock", "package.json", "package-lock.json")
	if err := cmd.Run(); err != nil {
		fmt.Printf("Error adding files: %v\n", err)
		os.Exit(1)
	}

	// Git commit
	cmd = exec.Command("git", "commit", "-m", "Update claude code to latest version")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("Error committing: %v\n", err)
		os.Exit(1)
	}
}
