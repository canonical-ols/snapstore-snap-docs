#!/bin/bash

BUILDDIR=$HOME/snapstore-snap-docs

cleanup()
{
    rm -rf "$BUILDDIR"
}

trap cleanup EXIT

mkdir -p "$BUILDDIR"
cp -a ./* "$BUILDDIR"
documentation-builder --base-directory "$BUILDDIR" --output-path "$BUILDDIR/html"
cp -a "$BUILDDIR/html" . 
