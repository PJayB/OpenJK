#!/bin/bash
ROOTDIR=$(pwd)
if [ ! -f CMakeLists.txt ]; then
    echo "CMakeLists.txt is missing."
    exit 1
fi

TASKSFILE=$ROOTDIR/.vscode/tasks.json

CONFIGS="RELEASE DEBUG RELWITHDBGINFO MINSIZEREL"

MPTOGGLES="BuildMPCGame BuildMPDed BuildMPEngine BuildMPGame BuildMPRdVanilla BuildMPUI"
SPTOGGLES="BuildSPEngine BuildSPGame BuildSPRdVanilla"
JK2TOGGLES="BuildJK2SPEngine BuildJK2SPGame BuildJK2SPRdVanilla"

for t in $MPTOGGLES; do
    MPTOGGLES_OFF="$MPTOGGLES_OFF -D$t=OFF"
    MPTOGGLES_ON="$MPTOGGLES_ON -D$t=ON"
done
for t in $SPTOGGLES; do
    SPTOGGLES_OFF="$SPTOGGLES_OFF -D$t=OFF"
    SPTOGGLES_ON="$SPTOGGLES_ON -D$t=ON"
done
for t in $JK2TOGGLES; do
    JK2TOGGLES_OFF="$JK2TOGGLES_OFF -D$t=OFF"
    JK2TOGGLES_ON="$JK2TOGGLES_ON -D$t=ON"
done

echo '{' > $TASKSFILE
echo '  "version":"2.0.0",' >> $TASKSFILE
echo '  "tasks": [' >> $TASKSFILE

function do_config {
    FLAVOR=$1
    TOGGLES=$2
    ISDEFAULT=$3
    for c in $CONFIGS; do
        echo "Setting up config $FLAVOR|$c..."
        LOWERNAME=$(echo "${c,,}")
        PROJECTDIR=build/$FLAVOR/$LOWERNAME
        BINARYDIR=bin
        if [ ! -d $PROJECTDIR ]; then
            mkdir -p $PROJECTDIR
        fi
        if [ ! -d $PROJECTDIR/$BINARYDIR ]; then
            mkdir -p $PROJECTDIR/$BINARYDIR
        fi
        pushd $PROJECTDIR
        cmake "-DCMAKE_INSTALL_PREFIX=$BINARYDIR" "-DCMAKE_BUILD_TYPE=$c" $TOGGLES "$ROOTDIR"
        popd
        echo '    {' >> $TASKSFILE
        echo "      \"label\":\"Build $FLAVOR|$LOWERNAME\"," >> $TASKSFILE
        echo '      "type":"shell",' >> $TASKSFILE
        echo "      \"command\":\"cd $PROJECTDIR && make -j && make install\"," >> $TASKSFILE
        if [ "$ISDEFAULT" == "$c" ]; then
        echo '      "group": {' >> $TASKSFILE
        echo '        "kind":"build",' >> $TASKSFILE
        echo '        "isDefault":true' >> $TASKSFILE
        echo '      },' >> $TASKSFILE
        else
        echo '      "group":"build",' >> $TASKSFILE
        fi
        echo '      "problemMatcher": [' >> $TASKSFILE
        echo '        "$gcc"' >> $TASKSFILE
        echo '      ]' >> $TASKSFILE
        echo "    }," >> $TASKSFILE
    done
}

do_config "jasp" "$SPTOGGLES_ON $MPTOGGLES_OFF $JK2TOGGLES_OFF" "DEBUG"
do_config "jamp" "$SPTOGGLES_OFF $MPTOGGLES_ON $JK2TOGGLES_OFF"
do_config "josp" "$SPTOGGLES_OFF $MPTOGGLES_OFF $JK2TOGGLES_ON"

echo '  ]' >> $TASKSFILE
echo '}' >> $TASKSFILE
