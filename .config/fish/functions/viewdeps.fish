function viewdeps --wraps='cargo depgraph | dot -Tsvg -o out.svg && firefox out.svg' --description 'alias viewdeps cargo depgraph | dot -Tsvg -o out.svg && firefox out.svg'
    cargo depgraph | dot -Tsvg -o out.svg && firefox out.svg $argv

end
