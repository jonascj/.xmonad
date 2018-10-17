#!/bin/sh

xm="xmonad-x86_64-linux"
xmp=~/.xmonad
script=$(basename $0)

### Function
restore_symlinks ()
{
    mv $mycolors.bak $mycolors
    mv $xmp/$xm.bak $xmp/$xm
}


### Function
backup_symlinks ()
{
    mv $mycolors $mycolors.bak
    mv $xmp/$xm $xmp/$xm.bak
}


### Function
compile ()
{
    color=$1
    # Link colors file
    ln -sfT $mycolors-$color $mycolors
    
    # Try to recompile
    xmonad --recompile

    # On error log, restore, and exit
    if [ $? != 0 ]; then
        logger "$script: recompiling $color xmonad failed, exiting."
        restore_symlinks
        exit 1
    fi
    
    # On successful compilation append  -$color to name
    mv $xmp/$xm $xmp/$xm-$color
    
    logger "$script: succesfully compiled $color xmonad."
}



### Exit if 'xmonad-x86_64-linux' is not a symlink
if [ ! -h "$xmp/$xm" ]; then
    logger "$script: '$xmp/$xm' is not a symlink, exiting."
    exit 1
fi

### Exit if 'lib/MyColors.hs' is not a symlink
mycolors=$xmp/lib/MyColors.hs
if [ ! -h "$mycolors" ]; then
    logger "$script: '$mycolors' is not a symlink, exiting."
    exit 1
fi

### Backup symlinks now we know they exist
backup_symlinks


### Compile 
compile dark
compile light

### Restore symlinks
restore_symlinks


