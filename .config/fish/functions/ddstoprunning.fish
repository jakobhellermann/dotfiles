function ddstoprunning --wraps='docker ps -q | xargs docker stop' --description 'alias ddstoprunning=docker ps -q | xargs docker stop'
    docker ps -q | xargs docker stop $argv
end
