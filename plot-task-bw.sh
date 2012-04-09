#!/bin/bash

plot() {
suffix=$1
gnuplot <<EOF
set xlabel "time (s)"

set size 1
set terminal pngcairo size ${width:-1280}, 800
set terminal pngcairo size ${width:-1000}, 600
set terminal pngcairo size ${width:-1280}, ${height:-800}

set grid

set output "balance_dirty_pages-task-bw$suffix.png"
set ylabel "dirtied (MB)"
plot "task-bw-${dd[0]}$suffix" using 1:(\$3/1048576) with steps lw 2.0 lc rgbcolor "red"      title "task ${dd[0]}", \
     "task-bw-${dd[1]}$suffix" using 1:(\$3/1048576) with steps lw 1.9 lc rgbcolor "gold"     title "task ${dd[1]}", \
     "task-bw-${dd[2]}$suffix" using 1:(\$3/1048576) with steps lw 1.8 lc rgbcolor "web-blue" title "task ${dd[2]}"
EOF
}

for dir
do
cd $dir

[ -s pid ] || {
bzcat trace.bz2 | grep -F task_io | awk '/(dd|cp|tar|fio)-[0-9]+/{print $1}'| sed 's/[^0-9]//g' | head -n3000 | sort | uniq > dd-pid
}

declare -a dd
dd=($(cat pid dd-pid 2>/dev/null))


[[ ${#dd[*]} -lt 1 ]] && { cd ..; continue; }

#               dd-3876  [014]   151.167682: balance_dirty_pages: bdi btrfs-1: limit=0 goal=247413 dirty=212307 bdi_goal=649 bdi_dirty=212395 base_bw=102400 task_bw=13300 dirtied=256 dirtied_pause=256 period think pause=77 paused=0

trace_tab() {
	grep -o "[0-9.]\+: $1: .*" |\
	sed -e 's/bdi [^ ]\+//' \
	    -e 's/[^0-9.-]\+/ /g'
}

for pid in ${dd[0]} ${dd[1]} ${dd[2]}
do
	# if ($paused == 0) dirtied += $dirtied
	bzcat trace.bz2 | grep -F -- "-$pid " | trace_tab task_io > task-bw-$pid
	tail -n300 task-bw-$pid > task-bw-$pid-300
done

if [[ -s task-bw-${dd[0]} ]]; then
	plot
	plot -300
fi

cd ..
done
