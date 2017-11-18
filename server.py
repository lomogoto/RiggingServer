#!/usr/bin/env python3
import socket
import threading
import json
import time
import math
import smbus

#rigging data server
class server():
    #set configuration variables
    port = 6500
    alpha = 0.01

    mpu6050registers = {'ax':0x3B, 'ay':0x3D, 'az':0x3f, 'gx':0x43, 'gy':0x45, 'gz':0x47}

    sensors = {'rf': {'address':0x68, 'registers':mpu6050registers, 'calibrations':{'gx':0, 'gy':0, 'gz':0}},
        'rt': {'address':0x69, 'registers':mpu6050registers, 'calibrations':{'gx':0, 'gy':0, 'gz':0}}}

    power = 0x6B
    a_conf = 0x1B
    g_conf = 0x1C

    n = 100

    #initialize the server
    def __init__(self):
        #initialize i2c bus
        self.bus = smbus.SMBus(1)

        #make socket listening on port
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('', self.port))
        s.listen(1)

        #make new socket accepting a connection
        self.sock, addr = s.accept()

        #sensor data
        self.data = {'t' : 0}
        for s in self.sensors:
            self.data[s] = [0, 0, 0]

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
        self.bus.write_byte_data(sensor['address'], self.power, 0x00)

        #set ranges to 250 deg/s
        self.bus.write_byte_data(sensor['address'], self.g_conf, 0x00)

        #set accel ranges to  m/s/s
        self.bus.write_byte_data(sensor['address'], self.a_conf, 0x00)

        #loop over registers to calibrate
        for c in sensor['calibrations']:
            #pick by name
            register = sensor['registers'][c]

            #average first readings
            sum = 0
            for i in range(self.n):
                sum += self.get_register_data(sensor['address'], register)
            average = sum / self.n

            #save calibration
            sensor['calibrations'][c] = average

    #accept commands
    def listen(self):
        #loop until listening is set to false
        listening = True
        while listening:
            #accept a command from the client
            command = self.sock.recv(2048)

            #start processing data in the background
            if command == self.start_request:
                #enable polling
                self.running = True

                #initialize sensors
                for s in self.sensors:
                    self.init_sensor(self.sensors[s])

                #start processing thread
                self.data['t'] = time.time()
                t = threading.Thread(target = self.process)
                t.start()

                #confirm start
                self.sock.send(str(self.data['t']).encode())

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

        try:

            #loop until server is shut down
            while self.running:
                #start by reading time and change in time
                t = time.time()
                dt = t - self.data['t']
                self.data['t'] = t
    
                #loop over sensors and registers to get readings for each
                for s in self.sensors:
                    #pick a sensor by name
                    sensor = self.sensors[s]
    
                    #dictionary of sensor reading
                    read = {}
    
                    #loop over registers
                    for r in sensor['registers']:
                        #pick a register by name
                        register = sensor['registers'][r]
    
                        try:
                            calibration = sensor['calibrations'][r]
                        except:
                            calibration = 0
    
                        #read each register for sensor
                        read[r] = self.get_register_data(sensor['address'], register, calibration)
    
                    #get angles from acceleration
                    x = 90 - math.atan2(read['ay'], read['az'])*180/math.pi
                    y = math.atan2(read['ax'], read['az'])*180/math.pi
                    z = 90 - math.atan2(read['ay'], read['ax'])*180/math.pi
    
                    #calculate the impact of gravity on that angle
                    mag = math.sqrt(read['ax']**2 + read['ay']**2 + read['az']**2)
                    xMag = 1 #math.sqrt(read['ay']**2 + read['az']**2) / mag
                    yMag = 0 #math.sqrt(read['ax']**2 + read['az']**2) / mag
                    zMag = 1 #math.sqrt(read['ay']**2 + read['ax']**2) / mag
    
                    #update data for sensor
                    self.data[s][0] = (1 - self.alpha * xMag) * (self.data[s][0] + read['gx']/131.072 * dt) + self.alpha * xMag * x
                    self.data[s][1] = (1 - self.alpha * yMag) * (self.data[s][1] + read['gy']/131.072 * dt) + self.alpha * yMag * y
                    self.data[s][2] = (1 - self.alpha * zMag) * (self.data[s][2] + read['gz']/131.072 * dt) + self.alpha * zMag * z

        except Exception as e:
            print(e)

    #pack data into one dictionary for json dump
    def pack(self):
        data = self.data

        #return data encoded into a string
        return json.dumps(data, separators = (',', ':'))

    #read short using sensor address and register address
    def get_register_data(self, address, register, calibration = 0):
        #get high and low bytes
        h = self.bus.read_byte_data(address, register)
        l = self.bus.read_byte_data(address, register + 1)

        #move high byte up 8 digits and add low byte
        value = (h << 8) + l

        #convert from unsigned to signed short
        if value >= 0x8000:
            value -= 0x10000

        #return signed short
        return value - calibration

#start a new server object
server()
