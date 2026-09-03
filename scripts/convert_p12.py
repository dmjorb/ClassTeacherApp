"""Convert the signing p12 to a standard PKCS12 format that macOS security can import.
Run from the workflow working directory where cert.p12 exists.
"""
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.hazmat.primitives.serialization.pkcs12 import serialize_key_and_certificates
from cryptography.hazmat.primitives.serialization import BestAvailableEncryption

with open('cert.p12', 'rb') as f:
    key, cert, extra = pkcs12.load_key_and_certificates(f.read(), b'')

out = serialize_key_and_certificates(b'key', key, cert, extra, BestAvailableEncryption(b''))
with open('cert_fixed.p12', 'wb') as f:
    f.write(out)
print('p12 converted to standard format')
