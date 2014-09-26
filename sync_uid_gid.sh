#!/usr/bin/env bash

export parentPid=$$

orig_uids=$1
orig_gids=$2

uids_to_sync=$3
gids_to_sync=$4

u_start=${5:-1100}
g_start=${6:-1100}

function match_id()
{
    [[ "$1" =~ [0-9]+ ]] && echo ${BASH_REMATCH[0]}
}
function get_login()
{
    getent $1 $2 | cut -d: -f1
}
function change_uid()
{
    echo "Conflicts for: $1"

    while IFS=$'\n' read line; do
        [[ "$line" =~ "is currently used by process" ]] && echo "$line" && kill $parentPid
        local uid=$(match_id "$line")
        [ -z "$uid" ] && echo "$line" && continue
        local login=$(get_login passwd $uid)

        usermod -u $u_start $login

        echo "Unplanned uid was changed, you porbably wan't to run:"
        echo "find ~${login} -uid $uid -exec chown ${u_start} {} \\;"

        let u_start++
    done
}
function change_gid()
{
    echo "Conficts for: $1"

    while IFS=$'\n' read line; do
        local gid=$(match_id "$line")
        [ -z "$gid" ] && echo "$line" && continue
        local group=$(get_login group $gid)

        groupmod -g $g_start $group

        echo "Unplanned gid was changed, you porbably wan't to run:"
        echo "find / -gid $gid -exec chown :${g_start} {} \\;"

        let g_start++
    done
}

function uids()
{
    for u in $uids_to_sync; do
        echo "Login: $u"
        local o=$(grep "^${u}:" $orig_uids | cut -d: -f3)
        while ! $( usermod -u $o $u 2> >( change_uid $u >&2 ) ); do
            echo "Trying one more time"
        done
        echo "Finish"
    done
}

function gids()
{
    for g in $gids_to_sync; do
        echo "Group: $g"
        local o=$(grep "^${g}:" $orig_gids | cut -d: -f3)
        while ! $(groupmod -g $o $g 2> >( change_gid $g >&2 ) ); do
            echo "Trying one more time"
        done
        echo "Finish"
    done
}

if [ -z "$orig_uids" ] && [ -z "$orig_gids" ]; then
    cat <<"EOL" >&2
Sync uid/gid{s}.
Firstly install desired uid in $orig_uids file, and gid in $orig_gids'
After use the next command: $0 /path/to/uids /path/to/gids users groups"

For example if you want to change foo and bar uid/gid (not tested well):
-----------------------------------------------------------------------
$ diff -u0 passwd.orig passwd
--- passwd.orig 2014-09-26 13:23:45.991658391 +0400
+++ passwd      2014-09-26 13:24:22.203658699 +0400
@@ -28 +28 @@
-foo:x:1000:1001::/home/foo:/bin/bash
+foo:x:1007:1001::/home/foo:/bin/bash
@@ -35 +35 @@
-bar:x:1007:1008::/home/bar:/bin/bash
+bar:x:1000:1008::/home/bar:/bin/bash
s$ diff -u0 group.orig group
--- group.orig  2014-09-26 13:23:50.019658426 +0400
+++ group       2014-09-26 13:24:25.635658728 +0400
@@ -50 +50 @@
-foo:x:1000:foo
+foo:x:1008:foo
@@ -58 +58 @@
-bar:x:1008:bar
+bar:x:1000:bar
-----------------------------------------------------------------------
./sync_uid_gid.sh passwd group 'foo bar' 'foo bar'
EOL
    exit 1
fi
uids
gids
