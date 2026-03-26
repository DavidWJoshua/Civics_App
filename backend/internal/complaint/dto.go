package complaint

type CreateComplaintRequest struct {
	Category  string                 `json:"category" binding:"required"`
	Severity  string                 `json:"severity" binding:"required"`
	Latitude  float64                `json:"latitude"`
	Longitude float64                `json:"longitude"`
	Street    string                 `json:"street"`
	Area      string                 `json:"area"`
	Ward      string                 `json:"ward"`
	City      string                 `json:"city"`
	Location  map[string]interface{} `json:"location" binding:"required"`
	ImageURL  string                 `json:"-"`
}

type CreateComplaintResponse struct {
	ComplaintID string `json:"complaint_id"`
	Status      string `json:"status"`
	Message     string `json:"message"`
}

type SubmitFeedbackRequest struct {
	Rating       int    `json:"rating" binding:"required,min=1,max=5"`
	FeedbackText string `json:"feedback_text"`
}
