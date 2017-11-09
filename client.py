#!/usr/bin/env python3
import socket
import threading
import json

#client interface
class client():
    #set configuration variables
    address = ('10.42.0.1', 6500)

    #initialize the client
    def __init__(self):
        #connect a socket on the address
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.connect(self.address)

        #data collection defaults to off
        self.running = False

        #variable for collected data
        self.data = {}

        #commands for server
        self.send_request = 'send'.encode()
        self.start_request = 'start'.encode()
        self.stop_request = 'stop'.encode()

    #request data to process and process it constantly
    def process(self):
        while self.running:
            self.sock.send(self.send_request)
            self.data = json.loads(self.sock.recv(4096).decode())

    #start data collection
    def start(self):
        #enable the collection
        self.running = True
        self.sock.send(self.start_request)
        print(self.sock.recv(4096).decode())

        #start data processing in background
        t = threading.Thread(target = self.process)
        t.start()

    #stop the data collections and shut down server
    def stop(self):
        self.running = False
        self.sock.send(self.stop_request)

#run basic test if main
if __name__ == '__main__':
    import time
    c = client()
    c.start()
    try:
        while True:
            time.sleep(0.5)
            print(c.data)
    finally:
        c.stop()
