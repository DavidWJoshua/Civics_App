import json
import math

with open('backend/resources/wards.json', 'r') as f:
    wards = json.load(f)

lat = 9.4826809
lng = 77.5149783

min_dist = float('inf')
closest_ward = None

for w in wards:
    for pt in w['polygon']:
        x, y = pt[0], pt[1] # lng, lat
        dist = math.hypot(x - lng, y - lat)
        if dist < min_dist:
            min_dist = dist
            closest_ward = w['ward']

print(f"Distance to closest ward {closest_ward} is {min_dist} degrees. (~{min_dist * 111} km)")
