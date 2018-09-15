#!/usr/bin/python
import argparse
import serial
import csv
import struct
import time
import random


cmds = { 
    'ADDR' : 1 ,
    'LOAD' : 2,
    'WRITE' : 3,
    'READ' : 4,
    'READ_REQ' : 5,
    'COUNT': 6,
    'CONST': 7,
    }

def cmd(cmd, tx_data=0):
    ser.write(struct.pack('B', cmds[cmd] ))
    ser.write(struct.pack('>I', tx_data))

    rx_data = ser.read(4)
    data, = struct.unpack('>I', rx_data)
    if args.verbose:
        print(cmd, tx_data, data)
    return data


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="communicate with FPGA over serial")
    parser.add_argument('--port', default='/dev/ttyUSB0', help="serial port")
    parser.add_argument('--write', const=True, action="store_const", help="write test")
    parser.add_argument('--read', const=True, action="store_const", help="read test")
    parser.add_argument('--sequential', const=True, action="store_const", help="sequential write")
    parser.add_argument('--random', const=True, action="store_const", help="random write")
    parser.add_argument('--addr-end', default="10", help="number to end")
    parser.add_argument('--addr-start', default="0", help="where to start")
    parser.add_argument('-v','--verbose', dest="verbose", action="store_const", help="verbose", const=True)
    parser.add_argument('--hex', dest="hex", action="store_const", help="output in hex", const=True)
    parser.add_argument('--value', help="what value to write")

    args = parser.parse_args()

    ser=serial.Serial()
    ser.port=args.port
    ser.baudrate=115200
    ser.timeout=1
    ser.open()

    # if hex is given, assume addr args also in hex
    base = 10
    if args.hex:
        base = 16
    args.addr_end = int(args.addr_end, base)
    args.addr_start = int(args.addr_start, base)

    if args.write and args.value:
    # check right length
        if len(args.value) / 2 != args.addr_end - args.addr_start:
            exit("value is unexpected length %d - should be %d" % (len(args.value) / 2, args.addr_end - args.addr_start))


    index = 0
    try:
        for addr in range(args.addr_start, args.addr_end):

            if args.sequential:
                number = addr % 255
            elif args.random:
                number = random.randint(0,255)
            elif args.value:
                byte = args.value[index:index+2]
                number = int(byte,16)
                index += 2
            else:
                if args.write:
                    exit("must give sequential or random argument")

            data = cmd('ADDR', addr)
            if args.write:
                cmd('LOAD', number)
                cmd('WRITE')
                if args.hex:
                    print("%04x %02x" % (addr, number))
                else:
                    print("%d %d" % (addr, number))
            if args.read:
                cmd('READ_REQ')
                read_data = cmd('READ')
                if args.hex:
                    print("%04x %02x" % (addr, read_data))
                else:
                    print("%d %d" % (addr, read_data))

            if args.read and args.write:
                if(read_data == number):
                    pass
                else:
                    print("failed at addr %d, was %d" % (addr, read_data))

    except KeyboardInterrupt as e:
        print("quitting")
        print(addr)
