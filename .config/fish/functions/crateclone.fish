function crateclone --description 'alias cargofind cargo tree -i'
    jj git clone --colocate (craterepo $argv[1])
end
