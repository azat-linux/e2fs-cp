

start_port=255
bs=16k


function get_min_fs_size_in_kb()
{
    local dumpfs=$(dumpe2fs -h $1 | \
                   awk -F: '{\
                       if ($1 == "Block size") bs=$NF; \
                       if ($1 == "Block count") count=$NF; \
                       if ($1 == "Free blocks") free=$NF; \
                   } END {print bs count-free}')
    local fs_bs_k=$(echo $dumpfs | awk '{print $1/1024}')
    local fs_used=$(echo $dumpfs | awk '{print $2}')

    echo $(( fs_used * fs_bs_k ))
}

function get_fs_size_in_kb()
{
    local dumpfs=$(dumpe2fs -h $1 | \
                   awk -F: '{\
                       if ($1 == "Block size") bs=$NF; \
                       if ($1 == "Block count") count=$NF; \
                   } END {print bs count}')
    local fs_bs_k=$(echo $dumpfs | awk '{print $1/1024}')
    local fs_count=$(echo $dumpfs | awk '{print $2}')

    echo $(( fs_count * fs_bs_k ))
}

# $1 - index
function get_uuid()
{
    # TODO: or accept mount points instead of block devices
    fstab_line=$(grep ext4 /etc/fstab | egrep -v ' (/usr|/|/home|/var|) ' | tail -n+$1 | head -n1)

    echo "$fstab_line" | cut -d' ' -f1 | cut -d= -f2
}
