#!/usr/bin/env python3
import socket

address = ('10.42.0.1', 5000)

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

s.connect(address)

print(s.recv(1024).decode())
