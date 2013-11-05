#!/usr/bin/env bash

# TODO: add common consts
start_port=255

set -e
set -x

port=$start_port
for fs in $*; do
    (nc -nlp $port | tee -a >(md5sum >&2) | dd of=$fs oflag=direct iflag=fullblock bs=16k) &
    # TODO: do we need to calc md5sum from $fs
    # TODO: e2fsck of $fs
    let ++port
done

