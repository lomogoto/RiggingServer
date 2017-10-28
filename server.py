#!/usr/bin/env python3
import socket
import threading
import json
import time
####import smbus

#rigging data server
class server():
    #set configuration variables
    port = 6500
    sensors = {'rf':0x68}
    registers = {'ax':0x3B, 'ay':0x3D, 'az':0x3f, 'gx':0x43, 'gy':0x45, 'gz':0x47}
    power = 0x6B
    a_conf = 0x1B
    g_conf = 0x1C

    #initialize the server
    def __init__(self):
        #initialize i2c bus
        ####self.bus = sbmus.SMBUS(1)

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

    #initialize a sensor
    def init_sensor(self, sensor):
        #wake sensor
        self.bus.write_byte_data(sensor, self.power, 0x00)

        #set ranges to 250 deg/s
        self.bus.write_byte_data(sensor, self.g_conf, 0x00)

    #accept commands
    def listen(self):
        #loop until listening is set to false
        listening = True
        while listening:
            #accept a command from the client
            command = self.sock.recv(2048)

            #start processing data in the background
            if command == self.start_request:
                #initialize sensors
                for sensor in self.sensors:
                    pass ####self.init_sensor(self.sensors[sensor])

                #start processing thread
                self.start_time = time.time()
                t = threading.Thread(target = self.process)
                ####t.start()

                #confirm start
                self.sock.send('started'.encode())

            #transmit current data values
            elif command == self.send_request:
                #pack the data in the json standard format with no whitespace
                self.sock.send(self.pack().encode())

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
        #form dictionary for sending
        data = {'t' : 0,
            's1' : [1, 2, 3],
            's2' : [4, 5, 6],
            's3' : [7, 8, 9]}

        #return data encoded into a string
        return json.dumps(data, separators = (',', ':'))

    #read short using sensor address and register address
    def get_register_data(self, sensor, register):
        #get high and low bytes
        h = self.bus.read_byte_data(sensor, register)
        l = self.bus.read_byte_data(sensor, register + 1)

        #move high byte up 8 digits and add low byte
        value = (h << 8) + l

        #convert from unsigned to signed short
        if value >= 0x8000:
            value -= 0x10000

        #return signed short
        return value

#start a new server object
server()
