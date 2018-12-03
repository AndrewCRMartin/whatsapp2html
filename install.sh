#!/usr/bin/bash
SCRIPTS=$HOME/scripts/whatsapp2html
BIN=$HOME/bin
EMOJIS=$BIN/share/whatsapp2html/emojis
CSS=$BIN/share/whatsapp2html/css
PROGS="whatsapp2html.pl"
HERE=`pwd`

# Create directories
if [ ! -d $SCRIPTS ]; then
   echo "Creating scripts directory: $SCRIPTS"
   mkdir -p $SCRIPTS
fi
if [ ! -d $BIN ]; then
   echo "Creating bin directory: $BIN"
   mkdir -p $BIN
fi
if [ ! -d $EMOJIS ]; then
   echo "Creating emojis directory: $EMOJIS"
   mkdir -p $EMOJIS
fi
if [ ! -d $CSS ]; then
   echo "Creating css directory: $CSS"
   mkdir -p $CSS
fi

# Copy programs to scripts directory and make links in bin
for prog in $PROGS; do
   cp src/$prog $SCRIPTS
   (cd $BIN; ln -sf $SCRIPTS/$prog `basename $prog .pl`)
done

# Unpack emojis
cd $EMOJIS
tar zxf $HERE/emojis.tgz
mv emojis/* .
rmdir emojis
cd $HERE

# Copy CSS
cp src/whatsapp.css $CSS



