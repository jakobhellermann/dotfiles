function viewdeps --wraps='cargo depgraph | dot -Tsvg -o out.svg && firefox out.svg' --description 'alias viewdeps cargo depgraph | dot -Tsvg -o out.svg && firefox out.svg'
    set path (mktemp --suffix .deps.svg)
    cargo depgraph $argv | dot -Tsvg -o $path && firefox $path
end
