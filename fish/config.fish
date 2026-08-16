# System-wide fish defaults for the remote-dev-env workstation.
# Sourced BEFORE the per-user config (~/.config/fish/config.fish, persisted
# via the ./data/config bind mount), so anything here can be overridden or
# extended per user. Keep this file generic - no personal shortcuts.

# Make user-installed tools (npm -g, Grok Build) reachable no matter how
# this shell was started - the container ENV already covers VS Code
# terminals, but not e.g. non-login or stripped environments.
fish_add_path -g $HOME/.local/bin $HOME/.grok/bin

if status is-interactive

    # Prompt & navigation (all guarded - the image ships these tools,
    # but a degraded shell is better than a broken one)
    command -q starship; and starship init fish | source
    command -q zoxide; and zoxide init fish | source
    command -q direnv; and direnv hook fish | source
    command -q fzf; and fzf --fish 2>/dev/null | source

    # No greeting
    set fish_greeting

    # Sensible editor default (neovim is in the image)
    set -q EDITOR; or set -gx EDITOR nvim
    set -q VISUAL; or set -gx VISUAL nvim

    # Opt-in: vi key bindings. Comment in if you want them, or set
    #   set -g fish_key_bindings fish_vi_key_bindings
    # in your personal ~/.config/fish/config.fish.
    # set -g fish_key_bindings fish_vi_key_bindings

end
