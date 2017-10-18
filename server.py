#import needed modules
import socket

#set communication port
port = 5000

#make tcp socket for assured delivery
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

#bind the socket to all IP addresses and port 5000
sock.bind(('', port))

#listen for connections, allowing only one
sock.listen(1)

#get the communication socket and address of connected device
s, address = sock.accept()

#send a welcome message
s.send('You have connected'.encode())
