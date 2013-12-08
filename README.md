
Use `resize2fs`/`nc`/`dd` to copy the whole ext(2,3?)4 fs/partition.
(**NOT FOR PRODUCTION!**)

It will useful in case you have many small files on fs.
If you just use `tar`/`rsync`/`ssh` for copying you never won't get 100 MB/s
in case when you have many small files on it.
However this set of scripts, first shrink fs to minimal size (for this time fs
must be unmounted), after copy it using `dd` (for SATA drivers ~100 MB/s),
and finally enlarge it to maximum size on destination machine.

It use md5sum on sender/src and receiver/dst to show some errors
if dd will fail because of some network error.
This won't slow down copying, because md5sum is 300-400 MB/s.

See example at `resize_copy.sh`, for more information.

TODO
====

- getopt
- mount/unmount
- waitpid

