function reload --description 're-source system and personal fish config'
    source /etc/fish/config.fish
    if test -f ~/.config/fish/config.fish
        source ~/.config/fish/config.fish
    end
end
