#!/usr/bin/env python3
import socket

port = 5000

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

sock.bind(('', port))

sock.listen(1)

s, address = sock.accept()

s.send('Connected'.encode())

running = True

while running:
    command = s.recv(1024).decode()

    if command == 'exit':
        running = False
    elif command == 'send':
        pass
    elif command == 'record':
        pass
    elif command == 'stop':
        pass
    else:
        print(command)
