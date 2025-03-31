# pip install PyQt6

import sys
import termios
import json
from PyQt6.QtCore import *


def unpack(s):
  ba = QByteArray(s[6:].encode())
  ba = QByteArray.fromBase64(ba, QByteArray.Base64Option.Base64UrlEncoding | QByteArray.Base64Option.OmitTrailingEquals)
  return str(qUncompress(ba), 'utf-8')

def pack(s):
  try:
    json.loads(s)
  except Exception as e:
    return 'ERROR: ' + str(e)
  ba = qCompress(QByteArray(s.encode()))
  ba = ba.toBase64(QByteArray.Base64Option.Base64UrlEncoding | QByteArray.Base64Option.OmitTrailingEquals)
  return 'vpn://' + str(ba, 'utf-8')

lines = []
# allow to get lines loner than 4096
fd = sys.stdin.fileno()
old = termios.tcgetattr(fd)
new = termios.tcgetattr(fd)
new[3] = new[3] & ~termios.ICANON
termios.tcsetattr(fd, termios.TCSADRAIN, new)
while True:
  try:
    line = input()
    if line == '':
      break
  except EOFError:
    break
  lines.append(line)
termios.tcsetattr(fd, termios.TCSADRAIN, old)
lines = '\n'.join(lines).strip()

if lines.startswith('vpn://'):
  print(unpack(lines))
else:
  print(pack(lines))

