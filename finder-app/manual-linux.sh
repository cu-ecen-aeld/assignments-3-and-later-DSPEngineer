#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.
# Updated by: Jose Pagan, 06 June 2024, 12 May 2024

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
MY_CURRENT_DIR=`pwd`

# Install required lunux packages for building
  REQUIRED_PACKAGES="git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison tree"
  echo "--> Installing build packages: ${REQUIRED_PACKAGES}"
  sudo apt-get install $REQUIRED_PACKAGES

make-exec() {
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} "$@"
}

FORCE_BUILD_KERNEL=   # default: do NOT force (re-)building
FORCE_BUILD_BUSYBOX=  # default: do NOT force (re-)building
FORCE_MAKE_ROOTFS=    # default: do NOT force (re-)making

print_content() {
    # prefer to use the 'tree' util, but Ubuntu doesn't have it "out of the box",
    # so I have added it to the install apps above.

    tree "$@"
    if [  $? != 0 ]; then
        ## Use 'ls' in the event tree fails
        ls -lah "$@"
    fi
} 

echo **** $#
if [ $# -lt 1 ]
then
	echo "---- Using default directory [${OUTDIR}] for output"
else
	OUTDIR=$1
	echo "---- Using specified directory [${OUTDIR}] for output"
fi

mkdir -p ${OUTDIR}
echo "*** mkdir -p ${OUTDIR}"

cd "$OUTDIR"
## 1- grab the required linux kernel sources
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    # Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi

if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    # TODO: Add your kernel build steps here

    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # Building 5.1.10 kernel with recent GCC version (10 and later) fails with the following link time error:
    # (.text+0x0): multiple definition of `yylloc'; dtc-lexer.lex.o (symbol from plugin):(.text+0x0): first defined here
    # The following pathch fixes this
    # https://github.com/torvalds/linux/commit/e33a814e772cdc36436c8c188d8c42d019fda639
    ${FINDER_APP_DIR}/apply-git-patch.sh "${FINDER_APP_DIR}/scripts-dtc-Remove-redundant-YYLOC-global-declaratio.patch"

    # Source (page 15):
    # https://d3c33hcgiwev3.cloudfront.net/JNln4MtVSR-ZZ-DLVQkfYw_833bf61ded3942709a8745e579b1a0f1_Building-the-Linux-Kernel.pdf?Expires=1704412800&Signature=kViP~WLZtQm9l0Tq25DkDSiqJw8Vtpjwnu8FvadETfWEMkBfJCgshDnNV9WV8VweGsScGWutyv-jmYjgOAnWlJFRRtDWb7yvMTWnyRwC~9Dr7eEUEszU1oHedd2Zh3ijtUOyWJiisAgecT0t40yjUpZb5bOnpxmpwHFl~wjER3I_&Key-Pair-Id=APKAJLTNE6QMUY6HBC5A

    # TODO: Add your kernel build steps here
    #make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make-exec mrproper

    ## 3a - copy existing linux config file
    #echo "--> Copying stored configuration: ${MY_CURRENT_DIR}/myLinuxConfig"
    #cp ${MY_CURRENT_DIR}/myLinuxConfig .config
    ## 3b - make the defult configuration
    echo "--> Creating the default configuration: defconfig from ${MY_CURRENT_DIR}/myLinuxConfig"
    #make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make-exec defconfig

    ## 4 - make the defult configuration
    echo "--> Building the kernel ..."
    #make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    make-exec -j4 all

    ##make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    #make-exec modules
    ##make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
    ##make-exec dtbs
fi

cd "$OUTDIR"
echo "Adding the Image in outdir"
cp linux-stable/arch/${ARCH}/boot/Image .
ls -lah ./Image

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
_ROOTFS=${OUTDIR}/rootfs
if [ ! -d "${_ROOTFS}" ]
then
    echo "Creating rootfs directory at ${_ROOTFS}"
elif [ ! -z "${FORCE_MAKE_ROOTFS}" ]
then
    echo "Deleting rootfs directory at ${_ROOTFS} and starting over"
    sudo rm -rf ${_ROOTFS}
else
    echo "Re-using existing rootfs at ${_ROOTFS}"
fi

if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
# Create rootfs directory and folder tree
sudo mkdir -p ${OUTDIR}/rootfs
cd "${OUTDIR}/rootfs"
_BUSYBOX_DIRS="bin dev etc home lib lib64 proc sbin sys tmp usr usr/bin usr/lib usr/sbin var/log"
for _DIR in $_BUSYBOX_DIRS
do
    sudo mkdir -p $_DIR
done
sudo chmod -R 777 ${OUTDIR}/rootfs

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    sudo chmod -R 755 ${OUTDIR}/busybox
else
    cd busybox
fi

# TODO: Make and install busybox
sudo make distclean
sudo make defconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CROSS_COMPILE="$CROSS_COMPILE" CONFIG_PREFIX="${OUTDIR}/rootfs" install
cd ${OUTDIR}/rootfs

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
SYSROOT=$(aarch64-none-linux-gnu-gcc -print-sysroot)
dep1=$(find $SYSROOT -name "libm.so.6")
dep2=$(find $SYSROOT -name "libresolv.so.2")
dep3=$(find $SYSROOT -name "libc.so.6")
dep4=$(find $SYSROOT -name "ld-linux-aarch64.so.1")

cp ${dep1} ${dep2} ${dep3} ${OUTDIR}/rootfs/lib64
cp ${dep4} ${OUTDIR}/rootfs/lib

# TODO: Make device nodes
echo "Make Device nodes"
cd "${OUTDIR}/rootfs"
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 5 1

# TODO: Clean and build the writer utility
echo "Clean and build the writer utility"
echo ${FINDER_APP_DIR}
cd ${FINDER_APP_DIR}
sudo chmod 777 ${FINDER_APP_DIR}
sudo make clean
make CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
echo " Copy the finder related scripts and executables"
sudo cp ${FINDER_APP_DIR}/finder.sh ${FINDER_APP_DIR}/finder-test.sh ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home
sudo mkdir -p ${OUTDIR}/rootfs/home/conf
sudo cp ${FINDER_APP_DIR}/conf/*.txt ${OUTDIR}/rootfs/home/conf

# TODO: Chown the root directory
cd ${OUTDIR}/rootfs
sudo chown -R root:root *

# TODO: Create initramfs.cpio.gz
cd "${OUTDIR}/rootfs"
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio

sudo cp ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home