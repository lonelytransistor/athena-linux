#!/bin/bash
CONFIGFS="/sys/kernel/config"
GADGET="$CONFIGFS/usb_gadget"

# Create a new webcam
function createWebcam() {
set -e
    echo Creating a new UVC device...

    FUNCTION=uvc.0
    CONFIG=c.1
    VID="0x1d6b"
    PID="0x0104"
    SERIAL="4815162342"
    MANUF="reMarkable"
    PRODUCT="UVC Screen Capture"
    NAME=webcam

    mkdir -p $GADGET/$NAME
    cd $GADGET/$NAME
    # USB setup
    echo $VID > idVendor
    echo $PID > idProduct
    echo 0x0100 > bcdDevice
    echo 0x0200 > bcdUSB
    echo 0xEF > bDeviceClass
    echo 0x02 > bDeviceSubClass
    echo 0x01 > bDeviceProtocol
    echo 64 > bMaxPacketSize0
    # English strings
    mkdir -p strings/0x409
    echo $SERIAL > strings/0x409/serialnumber
    echo $MANUF > strings/0x409/manufacturer
    echo $PRODUCT > strings/0x409/product
    # Create UVC config
    mkdir configs/$CONFIG
    echo 500 > configs/$CONFIG/MaxPower
    mkdir configs/$CONFIG/strings/0x409
    # Create UVC function
    mkdir functions/$FUNCTION
    # Create frames
    wdir="functions/$FUNCTION/streaming/mjpeg/m/1872p"
    mkdir -p $wdir
    echo 1404 > $wdir/wWidth
    echo 1872 > $wdir/wHeight
    echo 200000 > $wdir/dwFrameInterval
    echo 210263040 > $wdir/dwMinBitRate
    echo 420526080 > $wdir/dwMaxBitRate
    wdir="functions/$FUNCTION/streaming/mjpeg/m/1404p"
    mkdir -p $wdir
    echo 1872 > $wdir/wWidth
    echo 1404 > $wdir/wHeight
    echo 200000 > $wdir/dwFrameInterval
    echo 210263040 > $wdir/dwMinBitRate
    echo 420526080 > $wdir/dwMaxBitRate
    # Create headers
    mkdir functions/$FUNCTION/streaming/header/h
    cd functions/$FUNCTION/streaming/header/h
    ln -s ../../mjpeg/m
    cd ../../class/fs
    ln -s ../../header/h
    cd ../../class/hs
    ln -s ../../header/h
    cd ../../../control
    mkdir header/h
    ln -s header/h class/fs
    cd ../../../
    echo 2048 > functions/$FUNCTION/streaming_maxpacket
    echo 1 >  functions/$FUNCTION/streaming_interval
    ln -s functions/$FUNCTION configs/$CONFIG
set +e
}
# Create a new ethernet device:
function createEthernet() {
set -e
    echo Creating a new ethernet device...

    FUNCTION=ecm.0
    CONFIG=c.1
    VID="0x1d6b"
    PID="0x0104"
    SERIAL="4815162342"
    MANUF="reMarkable"
    PRODUCT="Virtual USB Ethernet"
    HOSTMAC="48:6f:73:74:50:43" # "HostPC"
    SELFMAC="42:61:64:55:53:42" # "BadUSB"
    NAME=ethernet

    mkdir -p $GADGET/$NAME
    cd $GADGET/$NAME
    # USB setup
    echo $VID > idVendor
    echo $PID > idProduct
    # English strings
    mkdir -p strings/0x409
    echo $SERIAL > strings/0x409/serialnumber
    echo $MANUF > strings/0x409/manufacturer
    echo $PRODUCT > strings/0x409/product
    # Create ethernet config
    mkdir configs/$CONFIG
    echo 500 > configs/$CONFIG/MaxPower
    mkdir configs/$CONFIG/strings/0x409
    # Create ethernet function
    mkdir -p functions/$FUNCTION
    # First byte of address must be even
    echo $HOSTMAC > functions/$FUNCTION/host_addr
    echo $SELFMAC > functions/$FUNCTION/dev_addr
    ln -s functions/$FUNCTION configs/$CONFIG
set +e
}
# Create a new terminal device:
function createACM() {
set -e
    echo Creating a new terminal device...

    FUNCTION=acm.0
    CONFIG=c.1
    VID="0x1d6b"
    PID="0x0104"
    SERIAL="4815162342"
    MANUF="reMarkable"
    PRODUCT="Serial Console"
    NAME=serial

    mkdir -p $GADGET/$NAME
    cd $GADGET/$NAME
    # USB setup
    echo $VID > idVendor
    echo $PID > idProduct
    # English strings
    mkdir -p strings/0x409
    echo $SERIAL > strings/0x409/serialnumber
    echo $MANUF > strings/0x409/manufacturer
    echo $PRODUCT > strings/0x409/product
    # Create ACM config
    mkdir configs/$CONFIG
    echo 500 > configs/$CONFIG/MaxPower
    mkdir configs/$CONFIG/strings/0x409
    # Create ACM function
    mkdir -p functions/$FUNCTION
    ln -s functions/$FUNCTION configs/$CONFIG
set +e
}
# Create a new MTP device:
function createMTP() {
set -e
    echo Creating a new MTP device...

    FUNCTION=ffs.mtp
    CONFIG=c.1
    VID="0x1d6b"
    PID="0x0105"
    SERIAL="4815162342"
    MANUF="reMarkable"
    PRODUCT="MTP Storage Device"
    NAME=mtp
    
    mkdir -p $GADGET/$NAME
    cd $GADGET/$NAME
    # USB setup
    echo $VID > idVendor
    echo $PID > idProduct
    # English strings
    mkdir -p strings/0x409
    echo $SERIAL > strings/0x409/serialnumber
    echo $MANUF > strings/0x409/manufacturer
    echo $PRODUCT > strings/0x409/product
    # Create MTP config
    mkdir configs/$CONFIG
    echo 500 > configs/$CONFIG/MaxPower
    mkdir configs/$CONFIG/strings/0x409
    # Create MTP function
    mkdir -p functions/$FUNCTION
    ln -s functions/$FUNCTION configs/$CONFIG
    mkdir /dev/ffs-mtp
    mount -t functionfs mtp /dev/ffs-mtp
set +e
}
# Create a HID tablet & keyboard combo device:
function createKBD() {
set -e
    echo Creating a keyboard device...

    CONFIG=c.1
    VID="0x1d6b"
    PID="0x0105"
    SERIAL="4815162342"
    MANUF="reMarkable"
    PRODUCT="HID Keyboard"
    NAME=kbd
    
    FUNCTION=hid.0
    PROTOCOL=1
    SUBCLASS=1
    REPORT_LENGTH=8
    DESCRIPTOR=/etc/athena/data/keyboard.hid
    
    mkdir -p $GADGET/$NAME
    cd $GADGET/$NAME
    # USB setup
    echo $VID > idVendor
    echo $PID > idProduct
    # English strings
    mkdir -p strings/0x409
    echo $SERIAL > strings/0x409/serialnumber
    echo $MANUF > strings/0x409/manufacturer
    echo $PRODUCT > strings/0x409/product
    # Create HID config
    mkdir configs/$CONFIG
    echo 500 > configs/$CONFIG/MaxPower
    mkdir configs/$CONFIG/strings/0x409
    # Create HID function
    mkdir -p functions/$FUNCTION
    echo $PROTOCOL > functions/$FUNCTION/protocol
    echo $SUBCLASS > functions/$FUNCTION/subclass
    echo $REPORT_LENGTH > functions/$FUNCTION/report_length
    cat $DESCRIPTOR > functions/$FUNCTION/report_desc
    # Link the function
    ln -s functions/$FUNCTION configs/$CONFIG
set +e
}
# Create a HID tablet & keyboard combo device:
function createTablet() {
set -e
    echo Creating a tablet device...

    CONFIG=c.1
    VID="0x1d6b"
    PID="0x0105"
    SERIAL="4815162342"
    MANUF="reMarkable"
    PRODUCT="HID Tablet"
    NAME=tablet
    
    FUNCTION=hid.0
    PROTOCOL=1
    SUBCLASS=1
    REPORT_LENGTH=8
    DESCRIPTOR=/etc/athena/data/keyboard.hid
    
    mkdir -p $GADGET/$NAME
    cd $GADGET/$NAME
    # USB setup
    echo $VID > idVendor
    echo $PID > idProduct
    # English strings
    mkdir -p strings/0x409
    echo $SERIAL > strings/0x409/serialnumber
    echo $MANUF > strings/0x409/manufacturer
    echo $PRODUCT > strings/0x409/product
    # Create HID config
    mkdir configs/$CONFIG
    echo 500 > configs/$CONFIG/MaxPower
    mkdir configs/$CONFIG/strings/0x409
    # Create HID function
    mkdir -p functions/$FUNCTION
    echo $PROTOCOL > functions/$FUNCTION/protocol
    echo $SUBCLASS > functions/$FUNCTION/subclass
    echo $REPORT_LENGTH > functions/$FUNCTION/report_length
    cat $DESCRIPTOR > functions/$FUNCTION/report_desc
    # Link the function
    ln -s functions/$FUNCTION configs/$CONFIG
set +e
}
#echo ci_hdrc.0 > UDC
createWebcam
createEthernet
createACM
createMTP
#createKbd
#createTablet
