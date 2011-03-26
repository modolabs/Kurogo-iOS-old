#!/usr/bin/python

# we will take a hash signature and create a 4x4 grid
# of squares each of which is 16x16 pixels

num_squares = 4 * 4
square_size = 8 # must be even!

import sys
import zlib

def split_bytes(num):
    result = []
    result.append((num >> 24) & 255)
    result.append((num >> 16) & 255)
    result.append((num >> 8) & 255)
    result.append(num & 255)
    return result

def len_bytes(data):
    return "".join([chr(b) for b in split_bytes(len(data))])

def crc_bytes(data):
    return "".join([chr(b) for b in split_bytes(zlib.crc32(data))])

if len(sys.argv) > 1:
    githash = sys.argv[1]

max_hash_len = num_squares * 3 # 3 for r/g/b

while len(githash) < max_hash_len:
    githash += githash

githash = githash[0 : max_hash_len]

outfile = open('githash.png', 'wb')

# PNG signature
for b in [137, 80, 78, 71, 13, 10, 26, 10]:
    outfile.write(chr(b))

# image header
header_chunk = "IHDR"

width = [0, 0, 0, square_size*4]
height = [0, 0, 0, square_size*4]
# bit depth = 4, color type = indexed
# compression method, filter method (only 0 allowed for both)
# interlaced method = no interlace
flags = [4, 3, 0, 0, 0]

header_data = "".join([chr(b) for b in width + height + flags])

outfile.write(len_bytes(header_data))
outfile.write(header_chunk)
outfile.write(header_data)
outfile.write(crc_bytes(header_chunk + header_data))

# palette
header_chunk = "PLTE"

# 97 === (48 + 10) === 9 (mod 39)
palette = "".join([chr(((ord(x) % 39) - 9) * 16) for x in githash])

outfile.write(len_bytes(palette))
outfile.write(header_chunk)

outfile.write(palette)
outfile.write(crc_bytes(header_chunk + palette))

# image data
header_chunk = "IDAT"

scanlines = []
for row in range(4):
    for scanline in range(square_size):
        scanlines.append("\x00")
        for col in range(4):
            pixel = row * 4 + col
            scanlines.append(chr(pixel * 16 + pixel)*(square_size/2))

image_data = zlib.compress("".join(scanlines))

outfile.write(len_bytes(image_data))
outfile.write(header_chunk)
outfile.write(image_data)
outfile.write(crc_bytes(header_chunk + image_data))

# IEND chunk
header_chunk = "IEND"

outfile.write(len_bytes(""))
outfile.write(header_chunk)
outfile.write(crc_bytes(header_chunk))


