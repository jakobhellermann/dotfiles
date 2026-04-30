function watchdocs --description 'Continually build rustdoc'
    cargo doc --no-deps --open
    cargo watch -x 'doc --no-deps'
end
