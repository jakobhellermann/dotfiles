function craterepo --description 'alias cargofind cargo tree -i'
    curl -s "https://crates.io/api/v1/crates/$argv[1]" | jq .crate.repository -r
end
