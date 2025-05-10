#!/bin/bash

# https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/861569243/Boot+Images

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
    # Create a 4GB SD card image if it doesn't exist
    SD_CARD_IMAGE="${PWD}/sd_card.img"
    echo "Creating SD card image..."
    dd if=/dev/zero of="$SD_CARD_IMAGE" bs=1M count=256
    # create a FAT32 partition
    echo "Creating FAT32 partition..."
    sudo mkfs.vfat "$SD_CARD_IMAGE"
    sudo mount "$SD_CARD_IMAGE" /mnt
    sudo cp -r ./images/linux/Image /mnt
    sudo cp -r ./images/linux/boot.scr /mnt
    sudo cp -r ./images/linux/BOOT.BIN /mnt
    sudo cp -r ./dts/zcu102-root-aarch64.dtb /mnt
    sudo cp -r ./dts/system.dtb /mnt
    sudo umount /mnt

    echo "Starting QEMU..."
    petalinux-boot qemu --prebuilt 2 \
        --qemu-args "-drive file=${SD_CARD_IMAGE},if=none,format=raw,id=sd_drive -device sd-card,drive=sd_drive,id=sd_card"
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
            compile_dts
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

# fatload mmc 0:0 0x40400000 Image;fatload mmc 0:0 0x40000000 system.dtb;booti 0x40400000 - 0x40000000
