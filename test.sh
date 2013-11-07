#!/usr/bin/env bash

#
# If copying using simple dd, after resize2fs using shrinked size,
# fsck report errors, this script for investigating it
#

set -e

a=${1:-"test.img"}
b=${2:-"test_dup.img"}
size=${3:-$((1024 * 1024 * 512))} # 512 MiB
create_delete_iterations=${4:-30}

# system configuration
uname -a

function image_info()
{
    dumpe2fs -h $a
}

function create_random()
{
    dd if=/dev/urandom bs=1M count=1 >| $1 2>/dev/null
}

function fsck()
{
    e2fsck -vvvv -f $1
}

function is_block_device()
{
    return $(file $1 2>/dev/null | grep -q "sticky block special")
}

function mnt()
{
    img=$1
    shift

    mnt_opts="$*"


    if is_block_device $img; then
        if [ ! -z "$mnt_opts" ]; then
            mnt_opts="-o $mnt_opts"
        fi

        mount -t ext4 $img mnt
    else
        if [ ! -z "$mnt_opts" ]; then
            mnt_opts=",$mnt_opts"
        fi

        mount -o loop$mnt_opts -t ext4 $img mnt
    fi
}

function fill_image()
{
    if ! is_block_device $1; then
        fallocate -l $size $1
    fi
}

function calc_md5sum()
{
    if ! is_block_device $1; then
        md5sum $1
    fi
}

# do an acitivity, in parallel, while copying is in progress
function read_activity()
{
    img=$1
    mnt=$2

    dd if=$img of=/dev/null
    dd if=$img of=/dev/null bs=1K

    for i in {1..5}; do
        find $mnt -type f | xargs cat > /dev/null
    done
}

# create
fill_image $a
mke2fs -F -t ext4 $a
fsck $a

# mount
mkdir -p mnt
mnt $a

# fill it, with holes
for i in $(seq 1 $create_delete_iterations); do
    create_random mnt/${i}.test
done
# create holes
for i in $(seq 1 $create_delete_iterations); do
    if [ $((i % 2)) -eq 0 ]; then
        rm mnt/${i}.test
    fi
done
for i in $(seq 1 $create_delete_iterations); do
    create_random mnt/${i}.test
done

sync
image_info $a
umount mnt

min_size_4k=$(resize2fs -P $a 2>/dev/null | awk '{print $NF}')
fsck $a
resize2fs $a $min_size_4k
fsck $a

mnt $a ro
read_activity $a mnt &

# copy and check
nc -nlp 2048 | tee >(md5sum >&2) | dd of=$b oflag=direct iflag=fullblock & # receiver
sleep 1
dd if=$a bs=4k count=$min_size_4k | tee >(md5sum >&2) | nc -q1 localhost 2048 # sender

sync
image_info $b
calc_md5sum $a
calc_md5sum $b
fsck $b

