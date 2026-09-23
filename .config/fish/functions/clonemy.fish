function clonemy -a repo --description 'clone my github repo'
    if test -z "$repo"
        echo "usage: clonemy <repo>" >&2
        return 1
    end

    # if the repo is a fork, clone its upstream and fork it locally
    # .parent is null when the repo is not a fork; select(.) drops that case
    # (jq's null + "/" + null would otherwise produce "/")
    set --local parent (gh repo view "jakobhellermann/$repo" --json parent --jq '.parent | select(.) | .owner.login + "/" + .name' 2>/dev/null)

    if test -n "$parent"
        if test -d "$repo"
            echo "$repo already exists, running jj fork"
        else
            echo "cloning upstream $parent (it's a fork)"
            jj git clone --colocate git@github.com:$parent
            # clone dir is named after the upstream repo, rename to $repo
            set --local dir (string split / $parent)[-1]
            if test "$dir" != "$repo"
                mv $dir $repo
            end
        end
        cd $repo; or return 1
        jj fork
    else
        if test -d "$repo"
            echo "$repo already exists" >&2
            return 1
        end
        jj git clone --colocate git@github.com:jakobhellermann/$repo
    end
end

complete -c clonemy --no-files -a '(memini gh repo list --limit 1000 --json name -q ".[].name" 2>/dev/null)'
