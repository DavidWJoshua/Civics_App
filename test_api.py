import requests
import json

url = "http://localhost:8080/api/auth/citizen/verify-otp"
response = requests.post(url, json={"phone_number": "+919999999901", "otp": "000000"})
if "token" in response.json():
    print("Logged in!")
    token = response.json()["token"]
else:
    # Use a dummy token logic just for the script, but we need Auth. Let's use any login endpoint if it exists.
    pass
