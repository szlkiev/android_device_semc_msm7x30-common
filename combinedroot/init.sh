#!/sbin/busybox sh
set +x
_PATH="$PATH"
export PATH=/sbin

busybox cd /
busybox date >>boot.txt
exec >>boot.txt 2>&1
busybox rm /init

# include device specific vars
source /sbin/bootrec-device

# create directories
busybox mkdir -m 755 -p /cache
busybox mkdir -m 755 -p /dev/block
busybox mkdir -m 755 -p /dev/input
busybox mkdir -m 555 -p /proc
busybox mkdir -m 755 -p /sys

# create device nodes
busybox mknod -m 600 /dev/block/mmcblk0 b 179 0
busybox mknod -m 600 ${BOOTREC_CACHE_NODE}
busybox mknod -m 600 ${BOOTREC_EVENT_NODE}
busybox mknod -m 666 /dev/null c 1 3

# mount filesystems
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys
busybox mount -t yaffs2 ${BOOTREC_CACHE} /cache

# fixing CPU clocks to avoid issues in recovery
busybox echo 1024000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
busybox echo 122000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

# trigger lime green LED & button-backlight
busybox echo 25 > ${BOOTREC_LED_RED}
busybox echo 255 > ${BOOTREC_LED_GREEN}
busybox echo 0 > ${BOOTREC_LED_BLUE}
busybox echo 255 > ${BOOTREC_LED_BUTTONS}
busybox echo 50 > ${BOOTREC_VIBRATOR}
busybox cat ${BOOTREC_EVENT} > /dev/keycheck&
busybox sleep 1

# trigger pink LED & button-backlight
busybox echo 100 > ${BOOTREC_LED_RED}
busybox echo 35 > ${BOOTREC_LED_GREEN}
busybox echo 50 > ${BOOTREC_LED_BLUE}
busybox echo 255 > ${BOOTREC_LED_BUTTONS}
busybox echo 50 > ${BOOTREC_VIBRATOR}
busybox cat ${BOOTREC_EVENT} > /dev/keycheck&
busybox sleep 1

# trigger aqua blue LED & button-backlight
busybox echo 0 > ${BOOTREC_LED_RED}
busybox echo 100 > ${BOOTREC_LED_GREEN}
busybox echo 255 > ${BOOTREC_LED_BLUE}
busybox echo 255 > ${BOOTREC_LED_BUTTONS}

# trigger vibrator
busybox echo 200 > ${BOOTREC_VIBRATOR}

# keycheckblue
busybox cat ${BOOTREC_EVENT} > /dev/keycheck&
busybox sleep 3

# android ramdisk
load_image=/sbin/ramdisk.cpio

# boot decision
if [ -s /dev/keycheck -o -e /cache/recovery/boot ]
then
	busybox echo 'RECOVERY BOOT' >>boot.txt
	busybox rm -fr /cache/recovery/boot
	# trigger gold led
	busybox echo 90 > ${BOOTREC_LED_RED}
	busybox echo 255 > ${BOOTREC_LED_GREEN}
	busybox echo 0 > ${BOOTREC_LED_BLUE}
	busybox echo 0 > ${BOOTREC_LED_BUTTONS}
	# framebuffer fix
	busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
	# recovery ramdisk
	load_image=/sbin/ramdisk-recovery.cpio
else
	busybox echo 'ANDROID BOOT' >>boot.txt
	# poweroff LED & button-backlight
	busybox echo 0 > ${BOOTREC_LED_RED}
	busybox echo 0 > ${BOOTREC_LED_GREEN}
	busybox echo 0 > ${BOOTREC_LED_BLUE}
	busybox echo 0 > ${BOOTREC_LED_BUTTONS}
	# framebuffer fix
	busybox echo 1 > /sys/module/msm_fb/parameters/align_buffer
fi

# kill the keycheck process
busybox pkill -f "busybox cat ${BOOTREC_EVENT}"

# unpack the ramdisk image
busybox cpio -i < ${load_image}

busybox umount /cache
busybox umount /proc
busybox umount /sys

busybox rm -fr /dev/*
busybox date >>boot.txt
export PATH="${_PATH}"
exec /init
