#!/usr/bin/env ruby
require 'base64'
require 'openssl'

def bn_output(bn)
	hex = bn.to_s(16)
	raw = [hex].pack("H*")
	b64 = Base64.strict_encode64(raw)
	return b64
end

def bn_input(str)
	b64 = str
	raw = Base64.decode64(str)
	hex = raw.unpack("H*")[0]
	OpenSSL::BN.new(hex, 16)
end

def buf_to_hex(buf)
	buf.unpack("H*")[0]
end

params = <<EOF
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEAtp9N1rD42nLs1Jsj72RTYmY2FL9S3844VgIpwE+xOfiA2PGNNC2W
mpH4pfBlPEtBR20wpZe6pIGOGeQByImwedYqvFG7azKVyhA+cwrKa63O6Mz6rSzH
pF8uk6lBLvbgvVQeSAImavnc9bsJ1k3+8/CteCiindUu6Njw7KHAjYq8S1vQSfDL
U0BQnV5mdbI7WvJ/rkDzLTa9DDEvHk+W3bMDCTNWJf4I10Vlz3UM+fbozpxAkfnm
yb4R9IjvvZywjDmgQX8pmY7sOhAE+gb7/5I27NGlVQrSt9xEpgxethmGlMOTR5fu
5/rkR/oeqjqxLzy/ebLXL+t2G9b9GXwJSwIBAg==
-----END DH PARAMETERS-----
EOF

other_public = nil

dh = OpenSSL::PKey::DH.new(params)

dh.generate_key!

puts "my public key: \e[32m#{bn_output(dh.pub_key)}\e[m"

if other_public.nil?
	print "their public key? "
	STDOUT.flush
	other_public = bn_input(gets)
end

secret = dh.compute_key(other_public)

puts "shared secret: \e[31m#{buf_to_hex(secret)}\e[m"

hash = OpenSSL::Digest::SHA1.digest(secret)

puts "hash of secret: \e[33m#{buf_to_hex(hash)}\e[m"
