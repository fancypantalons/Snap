#!/bin/sh

#
# Snap installation script.
#

#
# Change ROOT_PATH if you want to install Snap into a different tree
# (eg, /usr).
#

ROOT_PATH=/usr/local

BIN_PATH=$ROOT_PATH/bin
LIB_PATH=$ROOT_PATH/lib/libsnap
SHARE_PATH=$ROOT_PATH/share/snap

SCRIPT_NAME=snap.inst
USER_SCRIPT=$ROOT_PATH/bin/$SCRIPT_NAME

###############################################################################

echo "Creating installation directories..."

mkdir $LIB_PATH
mkdir $SHARE_PATH
mkdir $SHARE_PATH/scripts

echo "Copying files..."

cp snap $BIN_PATH/snap
cp -r libsnap/* $LIB_PATH/

cp snaprc $SHARE_PATH/
cp -r scripts/* $SHARE_PATH/scripts/

echo "Setting permissions..."

chmod 755 $BIN_PATH/snap
chmod 755 $LIB_PATH

find $LIB_PATH -type d -exec chmod 755 \{\} \;
find $LIB_PATH -type f -exec chmod 644 \{\} \;

find $SHARE_PATH -type d -exec chmod 755 \{\} \;
find $SHARE_PATH -type f -exec chmod 644 \{\} \;

echo "Creating user install script ($SCRIPT_NAME)..."

cat <<EOF > $USER_SCRIPT
#!/bin/sh

echo "Copying RC file..."
cp $SHARE_PATH/snaprc \$HOME/.snaprc

echo "Creating snap directory..."
mkdir \$HOME/snap
mkdir \$HOME/snap/upload
mkdir \$HOME/snap/download

echo
echo "Please edit your .snaprc to set your username and password."
EOF

chmod 755 $USER_SCRIPT
