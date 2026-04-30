function opendot --description 'View a graphviz dot graph from stdin in firefox'
    set path (mktemp --suffix .deps.svg)
    dot -Tsvg -o $path && firefox $path
end
