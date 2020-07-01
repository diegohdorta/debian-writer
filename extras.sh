
function debian-help() {
cat << _EOF_
    Unix tool for generating Debian images for i.MX8 boards.     

_EOF_
}

main() {
    echo "Debian Writer -- Tool for Generating Images for i.MX8 Boards (Version 1.0.0)"
    if [ "$EUID" -ne 0 ]
      then echo "Please run as root"
      exit
    fi

    echo $1

    if [ "$#" -eq 0 ]; then
        debian-help
        exit
    fi

    if [ "$1" == "--run" ]; then
        run
        #> /dev/null 2>&1
        echo "Done."
        exit
    fi
    
    if [ -n "$1" ]; then
        echo "Debian Writer: Invalid argument. Try 'debian-writer --help' for more info." >&2
        exit 1
    fi

}

build_kernel() {
    cd $HOME
    git clone https://source.codeaurora.org/external/imx/linux-imx/
    cd $HOME/linux-imx/
    apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
    export ARCH=arm64
    export CROSS_COMPILE=/usr/bin/aarch64-linux-gnu-
    make imx_v8_defconfig
    make -j$(nproc)
    
    mount /dev/loop0p1 /mnt
    cp arch/arm64/boot/Image /mnt && sync
    cp arch/arm64/boot/dts/freescale/imx8qm*.dtb /mnt && sync
    umount /mnt
}

build_kernel_modules() {
    mkdir $HOME/foo
    cd linux-imx/
    make modules_install firmware_install INSTALL_MOD_PATH=$HOME/foo
    rsync -avHP $HOME/foo/lib/ /mnt

}



#img=$(date +'%m_%d_%Y_disk.img')



#DARKGRAY='\033[1;30m'
#RED='\033[0;31m'
#LIGHTRED='\033[1;31m'
#GREEN='\033[0;32m'
#YELLOW='\033[1;33m'
#BLUE='\033[0;34m'
#PURPLE='\033[0;35m'
#LIGHTPURPLE='\033[1;35m'
#CYAN='\033[0;36m'
#WHITE='\033[1;37m'
#DEFAULT='\033[0m'

#COLORS=($DARKGRAY $RED $LIGHTRED $GREEN $YELLOW $BLUE $PURPLE $LIGHTPURPLE $CYAN $WHITE )

#for c in "${COLORS[@]}";do
#    printf "\r $c LOVE $DEFAULT "
#    sleep 1
#done
