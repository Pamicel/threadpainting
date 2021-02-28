#!/bin/bash
ffmpeg -f image2 -framerate 60 -i screen-%04d.tif -vcodec rawvideo -pix_fmt yuv420p raw.avi