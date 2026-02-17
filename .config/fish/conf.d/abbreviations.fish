abbr --add grhh 'git reset --hard'

abbr --add jl 'jj git fetch'
abbr --add jp 'jj git push'
abbr --add ju jjui
abbr --add jdr 'jj interdiff --from (jj_current_bookmark)@origin'

abbr --add wo 'cd (jj workspace-path)'

abbr --add dcup 'docker compose up -d'
abbr --add dcd 'docker compose down'
abbr --add dcs 'docker compose ps'

function last_history_item
    echo $history[1]
end
abbr -a !! --position anywhere --function last_history_item
