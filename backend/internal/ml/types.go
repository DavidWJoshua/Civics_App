package ml

type PredictResponse struct {
	Category string `json:"category"`
	Severity string `json:"severity"`
	Error    string `json:"error,omitempty"`
}