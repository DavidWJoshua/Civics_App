package leave_management

import (
	"context"
	"log"
	"sort"
)

type Service struct {
	Repo *Repository
}

func (s *Service) ApplyLeave(ctx context.Context, req *LeaveRequest) error {
	return s.Repo.CreateLeaveRequest(ctx, req)
}

func (s *Service) GetPendingLeaves(ctx context.Context) ([]LeaveRequest, error) {
	return s.Repo.GetPendingLeaves(ctx)
}

func (s *Service) GetLeaveHistory(ctx context.Context, officerID string) ([]LeaveRequest, error) {
	return s.Repo.GetLeaveHistory(ctx, officerID)
}

func (s *Service) ApproveLeave(ctx context.Context, leaveID string, approverID string) error {
	// 1. Update status to APPROVED
	err := s.Repo.UpdateLeaveStatus(ctx, leaveID, "APPROVED", approverID)
	if err != nil {
		return err
	}

	// 2. Trigger Reassignment
	go s.ReassignComplaintsForLeave(context.Background(), leaveID)
	return nil
}

func (s *Service) RejectLeave(ctx context.Context, leaveID string, approverID string) error {
	return s.Repo.UpdateLeaveStatus(ctx, leaveID, "REJECTED", approverID)
}

func (s *Service) ReassignComplaintsForLeave(ctx context.Context, leaveID string) {
	// Fetch Leave details
	leave, err := s.Repo.GetLeaveRequest(ctx, leaveID)
	if err != nil {
		log.Printf("❌ Failed to fetch leave %s: %v", leaveID, err)
		return
	}

	officerID := leave.OfficerID
	log.Printf("🔄 Starting reassignment for officer %s (Leave %s)", officerID, leaveID)

	// Get active complaints
	complaintIDs, err := s.Repo.GetActiveComplaintsForOfficer(ctx, officerID)
	if err != nil {
		log.Printf("❌ Failed to fetch active complaints: %v", err)
		return
	}

	if len(complaintIDs) == 0 {
		log.Println("✅ No active complaints to reassign.")
		return
	}

	// Track in-memory load to ensure balanced assignment during this batch
	inMemoryLoad := make(map[string]int)

	for _, compID := range complaintIDs {
		// 1. Get Ward of complaint
		ward, err := s.Repo.GetComplaintWard(ctx, compID)
		if err != nil {
			log.Printf("⚠️ Failed to get ward for complaint %s: %v", compID, err)
			continue
		}

		// 2. Find Eligible Officers for this Ward
		eligibleOfficers, err := s.Repo.GetEligibleOfficers(ctx, officerID, ward)
		if err != nil || len(eligibleOfficers) == 0 {
			log.Printf("⚠️ No eligible officers found for complaint %s (Ward %d)", compID, ward)
			continue
		}

		// 3. Adjust Load with in-memory counts
		for i := range eligibleOfficers {
			eligibleOfficers[i].ActiveCount += inMemoryLoad[eligibleOfficers[i].OfficerID]
		}

		// 4. Sort: Least Active Count -> Lowest Severity Weight
		sort.Slice(eligibleOfficers, func(i, j int) bool {
			if eligibleOfficers[i].ActiveCount != eligibleOfficers[j].ActiveCount {
				return eligibleOfficers[i].ActiveCount < eligibleOfficers[j].ActiveCount
			}
			return eligibleOfficers[i].SeverityWeight < eligibleOfficers[j].SeverityWeight
		})

		targetOfficer := eligibleOfficers[0]

		// 5. Perform Reassignment
		err = s.Repo.ReassignComplaint(ctx, compID, officerID, targetOfficer.OfficerID, "Reassignment due to approved leave")
		if err != nil {
			log.Printf("❌ Failed to reassign complaint %s: %v", compID, err)
			continue
		}

		log.Printf("✅ Reassigned complaint %s (Ward %d) to %s", compID, ward, targetOfficer.OfficerID)

		// 6. Update in-memory load
		inMemoryLoad[targetOfficer.OfficerID]++
	}
}
