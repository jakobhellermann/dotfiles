if type -q bat
    function cat --wraps=bat --description 'alias cat bat'
        bat -p $argv
    end
end
