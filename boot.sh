#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SD_CARD_IMAGE="${SCRIPT_DIR}/disks/test_ubuntu.ext4"

compile_dts() {
    # at ./dts
    for file in ./dts/*.dts; do
        echo "Compiling $file..."
        dtc -I dts -O dtb -o ${file%.dts}.dtb $file
    done
}

show_usage() {
    echo "Usage: $0 [OPTION]"
    echo "Options:"
    echo "  -b, --build    Build the PetaLinux project"
    echo "  -B, --boot     Boot the system using QEMU"
    echo "  -h, --help     Show this help message"
    echo "  -c, --compile-dts    Compile the DTS files"
    exit 1
}

build_project() {
    echo "Building PetaLinux project..."
    petalinux-build
    if [ $? -ne 0 ]; then
        echo "Build failed!"
        exit 1
    fi
    echo "Build completed successfully!"
}

boot_qemu() {
    if [ ! -f "$SD_CARD_IMAGE" ]; then
        echo "Error: SD card image not found at $SD_CARD_IMAGE"
        exit 1
    fi

    echo "Starting QEMU..."
    petalinux-boot qemu \
        --qemu-args "-drive file=${SD_CARD_IMAGE},if=sd,format=raw \
        -net nic -net user -nographic -serial /dev/null -monitor none"
}

if [ $# -eq 0 ]; then
    show_usage
fi

while [ "$1" != "" ]; do
    case $1 in
        -b | --build )
            build_project
            ;;
        -B | --boot )
            boot_qemu
            ;;
        -h | --help )
            show_usage
            ;;
        -c | --compile-dts )
            compile_dts
            ;;
        * )
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
    shift
done 

# copy to SD card's FAT32 partition
# dts/zcu102-root-aarch64.dtb
# images/linux/Image
# images/linux/boot.scr
# images/linux/BOOT.BIN

# fatload mmc 0:1 0x40400000 Image;
# fatload mmc 0:1 0x40000000 zcu102-root-aarch64.dtb
#bootm 0x40400000 - 0x40000000
