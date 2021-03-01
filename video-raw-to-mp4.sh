#!/bin/bash
ffmpeg -i raw.avi -crf 10 -vf "transpose=1" finalvid.mp4