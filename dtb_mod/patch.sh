#!/bin/bash
set -e

doCleanUp=1
outDir="dist"
function patch_dts() {
    echo "Processing $1..."
    dtc -o tmp.dts -O dts zero-sugar.dtb 2>/dev/null
    patch -p1 -F1 -i patches/$1.patch tmp.dts
    mkdir -p ${outDir}
    dtc -o ${outDir}/zero-sugar_$1.dtb -O dtb tmp.dts 2>/dev/null
    echo "Done."
}
function clean_up() {
    echo "Cleaning up..."
    rm -f tmp.dts
}

if [ "$1" = "--no-cleanup" ]; then
    doCleanUp=0
    shift
fi
if [ "$2" != "" ]; then
    outDir="$2"
fi
if [ "$1" = "clean" ]; then
    clean_up
elif [ "$1" = "build" ]; then
    clean_up
    patch_dts -75mV
    patch_dts -50mV
    patch_dts -25mV
    patch_dts   0mV
    patch_dts  25mV
    patch_dts  50mV
    patch_dts  75mV
    if [[ ${doCleanUp} -eq 1 ]]; then
        clean_up
    fi
else
    echo "Usage: ./patch.sh [OPTION] <clean|build> [OUTDIR]"
    echo "Builds a patched dtb. If OUTDIR is ommited, the output files will be placed in dist/"
    echo ""
    echo "Options:"
    echo "   --no-cleanup - do not clean after building"
fi
