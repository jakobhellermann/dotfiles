function lnswap --description "Swap a symlink with its target"
    if test (count $argv) -ne 1
        echo "Usage: lnswap <symlink>"
        return 1
    end

    # Strip trailing slash from argument so test -L doesn't follow the link
    set link (string trim --right --chars=/ -- $argv[1])

    if not test -L $link
        echo "Error: $link is not a symlink"
        return 1
    end

    # Absolute path of the symlink itself.
    # Use realpath instead of `cd`, because fish command substitution shares
    # the shell's cwd — `(cd … ; and pwd)` would leak and break later commands.
    set link_dir (realpath -- (dirname $link))
    set link_base (basename $link)
    set link_abs "$link_dir/$link_base"

    # Resolve the symlink target. readlink returns the literal target (may be
    # relative and may carry a trailing slash from the original ln invocation).
    set target_raw (readlink $link)
    set target_raw (string trim --right --chars=/ -- $target_raw)
    if string match -qr '^/' -- $target_raw
        set target_abs $target_raw
    else
        set target_abs (realpath -m -- "$link_dir/$target_raw")
    end

    if not test -e $target_abs
        echo "Error: target $target_abs does not exist"
        return 1
    end

    set temp_name "$link_abs.lnswap.tmp"

    mv $link_abs $temp_name
    or return 1

    if not mv $target_abs $link_abs
        mv $temp_name $link_abs
        return 1
    end

    if not ln -s $link_abs $target_abs
        mv $link_abs $target_abs
        mv $temp_name $link_abs
        return 1
    end

    rm $temp_name

    echo "Swapped: $target_abs -> $link_abs"
end
