package spatial

import (
	"encoding/json"
	"log"
	"math"
	"os"
)

type WardPolygon struct {
	Ward    string      `json:"ward"`
	Polygon [][]float64 `json:"polygon"` // [longitude, latitude]
}

var wards []WardPolygon

// LoadWards parses the extracted JSON wards bounding
func LoadWards(filePath string) error {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}
	err = json.Unmarshal(data, &wards)
	if err != nil {
		return err
	}
	log.Printf("Loaded %d wards for spatial location", len(wards))
	return nil
}

// GetWardFromPoint takes latitude and longitude and returns the ward name.
// First it tries exact polygon intersection.
// If not found, it falls back to finding the closest ward perfectly.
func GetWardFromPoint(lat, lng float64) string {
	for _, w := range wards {
		if isPointInPolygon(lng, lat, w.Polygon) {
			return w.Ward
		}
	}

	// Fallback logic for when the user is technically outside the city limits 
	// or the KML boundaries strictly (e.g., margins of error or GPS drift).
	return getClosestWard(lat, lng)
}

func getClosestWard(lat, lng float64) string {
	if len(wards) == 0 {
		return ""
	}

	closestWard := ""
	minDist := math.MaxFloat64

	for _, w := range wards {
		for _, pt := range w.Polygon {
			// pt[0] is longitude, pt[1] is latitude
			x, y := pt[0], pt[1]
			
			dist := math.Hypot(x-lng, y-lat)
			if dist < minDist {
				minDist = dist
				closestWard = w.Ward
			}
		}
	}
	return closestWard
}

// Ray-casting algorithm
func isPointInPolygon(lng, lat float64, polygon [][]float64) bool {
	inside := false
	j := len(polygon) - 1
	for i := 0; i < len(polygon); i++ {
		xi, yi := polygon[i][0], polygon[i][1]
		xj, yj := polygon[j][0], polygon[j][1]

		intersect := ((yi > lat) != (yj > lat)) &&
			(lng < (xj-xi)*(lat-yi)/(yj-yi)+xi)
		if intersect {
			inside = !inside
		}
		j = i
	}
	return inside
}
