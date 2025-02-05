abbr --add jl 'jj git fetch --all-remotes'
abbr --add jp 'jj git push'
abbr --add jdr 'jj interdiff --from (jj_current_bookmark)@origin'

function last_history_item
    echo $history[1]
end
abbr -a !! --position anywhere --function last_history_item
