function wlp --wraps=fish_clipboard_paste --description 'paste from clipboard (needs a clipboard backend; browsers block clipboard reads)'
    fish_clipboard_paste $argv
end
