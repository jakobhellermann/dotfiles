function sclone -a repo --description 'clone sipgate github repo'
    jj git clone --colocate git@github.com:sipgate/$repo
    cd $repo
    jj config set user.email 'hellermann@sipgate.de' --repo 2>/dev/null
    jj describe --reset-author --no-edit 2>/dev/null
end

complete -c sclone --no-files -a '(memini gh repo list sipgate --limit 1000 --json name -q ".[].name" 2>/dev/null)'
