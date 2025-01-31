function curljq --wraps='curl -s' --description 'alias curljq curl -s'
    curl -s $argv | jq
end
