function pbxdevtools
    function open
        echo $argv[1]
        firefox https://neopbx-devtools.nautilus-tooling01.live.ix01.sipgate.net/calls/$argv[1]
    end

    if count $argv >/dev/null
        for arg in $argv
            open "$arg"
        end
    else
        while read line
            open "$line"
        end
    end
end
