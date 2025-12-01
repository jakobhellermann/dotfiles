function jj_current_bookmark
    jj bookmark list -r '@-' --tracked -T 'if(!remote, name ++ "\n")'
end
