function jlo --wraps='jj log -r ::@ --no-graph' --description 'alias jlo jj log -r ::@ --no-graph'
    jj log -r ::@ --no-graph $argv
end
