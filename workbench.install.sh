#!/bin/bash

echo "Checking if GitHub CLI (gh) is installed in your system"
sleep 1

if GH=$(gh --version);
then
    echo -n $GH
    echo " is installed"
else
    echo "Installation aborted. Please install the GitHub CLI first (https://github.com/cli/cli?tab=readme-ov-file#installation)"
    exit 1
fi
echo ""
echo "Checking if jq utility is installed in your system"
sleep 1
if JQ=$(jq --version);
then
    echo -n $JQ
    echo " is installed"
else
    echo "Installation aborted. Please install the jq utility first (https://jqlang.github.io/jq/download/)"
    exit 1
fi

echo ""
sleep 1

CFGDIR="$HOME/.config/workbench"
BINDIR="$HOME/.wb/bin"

echo "Installing Merthin's workbench"
echo "Creating directory structure"
mkdir -p $CFGDIR
mkdir -p $BINDIR
sleep 1
echo "Downloading components"
curl -sLo $CFGDIR/workbench.functions.sh https://raw.githubusercontent.com/MerthinTechnologies/workbench/master/dist/workbench.functions.sh
curl -sLo $BINDIR/workbench https://raw.githubusercontent.com/MerthinTechnologies/workbench/master/dist/workbench
chmod 755 $BINDIR/workbench
echo ""
echo "Merthin's workbench installed."
echo ""
echo "Please include $BINDIR to your exec PATH. At this to your shell rc file (i.e. .bashrc):"
echo ""
echo "export PATH=$PATH:$BINDIR"
echo ""






