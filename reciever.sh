#!/bin/bash


BASE_IP="192.168.1.1" 
RECEIVE_DIR="/path/to/receive/dir" 
GARBAGE_PACKAGE="garbage_package.txt"
ENCRYPTED_FILE="encrypted_file.gpg"
DECRYPTED_FILE="my_secret_file.txt"


function update_ip() {
    IFS='.' read -r -a octets <<< "$BASE_IP"
    octets[3]=$((octets[3] + 1))

    # If the last octet exceeds 254, reset it and increment the third octet
    if [[ ${octets[3]} -gt 254 ]]; then
        octets[3]=1
        octets[2]=$((octets[2] + 1))
    fi
    
    NEW_IP="${octets[0]}.${octets[1]}.${octets[2]}.${octets[3]}"
    echo $NEW_IP
}


echo "Waiting for the garbage package at $BASE_IP..."

# ye 5 sec wait karega bas
while true; do
    rsync -avz user@$BASE_IP:$GARBAGE_PACKAGE $RECEIVE_DIR/
    if [[ -f "$RECEIVE_DIR/$GARBAGE_PACKAGE" ]]; then
        echo "Garbage package received at $BASE_IP!"
        break
    fi

    echo "Still waiting for the garbage package..."
    sleep 5
done


PART_NUM=1
while true; do
    BASE_IP=$(update_ip)
    
    PACKAGE_NAME="package_part_$PART_NUM"
    echo "Receiving $PACKAGE_NAME from $BASE_IP..."
    
    rsync -avz user@$BASE_IP:$PACKAGE_NAME $RECEIVE_DIR/
    
    if [[ -f "$RECEIVE_DIR/$PACKAGE_NAME" ]]; then
        echo "$PACKAGE_NAME received."
        ((PART_NUM++))
    else
        #ye sab delte kar dega
        echo "Failed to receive $PACKAGE_NAME. Deleting all received files and aborting."
        rm -rf "$RECEIVE_DIR/*"
        exit 1
    fi
    
    #agra sab mil jata hai toh 
    if [[ "$PART_NUM" -gt TOTAL_NUM_OF_PACKAGES ]]; then
        echo "All packages received."
        break
    fi
done

#ye decrypt karge
cat "$RECEIVE_DIR/package_part_*" > "$RECEIVE_DIR/$ENCRYPTED_FILE"
echo "File reassembled. Decrypting the file..."

gpg --output "$RECEIVE_DIR/$DECRYPTED_FILE" --decrypt "$RECEIVE_DIR/$ENCRYPTED_FILE"

if [[ $? -eq 0 ]]; then
    echo "Decryption successful. File saved as $RECEIVE_DIR/$DECRYPTED_FILE."
else
    echo "Decryption failed."
    exit 1
fi

echo "All tasks completed successfully."
