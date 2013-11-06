#!/usr/bin/env bash

#
#
#

function image_info()
{
    dumpe2fs -h test.img
}

function create_random()
{
    dd if=/dev/urandom bs=1M count=1 >| $1 2>/dev/null
}

function fsck()
{
    e2fsck -vvvv -f $1
}

# create
fallocate -l $((1024 * 1024 * 512)) test.img
mke2fs -F -t ext4 test.img
fsck test.img

# mount
mkdir -p mnt
mount -o loop -t ext4 test.img mnt

# fill it, with holes
for i in {1..30}; do
    create_random mnt/${i}.test
done
for i in {1..30}; do
    if [ $((i % 2)) -eq 0 ]; then
        rm mnt/${i}.test
    fi
done
for i in {1..30}; do
    create_random mnt/${i}.test
done

sync
image_info test.img
umount mnt

min_size_4k=$(resize2fs -P test.img 2>/dev/null | awk '{print $NF}')
fsck test.img
resize2fs -M test.img
fsck test.img

# copy and check
dd if=test.img of=test_dup.img bs=4k count=$min_size_4k oflag=direct
sync
image_info test_dup.img
fsck test_dup.img

