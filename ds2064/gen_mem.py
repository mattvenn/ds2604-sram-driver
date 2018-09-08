v = 0
for i in range(2**13):
    print("%02x" % v)
    v += 1
    if v == 256:
        v = 0
