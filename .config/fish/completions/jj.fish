complete --keep-order --exclusive --command jj --arguments "(COMPLETE=fish "'jj'" -- (commandline --current-process --tokenize --cut-at-cursor) (commandline --current-token))"

set -l coauthorsfile (dirname (jj config path --user | head -n1))/coauthors.json
if test -f $coauthorsfile
    jq -r 'to_entries[] | "\(.key)\t\(.value)"' $coauthorsfile | while read -l line
        set -l alias (echo $line | cut -f1)
        set -l desc (echo $line | cut -f2-)
        complete -c jj -n '__fish_seen_subcommand_from team' -a $alias -d "$desc"
    end
end

complete -c jj -n '__fish_seen_subcommand_from team' -a 'disable list'
