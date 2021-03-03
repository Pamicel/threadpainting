#!/bin/bash
ffmpeg -i raw.avi -crf 10 -vf "transpose=2" finalvid.mp4