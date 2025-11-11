function ddrmcontainers --wraps='docker ps -aq | xargs sudo docker rm' --description 'alias ddrmcontainers=docker ps -aq | xargs sudo docker rm'
    docker ps -aq | xargs sudo docker rm $argv

end
