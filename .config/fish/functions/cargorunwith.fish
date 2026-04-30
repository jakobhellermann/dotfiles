function cargorunwith --description 'Run cargo with wrapper command'
    set TARGET X86_64_UNKNOWN_LINUX_GNU
    set BIN $argv[1]
    set argv $argv[2..-1]
    env CARGO_TARGET_{$TARGET}_RUNNER=$BIN cargo run $argv
end

complete \
    --command cargorunwith \
    --condition "not __fish_seen_subcommand_from" \
    --arguments "(__fish_complete_command)"

complete \
    --command cargorunwith \
    --condition __fish_seen_subcommand_from \
    --wraps "cargo run"
