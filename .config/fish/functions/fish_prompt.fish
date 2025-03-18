function fish_prompt
    set color (test $status -gt 0 && echo red || echo blue)
    set pwd (realpath --relative-base ~ (pwd) \
 		  | string replace -r '^.$' '~' \
 		  | string split '/' | tail -n 3 | string join '/')
    echo -n (set_color cyan) $pwd (set_color $color)'λ' (set_color normal)
end
