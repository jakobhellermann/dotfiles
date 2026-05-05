function nadd --description 'nix profile add nixpkgs#<pkg>'
    nix profile add nixpkgs#$argv[1] $argv[2..]
end
