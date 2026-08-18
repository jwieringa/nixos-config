{ ... }:

{
  # Google Chrome publishes no aarch64 Linux build, so we run Chromium instead.
  # Claude Code's Chrome integration detects the extension in any Chromium-based
  # browser, so Chromium gives us the same capability.
  #
  # See https://code.claude.com/docs/en/chrome
  programs.chromium = {
    enable = true;

    # Render natively on Wayland rather than through XWayland, which lets
    # GNOME's HiDPI scaling apply to Chromium.
    commandLineArgs = [ "--ozone-platform-hint=auto" ];

    extensions = [
      # Claude in Chrome
      # https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn
      { id = "fcoeoabgfenejglbffodgkkbkcdhcgfn"; }
    ];

    # Deliberately left unset: setting programs.chromium.nativeMessagingHosts
    # replaces ~/.config/chromium/NativeMessagingHosts with a read-only symlink
    # into the Nix store, and Claude Code needs to write its own host manifest
    # into that directory when it first connects to the extension.
  };
}
