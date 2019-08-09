#!/usr/bin/env bash

if [ $# -ne 3 ]
then
cat << EOF
Usage : 
$0 /partition/to/encrypt partition-name /path/to/boot
EOF
exit
fi

rbtohex() {
    ( od -An -vtx1 | tr -d ' \n' )
}

hextorb() {
    ( tr '[:lower:]' '[:upper:]' | sed -e 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI'| xargs printf )
}

PARTITION="$1"
NAME="$2"
BOOT_ROOT="$3"
SALT_LENGTH=16
KEY_LENGTH=512
ITERATIONS=1000000
CIPHER="aes-xts-plain64"
HASH="sha512"

echo "computing salt"
SALT="$(dd if=/dev/random bs=1 count=$SALT_LENGTH 2>/dev/null | rbtohex)"

echo "enter passphrase"
read -s USER_PASSPHRASE
echo "confirm passphrase"
read -s CONFIRM_USER_PASSPHRASE

if [ "$USER_PASSPHRASE" != "$CONFIRM_USER_PASSPHRASE" ]
then
    echo "Passphrase are different exiting"
    exit
fi

echo "creating challenge"
CHALLENGE="$(echo -n $SALT | openssl dgst -binary -sha512 | rbtohex)"
RESPONSE=$(ykchalresp -2 -x $CHALLENGE 2>/dev/null)

echo "Creating luks key"
LUKS_KEY="$(echo -n $USER_PASSPHRASE | pbkdf2-sha512 $(($KEY_LENGTH / 8)) $ITERATIONS $RESPONSE | rbtohex)"

echo "Encrypting"
echo -n "$LUKS_KEY" | hextorb | cryptsetup luksFormat --cipher="$CIPHER" --key-size="$KEY_LENGTH" --hash="$HASH" --key-file=- "$PARTITION"

echo "saving salt"
mkdir -p "$BOOT_ROOT/crypt-storage"
echo -ne "$SALT\n$ITERATIONS" > "$BOOT_ROOT/crypt-storage/default"

echo "opening encrypted partition"
echo -n "$LUKS_KEY" | hextorb | cryptsetup open "$PARTITION" "$NAME-cyphered" --key-file=-

echo "formatting"
mkfs.ext4 -L "$NAME" "/dev/mapper/$NAME-cyphered"

