set -l bookmark_aliases tug-2 tug-1 tug1 tug2 tug3 unconflict-bookmark-git unconflict-bookmark-origin gitmerge

# Default completions, but skip aliases we handle manually below.
complete --keep-order --exclusive --command jj \
    --condition "not __fish_seen_subcommand_from $bookmark_aliases" \
    --arguments "(COMPLETE=fish "'jj'" -- (commandline --current-process --tokenize --cut-at-cursor) (commandline --current-token))"

# Custom alias completions: util exec aliases that take a bookmark name as $1.
# Delegates to `jj bookmark delete` completion so we get bookmark names (plus
# global flags); use the commented-out template line for names only.
for alias in $bookmark_aliases
    complete -c jj --condition "__fish_seen_subcommand_from $alias" --no-files \
        -a '(complete -C "jj bookmark delete ")'
end

set -l coauthorsfile (dirname (jj config path --user | head -n1))/coauthors.json
if test -f $coauthorsfile
    jq -r 'to_entries[] | "\(.key)\t\(.value)"' $coauthorsfile | while read -l line
        set -l alias (echo $line | cut -f1)
        set -l desc (echo $line | cut -f2-)
        complete -c jj -n '__fish_seen_subcommand_from team' -a $alias -d "$desc"
    end
end

complete -c jj -n '__fish_seen_subcommand_from team' -a 'disable list'
