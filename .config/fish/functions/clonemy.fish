function clonemy -a repo --description 'clone my github repo'
    jj git clone --colocate git@github.com:jakobhellermann/$repo
end

function __foo
    gh repo list --json name -q '.[].name'
end

complete -c clonemy --no-files -a '(memini gh repo list --limit 1000 --json name -q ".[].name" 2>/dev/null)'
