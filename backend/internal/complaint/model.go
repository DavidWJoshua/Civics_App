package complaint

import "time"

type Complaint struct {
	ID                 string                 `json:"id"`
	CitizenID          string                 `json:"citizen_id"`
	Category           string                 `json:"category"`
	Severity           string                 `json:"severity"`
	Latitude           float64                `json:"latitude"`
	Longitude          float64                `json:"longitude"`
	Street             string                 `json:"street"`
	Area               string                 `json:"area"`
	Ward               string                 `json:"ward"`
	City               string                 `json:"city"`
	Location           map[string]interface{} `json:"location"`
	ImageURL           string                 `json:"image_url"`
	CompletionImageURL string                 `json:"completion_image_url"`
	Status             string                 `json:"status"`
	Rating             int                    `json:"rating,omitempty"`
	FeedbackText       string                 `json:"feedback_text,omitempty"`
	CreatedAt          time.Time              `json:"created_at"`
}
