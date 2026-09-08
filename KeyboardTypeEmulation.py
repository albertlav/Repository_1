text=r"""
Keyboard input emulation for linux uinput

use:
paste whatever you need to type here, replacing this text, 
or provide text to type to script stdin with '-' arg like this: $ sudo sh -c "cat mytext.txt | python3 KeyboardTypeEmulation.py -"
run with sudo as we need access to /dev/uinput
get focus to the window/terminal where you need to type it in 5 seconds

tune CR/LF handling for your needs by (un)commenting or changing relevant line
tune delay between keypresses to your needs. 
50 ms works fine generally for typing something complex (hugeoneliners, multiline code/script, base64 encoded binary data, etc) to BMC console or remote screensharing

"""


import os
import sys
import struct
import fcntl
import time

delay_ms=50
start_delay=5
keymap={'1': (2, 0), '!': (2, 1), '2': (3, 0), '@': (3, 1), '3': (4, 0), '#': (4, 1), '4': (5, 0), '$': (5, 1), '5': (6, 0), '%': (6, 1), '6': (7, 0), '^': (7, 1), '7': (8, 0), '&': (8, 1), '8': (9, 0), '*': (9, 1), '9': (10, 0), '(': (10, 1), '0': (11, 0), ')': (11, 1), '-': (12, 0), '_': (12, 1), '=': (13, 0), '+': (13, 1), 'q': (16, 0), 'Q': (16, 1), 'w': (17, 0), 'W': (17, 1), 'e': (18, 0), 'E': (18, 1), 'r': (19, 0), 'R': (19, 1), 't': (20, 0), 'T': (20, 1), 'y': (21, 0), 'Y': (21, 1), 'u': (22, 0), 'U': (22, 1), 'i': (23, 0), 'I': (23, 1), 'o': (24, 0), 'O': (24, 1), 'p': (25, 0), 'P': (25, 1), '[': (26, 0), '{': (26, 1), ']': (27, 0), '}': (27, 1), 'a': (30, 0), 'A': (30, 1), 's': (31, 0), 'S': (31, 1), 'd': (32, 0), 'D': (32, 1), 'f': (33, 0), 'F': (33, 1), 'g': (34, 0), 'G': (34, 1), 'h': (35, 0), 'H': (35, 1), 'j': (36, 0), 'J': (36, 1), 'k': (37, 0), 'K': (37, 1), 'l': (38, 0), 'L': (38, 1), ';': (39, 0), ':': (39, 1), "'": (40, 0), '"': (40, 1), '`': (41, 0), '~': (41, 1), '\\': (43, 0), '|': (43, 1), 'z': (44, 0), 'Z': (44, 1), 'x': (45, 0), 'X': (45, 1), 'c': (46, 0), 'C': (46, 1), 'v': (47, 0), 'V': (47, 1), 'b': (48, 0), 'B': (48, 1), 'n': (49, 0), 'N': (49, 1), 'm': (50, 0), 'M': (50, 1), ',': (51, 0), '<': (51, 1), '.': (52, 0), '>': (52, 1), '/': (53, 0), '?': (53, 1), ' ': (57, 0), '\t': (15, 0), '\n': (28, 0)}

def send_key(fd, keycode, value):
    data = struct.Struct("@llHHi").pack(0, 0, 1, keycode, value)
    data += struct.Struct("@llHHi").pack(0, 0, 0, 0, 0)
    os.write(fd, data)

if len(sys.argv) == 2 and sys.argv[1] == '-':
    text = sys.stdin.buffer.read().decode("utf-8-sig")
text = text.replace("\r\n", "\n").replace("\r", "\n").removesuffix("\n") # CR/LF handling and trailing CR
print("Typing",len(text),"characters with",delay_ms,"ms between keypresses. It will take",(len(text)*delay_ms)/1000/60,"minutes. You have",start_delay,"seconds to get UI focus the target console/window\n")

fd = os.open("/dev/uinput", os.O_WRONLY | os.O_CLOEXEC)
fcntl.ioctl(fd, 0x40045564, 1)
for code in range(1, 84):
    fcntl.ioctl(fd, 0x40045565, code)
fcntl.ioctl(fd, 0x405C5503, struct.Struct("@HHHH80sI").pack(0x06, 0, 0, 1, b"kbd", 0))
fcntl.ioctl(fd, 0x5501)

time.sleep(start_delay)
for char in text:
    code, shifted = keymap[char]
    if shifted:
        send_key(fd, 42, 1)
        send_key(fd, code, 1)
        send_key(fd, code, 0)
        send_key(fd, 42, 0)
    else:
        send_key(fd, code, 1)
        send_key(fd, code, 0)
    time.sleep(delay_ms / 1000)
print("Done")
