import json

def isPointInPolygon(lng, lat, polygon):
    inside = False
    j = len(polygon) - 1
    for i in range(len(polygon)):
        xi, yi = polygon[i][0], polygon[i][1]
        xj, yj = polygon[j][0], polygon[j][1]
        
        intersect = ((yi > lat) != (yj > lat)) and (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi)
        if intersect:
            inside = not inside
        j = i
    return inside

with open('backend/resources/wards.json', 'r') as f:
    wards = json.load(f)

lat = 9.4826809
lng = 77.5149783

found = False
for w in wards:
    if isPointInPolygon(lng, lat, w['polygon']):
        print(f"Found inside Ward: {w['ward']}")
        found = True

if not found:
    print("Point is not inside any ward polygon!")
