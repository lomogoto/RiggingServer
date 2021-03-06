#!/usr/bin/env python3
import socket
import threading
import json
import time
import math
import smbus
import Adafruit_ADS1x15

#rigging data server
class server():
    #set configuration variables
    port = 6500
    alpha = 0.02
    gain = 2/3
    down = 10000

    #number of times to poll data when calibrating
    n = 1000

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
        print('Accepting Connections')
        self.sock, addr = s.accept()
        print('Connected to ' + str(addr[0]))
    
        #sensor data
        self.data = {'t' : 0}

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
                #enable polling
                self.running = True
        
                #build sensors
                self.sensors = {
                    'rf':self.init_mpu6050(0x68),
                    'rt':self.init_alt10(0x1D, 0x6B),
                    'lf':self.init_mpu6050(0x69),
                    'lt':self.init_alt10(0x1E, 0x6A)}

                #add analog sensors
                self.analogs = {
                    'rp':Adafruit_ADS1x15.ADS1115(address=0x48),
                    'lp':Adafruit_ADS1x15.ADS1115(address=0x49)}

                #initialize the sensor data
                for s in self.sensors:
                    self.calibrate(self.sensors[s])
                    self.data[s] = [0, 0, 0]

                #initialize analog data
                for a in self.analogs:
                    self.data[a] = [0, 0, 0, 0]

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
                self.sock.send('{}'.encode())

    #calibrate a sensor
    def calibrate(self, sensor):
        #loop over registers to calibrate
        for c in sensor['calibrations']:
            #pick by name
            register = sensor['registers'][c]

            #average first readings
            total = 0
            for i in range(self.n):
                total += self.get_register_data(sensor['cal_address'], register)
            average = total / self.n

            #save calibration
            sensor['calibrations'][c] = average

    #read from sensors and integrate on a loop
    def process(self):
        #attempt to process requests
        try:
            #loop until server is shut down
            while self.running:
                #start by reading time and change in time
                t = time.time()
                dt = t - self.data['t']
                self.data['t'] = t

                #pole analog data
                for a in self.analogs:
                    #pick analog by name
                    analog = self.analogs[a]

                    #collect data
                    for i in range(4):
                        #make data zero if sensor unreachable
                        try:
                            self.data[a][i] = int(analog.read_adc(i, gain = self.gain) > self.down)
                        except IOError:
                            self.data[a][i] = 0
    
                #loop over sensors and registers to get readings for each
                for s in list(self.sensors):
                    #pick a sensor by name
                    sensor = self.sensors[s]
    
                    #dictionary of sensor reading
                    read = {}

                    #delete sensor if un reachable
                    try:
                        #loop over addresses
                        for address in sensor['addresses']:
                            #loop over registers
                            for r in sensor['addresses'][address]:
                                #pick a register by name
                                register = sensor['registers'][r]
            
                                #check for calibrations
                                try:
                                    calibration = sensor['calibrations'][r]
                                except KeyError:
                                    calibration = 0
            
                                #read each register for sensor
                                read[r] = self.get_register_data(address, register, calibration)
    
                        #get gyro data
                        g = [read['gx'], read['gy'], read['gz']]
    
                        #get angles from acceleration
                        euler = [None, None, None]
                        if sensor['up'] == '-x':
                            euler[1] = math.degrees(math.atan2(read['az'], -read['ax']))
                            euler[2] = -math.degrees(math.atan2(read['ay'], -read['ax']))
                        elif sensor['up'] == 'y':
                            euler[0] = math.degrees(math.atan2(read['az'], read['ay']))
                            euler[2] = -math.degrees(math.atan2(read['ax'], read['ay']))
    
                        #range factor
                        scale = sensor['range']*2**-15
    
                        #update data for sensor
                        for i in range(3):
                            #check if filtering or not
                            alpha = self.alpha
                            if euler[i] == None:
                                alpha = euler[i] = 0
    
                            #filter data
                            self.data[s][i] = (1 - alpha) * (self.data[s][i] + g[i]*scale * dt) - alpha * euler[i]
                    except IOError:
                        del self.sensors[s]
                        del self.data[s]

        #print out any errors from requests
        except Exception as e:
            print('Error: ' + str(e))

    #pack data into one dictionary for json dump
    def pack(self):
        data = self.data

        #return data encoded into a string
        return json.dumps(data, separators = (',', ':'))

    #initialize alt10 sensor
    def init_alt10(self, addr_am, addr_g):
        #sensor rergister data
        registers = {
            'mx':(0x9,  0x8),  'my':(0xB,  0xA),  'mz':(0xC,  0xD),
            'ax':(0x29, 0x28), 'ay':(0x2B, 0x2A), 'az':(0x2D, 0x2C),
            'gx':(0x29, 0x28), 'gy':(0x2B, 0x2A), 'gz':(0x2D, 0x2C)}

        #power on gyro
        self.bus.write_byte_data(addr_g, 0x20, 0b1111)
        
        #power on accelerometer and magnetometer
        self.bus.write_byte_data(addr_am, 0x20, 0b10100111)
        self.bus.write_byte_data(addr_am, 0x24, 0b01110100)
        self.bus.write_byte_data(addr_am, 0x26, 0b00000000)

        #use three addresses, one for each sensor
        addresses = {addr_am:('ax', 'ay', 'az', 'mx', 'my', 'mz'),
            addr_g:('gx', 'gy', 'gz')}

        #make dictionary for sensor
        sensor = {'addresses':addresses, 'registers':registers, 'cal_address':addr_g, 'calibrations':{'gx':0, 'gy':0, 'gz':0}, 'range':245, 'up':'-x'}

        #return the sensor dictionary
        return sensor

    #initialize bno055 sensor
    def init_bno055(self, address):
        #sensor register data
        registers = {
            'mx':(0xF,  0xE),  'my':(0x11, 0x10), 'mz':(0x13, 0x12),
            'ax':(0x9,  0x8),  'ay':(0xB,  0xA),  'az':(0xD,  0xC),
            'gx':(0x15, 0x14), 'gy':(0x17, 0x16), 'gz':(0x18, 0x19)}

        #set gyro range to 125 deg/s
        self.bus.write_byte_data(address, 0xA, 0b00000100)

        #set normal power mode
        self.bus.write_byte_data(address, 0x3E, 0x0)

        #enable all sensors without fusion
        self.bus.write_byte_data(address, 0x3D, 0x7)
        time.sleep(0.3)

        #make addresses
        addresses = {address:('ax', 'ay', 'az', 'gx', 'gy', 'gz', 'mx', 'my', 'mz')}

        #make dictionary for sensor
        sensor = {'addresses':addresses, 'registers':registers, 'cal_address':address, 'calibrations':{'gx':0, 'gy':0, 'gz':0}, 'range':2000}

        #return the sensor dictionary
        return sensor

    #initialize an mpu6050 sensor
    def init_mpu6050(self, address):
        #sensor register data
        registers = {
            'ax':(0x3B, 0x3C), 'ay':(0x3D, 0x3E), 'az':(0x3f, 0x40),
            'gx':(0x43, 0x44), 'gy':(0x45, 0x46), 'gz':(0x47, 0x48)}

        #wake sensor
        self.bus.write_byte_data(address, 0x6B, 0x00)

        #set ranges to 250 deg/s
        self.bus.write_byte_data(address, 0x1C, 0x00)

        #set accel ranges to  m/s/s
        self.bus.write_byte_data(address, 0x1B, 0x00)

        #make addresses
        addresses = {address:('ax', 'ay', 'az', 'gx', 'gy', 'gz')}

        #make dictionary for sensor
        sensor = {'addresses':addresses, 'registers':registers, 'cal_address': address, 'calibrations':{'gx':0, 'gy':0, 'gz':0}, 'range':250, 'up':'y'}

        #return the sensor dictionary
        return sensor

    #read short using sensor address and register address (high, low)
    def get_register_data(self, address, register, calibration = 0):
        #get high and low bytes
        h = self.bus.read_byte_data(address, register[0])
        l = self.bus.read_byte_data(address, register[1])

        #move high byte up 8 digits and add low byte
        value = (h << 8) + l

        #convert from unsigned to signed short
        if value >= 0x8000:
            value -= 0x10000

        #return signed short
        return value - calibration

#start a new server object
clean_stop = False
while not clean_stop:
    try:
        server()
        clean_stop = True
    except Exception as e:
        print('Error: ' + str(e))
