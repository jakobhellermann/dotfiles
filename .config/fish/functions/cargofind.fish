function cargofind --wraps='cargo tree -i' --description 'alias cargofind cargo tree -i'
    cargo tree -i $argv
end
