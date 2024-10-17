#!/bin/bash

# first ip address
BASE_IP="192.168.1.1"

FILE_TO_ENCRYPT="" #youtr file name to encrypt
GARBAGE_PACKAGE="" #pre defined garbage package name
RECEIVE_DIR="" #receive directory
DESTINATION_PATH="" #destination path

# Encrypt 
gpg --output encrypted_file.gpg --symmetric --cipher-algo AES256 "$FILE_TO_ENCRYPT"
echo "File encrypted."

# divide in parts of 1MB 
split -b 1M encrypted_file.gpg package_part_
echo "File split into multiple parts."

#garbage
echo "This is a garbage package" > "$GARBAGE_PACKAGE"

# ye check and update karega
function update_ip() {
    IFS='.' read -r -a octets <<< "$BASE_IP"
    octets[3]=$((octets[3] + 1))

    # agar 254 cross karne par rest and 3 octet se start karega better rahega file divide ka size bda do
    if [[ ${octets[3]} -gt 254 ]]; then
        octets[3]=1
        octets[2]=$((octets[2] + 1))
    fi
    
    NEW_IP="${octets[0]}.${octets[1]}.${octets[2]}.${octets[3]}"
    echo $NEW_IP
}

# num of split packages
PARTS=(package_part_*)
NUM_PARTS=${#PARTS[@]}

# loop to send , = becaue garbage bhi dena hai
for (( i=0; i<=$NUM_PARTS; i++ ))
do
    
    
    if [[ $i -eq 0 ]]; then
        #garbage phele
        echo "Sending garbage package to $BASE_IP..."
        rsync -avz "$GARBAGE_PACKAGE" user@$BASE_IP:$DESTINATION_PATH
    else
        # yha se phela package
        BASE_IP=$(update_ip)

        PACKAGE=${PARTS[$((i-1))]}
        echo "Sending $PACKAGE to $BASE_IP..."
        rsync -avz "$PACKAGE" user@$BASE_IP:$DESTINATION_PATH
    fi

    #wairt to see
    sleep 5  
    # connect to reciever 
    ssh user@$BASE_IP "test -f $RECEIVE_DIR/$GARBAGE_PACKAGE"
    if [[ $? -ne 0 ]]; then
        echo "Garbage package not found on the receiver's end. Aborting."
        #yahi del bhi kar dega na milne par
        for FILE in "${SENT_FILES[@]}"; do
            rm -f "$FILE"
            echo "Deleted $FILE"
        done
        
        exit 1
    fi
done

echo "All packages sent successfully."
