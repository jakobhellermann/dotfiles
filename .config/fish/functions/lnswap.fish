function lnswap --description "Swap a symlink with its target"
    if test (count $argv) -ne 1
        echo "Usage: lnswap <symlink>"
        return 1
    end

    set link $argv[1]

    # Check if it's a symlink
    if not test -L $link
        echo "Error: $link is not a symlink"
        return 1
    end

    # Get the target (resolved path)
    set target (readlink $link)

    # Check if target exists
    if not test -e $target
        echo "Error: target $target does not exist"
        return 1
    end

    # Get absolute path of the link's location (without following the symlink)
    set link_dir (cd (dirname $link); and pwd)
    set link_abs "$link_dir/"(basename $link)

    # Use a temporary name to avoid conflicts
    set temp_name "$link.lnswap.tmp"

    # Move the symlink to temp name
    mv $link $temp_name

    # Move target to link's original name
    mv $target $link

    # Create new symlink from old target location pointing to the absolute path
    ln -s $link_abs $target

    # Remove temp
    rm $temp_name

    echo "Swapped: $target -> $link_abs"
end
