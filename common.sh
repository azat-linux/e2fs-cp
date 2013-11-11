

start_port=255
bs=16k
reserve=1000


function get_min_block_size_kb()
{
    # We must avoid mount()
    # since after this we can't resize2fs because
    # resize/main.c: "fs->super->s_lastcheck < fs->super->s_mtime"
    # (because other previous checks is passed)
    mount $1
    kb_size=$(df -BK $1 | tail -n1 | awk '{print $3}' | tr -d K)
    umount $1

    reserved_kb_size=$(( kb_size + (1024 * 1024 * 10) )) # 10 GiB
    echo $reserved_kb_size
}

function get_image_size_in_bs()
{
    local dumpfs=$(dumpe2fs -h $1 | awk -F: '{if ($1 == "Block size") bs=$NF; if ($1 == "Block count") count=$NF;} END {print bs count}')
    local fs_bs_k=$(echo $dumpfs | awk '{print $1/1024}')
    local fs_count=$(echo $dumpfs | awk '{print $2}')

    # TODO: handle mg/gb and other stuff
    local bs_k=${bs/k/}

    echo $(( (fs_count / (bs_k / fs_bs_k)) + reserve ))
}

function get_uuid()
{
    # TODO: or accept mount points instead of block devices
    fstab_line=$(grep ext4 /etc/fstab | egrep -v ' (/usr|/|/home|/var|) ' | tail -n+$1 | head -n1)

    echo "$fstab_line" | cut -d' ' -f1 | cut -d= -f2
}
