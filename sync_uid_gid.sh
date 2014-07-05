#!/usr/bin/env bash

orig_uids=$1
orig_gids=$2

uids_to_sync=$3
gids_to_sync=$4

for u in $uids_to_sync; do
    o=$(grep "^${u}:" $orig_uids | cut -d: -f3)
    usermod -u $o $u
done

for g in $gids_to_sync; do
    o=$(grep "^${g}:" $orig_gids | cut -d: -f3)
    groupmod -g $o $g
done
