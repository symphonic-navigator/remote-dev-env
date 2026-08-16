function clear --description 'clear screen including scrollback'
    printf '\033[2J\033[3J\033[1;1H' $argv
end
