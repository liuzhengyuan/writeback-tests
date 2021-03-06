#!/bin/bash
#
# main-loop.sh: repeat tests under various combinations of fs/dd

cd $(dirname $0)

BASE_DIR=$(pwd)

# in my case, it's running from rc.local
export PATH=$BASE_DIR:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

source config.sh
source $(hostname)-config.sh || exit

source fs-common.sh
source dd-common.sh
source trace-common.sh
source cases-common.sh

for loop in $(seq ${LOOPS:-1})
do
for nr_dd in ${DD_TASKS:-1}
do
for fs in ${FILESYSTEMS:-ext4}
do
for scheme in $(test_cases)
do
for kver in "${KERNELS[@]:-""}"
do
for kopt in "${KERNEL_OPTIONS[@]:-""}"
do
	storage=${STORAGE:-HDD}
	devices=$DEVICES
	[[ $fs =~ nfs ]] && devices=$NFS_DEVICE
	RAID_LEVEL=jbod

	[[ $nr_dd =~ : ]] && {
		dd_opt=$(echo $nr_dd | cut -f2- -d:)
		nr_dd=$(echo $nr_dd | cut -f1 -d:)
	}

	cd $BASE_DIR

	if [[ $scheme =~ ^fio_ && -f $scheme ]]; then
		fio_job $scheme
	else
		$scheme
	fi
done
done
done
done
done
done

reboot_kexec
