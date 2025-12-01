function crateclone --description 'alias cargofind cargo tree -i'
    set url (craterepo $argv[1])
    if test $status != 0
        return $status
    end
    echo "$url"
    jj git clone "$url"
end
