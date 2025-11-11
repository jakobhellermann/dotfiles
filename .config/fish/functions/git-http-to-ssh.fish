function git-http-to-ssh -a url
    echo "$url" | sed 's|https://|git@|' | sed 's|/|:|'
end
