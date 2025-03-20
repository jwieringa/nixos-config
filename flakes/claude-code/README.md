# Claude Code Nix Package

This flake provides a Nix package for Claude Code, Anthropic's official CLI tool for Claude.

## Usage

### Within this flake

The Claude CLI is available in the system packages.

### Usage in other flakes

Add this flake as an input to your configuration:

```nix
{
  inputs = {
    # ... other inputs
    claude-code.url = "github:jwieringa/nixos-config?dir=flakes/claude-code";
  };
  
  # In your system configuration:
  environment.systemPackages = [
    inputs.claude-code.packages.${system}.default
  ];
}
```
