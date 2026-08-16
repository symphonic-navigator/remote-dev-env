function pw-hex -d "generate a hexadecimal password (default length 32)"
    set -l length 32
    if test (count $argv) -gt 0
        set length $argv[1]
    end
    set -l bytes (math "ceil($length / 2)")
    openssl rand -hex $bytes
    echo
end
