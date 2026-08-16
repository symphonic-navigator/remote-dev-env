function wlc --wraps=fish_clipboard_copy --description 'copy to clipboard (OSC 52 - works through the browser terminal)'
    fish_clipboard_copy $argv
end
