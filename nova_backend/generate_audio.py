import urllib.request
import base64
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

url = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req, context=ctx) as response:
    audio_data = response.read(60000)

encoded = base64.b64encode(audio_data).decode('utf-8')
with open('base64_audio.txt', 'w') as f:
    f.write(encoded)
print("Saved 60KB audio base64")
