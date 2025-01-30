# dotfiles

## git

```sh
curl https://raw.githubusercontent.com/jakobhellermann/dotfiles/main/.setup/dotfiles.sh -o dotfiles.sh
chmod +x dotfiles.sh
./dotfiles.sh
```

## jujutsu

```sh
jj git clone git@github.com:jakobhellermann/dotfiles
mv dotfiles/.jj . && rm dotfiles -fr
jj config set --repo snapshot.auto-track 'none()'
```

# os install

```sh
archinstall --config https://raw.githubusercontent.com/jakobhellermann/dotfiles/main/.setup/archinstall.json
```
