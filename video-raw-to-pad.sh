#!/bin/bash
ffmpeg -i raw.avi -crf 10 -vf "pad=1700:1700:(ow-iw)/2:(oh-ih)/2:color=white,transpose=2" finalpad.mp4