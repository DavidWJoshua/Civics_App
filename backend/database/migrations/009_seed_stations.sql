-- Seed Stations
INSERT INTO stations (name, type, ward_number, capacity, process_type) VALUES
-- Lifting Stations (1-4)
('Lifting Station 1', 'lifting', 'Ward 1', 5.0, NULL),
('Lifting Station 2', 'lifting', 'Ward 2', 4.5, NULL),
('Lifting Station 3', 'lifting', 'Ward 3', 6.0, NULL),
('Lifting Station 4', 'lifting', 'Ward 4', 5.5, NULL),
-- Pumping Stations (1-3)
('Pumping Station 1', 'pumping', 'Ward 5', 10.0, NULL),
('Pumping Station 2', 'pumping', 'Ward 6', 12.0, NULL),
('Pumping Station 3', 'pumping', 'Ward 7', 8.0, NULL),
-- STP Stations (1-2)
('STP Station 1', 'stp', 'Ward 10', 20.0, 'ASP'),
('STP Station 2', 'stp', 'Ward 11', 25.0, 'SBR')
ON CONFLICT DO NOTHING;

-- Seed Equipment (Example: 1 Pump per station for simplicity)
INSERT INTO equipment (station_id, name, type, details) 
SELECT id, 'Pump 1', 'pump', '{"power": "10HP", "make": "Kirloskar"}'::jsonb 
FROM stations WHERE type IN ('lifting', 'pumping')
ON CONFLICT DO NOTHING;

INSERT INTO equipment (station_id, name, type, details) 
SELECT id, 'Motor 1', 'motor', '{"power": "15HP", "make": "Siemens"}'::jsonb 
FROM stations WHERE type IN ('lifting', 'pumping')
ON CONFLICT DO NOTHING;

-- STP Equipment
INSERT INTO equipment (station_id, name, type, details) 
SELECT id, 'Blower 1', 'blower', '{"capacity": "500cfm"}'::jsonb 
FROM stations WHERE type = 'stp'
ON CONFLICT DO NOTHING;

INSERT INTO equipment (station_id, name, type, details) 
SELECT id, 'Clarifier 1', 'clarifier', '{"diameter": "20m"}'::jsonb 
FROM stations WHERE type = 'stp'
ON CONFLICT DO NOTHING;
