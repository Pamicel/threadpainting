#!/bin/zsh

BASEDIR=$(dirname "$0")
OUTDIR="$BASEDIR/$1"

git -C "$BASEDIR" rev-parse HEAD > $OUTDIR/commit