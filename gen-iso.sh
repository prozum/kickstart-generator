#!/bin/sh

MIRROR=http://ftp.klid.dk/ftp/centos/7/isos/x86_64/
ISO_NAME=CentOS-7-x86_64-NetInstall-1611
ISO_FILE=$ISO_NAME.iso

MOUNT_DIR=/mnt/iso
WORK_DIR=$PWD
TMP_DIR=$WORK_DIR/tmp
BUILD_DIR=$TMP_DIR/build
KS_DIR=$TMP_DIR/ks
ISOLINUX_DIR=$BUILD_DIR/isolinux/

# Download iso
mkdir -p $TMP_DIR
if [ ! -f "$TMP_DIR/$ISO_FILE" ]; then
    wget $MIRROR/$ISO_FILE -O$TMP_DIR/$ISO_FILE
fi

# Extract iso
sudo mkdir -p $MOUNT_DIR
sudo mount -o loop $TMP_DIR/$ISO_FILE $MOUNT_DIR
rm -rf $BUILD_DIR
mkdir $BUILD_DIR
cp -r $MOUNT_DIR/* $BUILD_DIR
chmod -R u+w $BUILD_DIR
sudo umount $MOUNT_DIR && sudo rmdir $MOUNT_DIR

# Setup kickstart isolinux entries
ISOLINUX_CFG=$ISOLINUX_DIR/isolinux.cfg
cp isolinux/isolinux.cfg.in $ISOLINUX_CFG
cp isolinux/splash.png $ISOLINUX_DIR
for KS in $(ls $KS_DIR)
do
    cp $KS_DIR/$KS $ISOLINUX_DIR
    echo "label check" >> $ISOLINUX_CFG
    echo "  menu label $KS" >> $ISOLINUX_CFG
    echo "  kernel vmlinuz" >> $ISOLINUX_CFG
    echo "  append initrd=initrd.img ks=cdrom:/$KS inst.stage2=hd:LABEL=CentOS\x207\x20x86_64 quiet" >> $ISOLINUX_CFG

done    

# Generate image
pushd $BUILD_DIR > /dev/null 2>&1
mkisofs -R -J -v -T \
 -o $WORK_DIR/boot.iso \
 -b isolinux.bin -c boot.cat \
 -V 'CentOS 7 x86_64' \
 -no-emul-boot -boot-load-size 4 -boot-info-table \
 isolinux/. $BUILD_DIR
popd > /dev/null 2>&1
