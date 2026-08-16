function pw-alpha -d "generate an alphanumeric password (default length 43)"
    set -l length 43
    if test (count $argv) -gt 0
        set length $argv[1]
    end
    # ~1.6x as many bytes as needed -> plenty of entropy after filtering
    set -l bytes (math "ceil($length * 5 / 4) + 8")
    openssl rand -base64 $bytes \
        | tr -d '+/=' \
        | tr -cd '[:alnum:]' \
        | head -c $length
    echo
end
