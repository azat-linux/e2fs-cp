#!/usr/bin/env bash

function copy_scripts()
{
    ssh $1 mkdir -p ~/resize_copy
    scp *.sh $1:~
}

set -e
set -x

dst=$1
src=$2

copy_scripts $src
copy_scripts $dst

ssh $src ~/resize_copy/resize2fs.sh
ssh $dst ~/resize_copy/image_receiver.sh &
ssh $src ~/resize_copy/image_sender.sh

