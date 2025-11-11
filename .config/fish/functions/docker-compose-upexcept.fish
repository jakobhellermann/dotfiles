function docker-compose-upexcept --description 'docker compose up (excluding)'
    docker compose config --services | grep -v $argv | xargs docker compose up -d
end
