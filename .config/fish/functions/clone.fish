function clone -a url --description 'clone repo by url'
    set url (echo "$url" | cut -f 1-5 -d '/')
    echo "$url"
    jj git clone (git-http-to-ssh "$url")
end
