function tmp --argument name --description 'enter a new temporary directory'
    pushd (mktemp -d /tmp/$name.XXXX)
end
