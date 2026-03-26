import xml.etree.ElementTree as ET
import json
import re

def parse_kml(file_path, out_path):
    tree = ET.parse(file_path)
    root = tree.getroot()
    # KML usually has namespaces
    namespaces = {'kml': 'http://www.opengis.net/kml/2.2', 'gx': 'http://www.google.com/kml/ext/2.2'}
    
    # Sometimes default namespace doesn't need to be defined this way if we use iter()
    
    wards = []
    
    # Let's just find all Placemarks
    for placemark in root.iter('{http://www.opengis.net/kml/2.2}Placemark'):
        name_elem = placemark.find('{http://www.opengis.net/kml/2.2}name')
        if name_elem is None:
            name_elem = placemark.find('.//{http://www.opengis.net/kml/2.2}SimpleData[@name="Name"]')
            
        name = name_elem.text if name_elem is not None else "Unknown"
        
        # Some KMLs store name differently, let's just dump whatever text looks like word
        if name == "Unknown":
             extended_data = placemark.find('{http://www.opengis.net/kml/2.2}ExtendedData')
             if extended_data is not None:
                 for simple_data in extended_data.iter('{http://www.opengis.net/kml/2.2}SimpleData'):
                     if 'ward' in simple_data.attrib.get('name', '').lower() or 'name' in simple_data.attrib.get('name', '').lower():
                         name = simple_data.text
                         break

        coords = placemark.find('.//{http://www.opengis.net/kml/2.2}coordinates')
        if coords is not None:
            coord_text = coords.text.strip()
            # Coordinates are usually lon,lat,alt lon,lat,alt
            points = []
            for pt in coord_text.split():
                if ',' in pt:
                    parts = pt.split(',')
                    points.append([float(parts[0]), float(parts[1])]) # lon, lat
            
            wards.append({
                'ward': str(name).strip() if name else "Unknown",
                'polygon': points
            })

    # write to JSON
    with open(out_path, 'w') as f:
        json.dump(wards, f, indent=2)

if __name__ == '__main__':
    parse_kml('Ward Boundary.kml', 'wards_extracted.json')
    print("Extraction done.")
