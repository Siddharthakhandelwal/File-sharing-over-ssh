The both file are using SSH protocol for sharing and receiving the file.
Sender File - 
In this sender will start sending the file by first sending the garbage package and after that change the IP in specific pattern , the next packages will be sneded to this new IP and search for garbage Package If found then continue otherwise brak and delete all the files.
Receiver File -
In this , there is a function to update the IP , if any ereor accurs it will delete all the previously received files.After Receiving all the files it will start decrypting them.
