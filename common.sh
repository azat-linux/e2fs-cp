

start_port=255
bs=16k
parallel_max=12


function get_min_fs_size_in_kb()
{
    local dumpfs=$(dumpe2fs -h $1 2>/dev/null | \
                   awk -F: '{\
                       if ($1 == "Block size") bs=$NF; \
                       if ($1 == "Block count") count=$NF; \
                       if ($1 == "Free blocks") free=$NF; \
                   } END {printf "%.f %.f", bs+0, count-free}')
    local fs_bs_k=$(echo $dumpfs | awk '{print $1/1024}')
    local fs_used=$(echo $dumpfs | awk '{print $2}')

    echo $(( fs_used * fs_bs_k ))
}

function get_max_fs_size_in_kb()
{
    local bytes=$(fdisk -l $1 2>/dev/null | \
                  grep '^Disk '$1 | \
                  awk '{print $(NF-1)}')
    echo $(( bytes / 1024 ))
}

function get_fs_size_in_kb()
{
    local dumpfs=$(dumpe2fs -h $1 2>/dev/null | \
                   awk -F: '{\
                       if ($1 == "Block size") bs=$NF; \
                       if ($1 == "Block count") count=$NF; \
                   } END {printf "%.f %.f", bs, count}')
    local fs_bs_k=$(echo $dumpfs | awk '{print $1/1024}')
    local fs_count=$(echo $dumpfs | awk '{print $2}')

    echo $(( fs_count * fs_bs_k ))
}

# $1 - index
function get_uuid()
{
    local type=$1
    local i=$2
    # TODO: or accept mount points instead of block devices
    fstab_line=$(grep $type /etc/fstab | \
                 grep -v ^# | \
                 egrep -v "[	 ]($(df | tail -n+2 | awk '{printf "%s|", $NF}' | sed 's/|$//'))[	 ]" | \
                 tail -n+$i | \
                 head -n1)

    echo "$fstab_line" | awk -F'[= \t]' '{print $2}'
}

# TODO: resolve UUID's
function mounted()
{
    grep -q "^$1 " /proc/mounts
}

# mounted read-only/ro
function read_only()
{
    egrep -q "^$1 .*[, ]ro[, ]" /proc/mounts
}

function get_fstype()
{
    blkid $@ | cut -d'"' -f4
}
