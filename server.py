#!/usr/bin/env python3
import socket
import threading
import json

#rigging data server
class server():
    #set configuration variables
    port = 6500
    sensors = {'rt':0x68, 'lt':0x01, 'rs':0x02, 'ls':0x03}
    registers = {'ax':0x3B, 'ay':0x3D, 'az':0x3f, 'gx':0x43, 'gy':0x45, 'gz':0x47}

    #initialize the server
    def __init__(self):
        #make socket listening on port
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.bind(('', self.port))
        s.listen(1)

        #make new socket accepting a connection
        self.sock, addr = s.accept()

        #start with no data collection active
        self.running = False

        #accepted commands
        self.send_request = 'send'.encode()
        self.start_request = 'start'.encode()
        self.stop_request = 'stop'.encode()

        #start listening for commands
        self.listen()

    #accept commands
    def listen(self):
        #loop until listening is set to false
        listening = True
        while listening:
            #accept a command from the client
            command = self.sock.recv(2048)

            #start processing data in the background
            if command == self.start_request:
                t = threading.Thread(target = self.process)
                ####t.start()
                self.sock.send('started'.encode())

            #transmit current data values
            elif command == self.send_request:
                #pack the data in a standard format json
                self.sock.send(json.dumps(self.pack()).encode())

            #end data collection and shutdown (if stop request)
            else:
                listening = False
                self.running = False
                self.sock.send(''.encode())

    #read from sensors and integrate on a loop
    def process(self):
        #loop until server is shut down
        while self.running:
            pass

    #pack data into one dictionary for json dump
    def pack(self):
        return {'t':0, 's1':(1,2,3), 's2':(4,5,6), 's3':(7,8,9)}

    #read short using sensor address and register address
    def get_register_data(self, sensor, register):
        #get high and low bytes
        h = 255 ####self.bus.read_byte_data(sensor, register)
        l = 128 ####self.bus.read_byte_data(sensor, register + 1)

        #move high byte up 8 digits and add low byte
        value = (h << 8) + l

        #convert from unsigned to signed short
        if value >= 0x8000:
            value -= 0x10000

        #return signed short
        return value

#start a new server object
server()
