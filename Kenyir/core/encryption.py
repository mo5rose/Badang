# kenyir/core/encryption.py
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad
import base64

key = b'16-byte-secret-key'
iv = b'16-byte-secret-iv'

def encrypt(data):
    cipher = AES.new(key, AES.MODE_CBC, iv)
    ct_bytes = cipher.encrypt(pad(data.encode(), AES.block_size))
    return base64.b64encode(ct_bytes).decode()

def decrypt(ct):
    ct = base64.b64decode(ct)
    cipher = AES.new(key, AES.MODE_CBC, iv)
    pt = unpad(cipher.decrypt(ct), AES.block_size)
    return pt.decode()