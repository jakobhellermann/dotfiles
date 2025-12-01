function craterepo --description 'alias cargofind cargo tree -i'
    set response (curl -s "https://crates.io/api/v1/crates/$argv[1]")
    set errors (echo "$response" | jq '.errors[]?.detail' -r)
    set repo (echo "$response" | jq .crate.repository -r)

    if test "$errors" != ""
        echo "$errors" >&2
        return 1
    else
        echo "$repo"
    end
end
