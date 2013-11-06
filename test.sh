#!/usr/bin/env bash

#
# If copying using simple dd, after resize2fs using shrinked size,
# fsck report errors, this script for investigating it
#

set -e

a=${1:-"test.img"}
b=${2:-"test_dup.img"}
create_delete_iterations=${3:-30}

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
    if is_block_device $1; then
        mount -t ext4 $1 mnt
    else
        mount -o loop -t ext4 $1 mnt
    fi
}

function fill_image()
{
    if ! is_block_device $1; then
        fallocate -l $((1024 * 1024 * 512)) $1
    fi
}

function calc_md5sum()
{
    if ! is_block_device $1; then
        md5sum $1
    fi
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

# copy and check
dd if=$a of=$b bs=4k count=$min_size_4k oflag=direct
sync
image_info $b
calc_md5sum $a
calc_md5sum $b
fsck $b

