function ddstoprunning --wraps='docker ps -q | xargs sudo docker stop' --description 'alias ddstoprunning=docker ps -q | xargs sudo docker stop'
    docker ps -q | xargs sudo docker stop $argv
end
