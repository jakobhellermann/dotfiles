function fish_prompt
    set pwd (realpath --relative-base ~ (pwd) \
		  | string replace -r '^.$' '~' \
		  | string split '/' | tail -n 3 | string join '/')
    echo (set_color cyan) $pwd (set_color blue)'λ' (set_color normal)
end
