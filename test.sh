#!/usr/bin/env bash

#
#
#

function image_info()
{
    df -B4K test.img
    df -i test.img
    dumpe2fs -h test.img
}

function create_random()
{
    dd if=/dev/urandom bs=1M count=1 >| $1 2>/dev/null
}

# create
fallocate -l $((1024 * 1024 * 512)) test.img
mke2fs -F -t ext4 test.img
e2fsck test.img

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
e2fsck -vvvv -f test.img
resize2fs -M test.img
e2fsck -vvvv -f test.img

# copy and check
dd if=test.img of=test_dup.img bs=4k count=$min_size_4k oflag=direct
sync
image_info test_dup.img
e2fsck -vvvv -f test_dup.img

