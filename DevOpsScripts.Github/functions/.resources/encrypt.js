const sodium = require(`${process.env.APPDATA}/npm/node_modules/sodium-native`)

const secretValue = process.argv[2]
const publicKey = process.argv[3]

const secretBuffer = Buffer.from(secretValue, 'utf-8')
const publicKeyBuffer = Buffer.from(publicKey, 'base64')

const ciphertext = Buffer.allocUnsafe(sodium.crypto_box_SEALBYTES + secretBuffer.length)

sodium.crypto_box_seal(ciphertext, secretBuffer, publicKeyBuffer)

const sealedBoxBase64 = ciphertext.toString('base64')

console.log(sealedBoxBase64)
return sealedBoxBase64