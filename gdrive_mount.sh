#!/bin/bash
OPTIONS="--daemon \
--cache-dir /tmp/rclone-cache \
--vfs-cache-mode full \
--vfs-cache-max-size 1G \
--vfs-cache-max-age 24h \
--vfs-read-chunk-size 32M"
rclone mount gdrive: ~/GDrive ${OPTIONS}
rclone mount MWgdrive: ~/MWGDrive ${OPTIONS}
#rclone mount GooglePhotos: ~/GooglePhotos ${OPTIONS}
