-- Create the database
CREATE DATABASE SmartTransportSystem;
USE SmartTransportSystem;

-- Create tables with proper normalization
-- 1. Core Entities
CREATE TABLE VehicleTypes (
    VehicleTypeID INT PRIMARY KEY AUTO_INCREMENT,
    TypeName VARCHAR(50) NOT NULL,
    Capacity INT NOT NULL,
    Description VARCHAR(200)
);

CREATE TABLE Vehicles (
    VehicleID INT PRIMARY KEY AUTO_INCREMENT,
    VehicleTypeID INT NOT NULL,
    RegistrationNumber VARCHAR(20) UNIQUE NOT NULL,
    ManufactureYear INT,
    LastMaintenanceDate DATE,
    Status ENUM('Active', 'Maintenance', 'Retired') NOT NULL,
    FOREIGN KEY (VehicleTypeID) REFERENCES VehicleTypes(VehicleTypeID)
);

CREATE TABLE Passengers (
    PassengerID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(20),
    RegistrationDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    LastLogin DATETIME,
    AnonymizedIdentifier CHAR(36) DEFAULT (UUID()) UNIQUE
);

CREATE TABLE Zones (
    ZoneID INT PRIMARY KEY AUTO_INCREMENT,
    ZoneName VARCHAR(50) NOT NULL,
    BaseFare DECIMAL(10,2) NOT NULL
);

CREATE TABLE Stops (
    StopID INT PRIMARY KEY AUTO_INCREMENT,
    StopName VARCHAR(100) NOT NULL,
    ZoneID INT NOT NULL,
    Latitude DECIMAL(9,6) NOT NULL,
    Longitude DECIMAL(9,6) NOT NULL,
    FOREIGN KEY (ZoneID) REFERENCES Zones(ZoneID)
);

-- 2. Route Management
CREATE TABLE Routes (
    RouteID INT PRIMARY KEY AUTO_INCREMENT,
    RouteName VARCHAR(100) NOT NULL,
    StartStopID INT NOT NULL,
    EndStopID INT NOT NULL,
    AverageDurationMinutes INT,
    Status ENUM('Active', 'Inactive', 'Under Maintenance') DEFAULT 'Active',
    FOREIGN KEY (StartStopID) REFERENCES Stops(StopID),
    FOREIGN KEY (EndStopID) REFERENCES Stops(StopID)
);

CREATE TABLE RouteStops (
    RouteStopID INT PRIMARY KEY AUTO_INCREMENT,
    RouteID INT NOT NULL,
    StopID INT NOT NULL,
    SequenceNumber INT NOT NULL,
    EstimatedTimeToNextStop INT, -- in minutes
    FOREIGN KEY (RouteID) REFERENCES Routes(RouteID),
    FOREIGN KEY (StopID) REFERENCES Stops(StopID),
    UNIQUE KEY (RouteID, SequenceNumber)
);

CREATE TABLE Schedules (
    ScheduleID INT PRIMARY KEY AUTO_INCREMENT,
    RouteID INT NOT NULL,
    VehicleID INT NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    RecurrencePattern VARCHAR(50), -- e.g., "Weekdays", "Weekend", "Daily"
    Status ENUM('Active', 'Inactive') DEFAULT 'Active',
    FOREIGN KEY (RouteID) REFERENCES Routes(RouteID),
    FOREIGN KEY (VehicleID) REFERENCES Vehicles(VehicleID)
);

-- 3. Real-time Tracking
CREATE TABLE VehiclePositions (
    PositionID BIGINT PRIMARY KEY AUTO_INCREMENT,
    VehicleID INT NOT NULL,
    Timestamp DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    Latitude DECIMAL(9,6) NOT NULL,
    Longitude DECIMAL(9,6) NOT NULL,
    Speed DECIMAL(6,2),
    Bearing DECIMAL(5,2),
    FOREIGN KEY (VehicleID) REFERENCES Vehicles(VehicleID)
);

CREATE TABLE VehicleStatusLog (
    LogID BIGINT PRIMARY KEY AUTO_INCREMENT,
    VehicleID INT NOT NULL,
    Status VARCHAR(50) NOT NULL,
    Timestamp DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    FOREIGN KEY (VehicleID) REFERENCES Vehicles(VehicleID)
);

-- 4. Ticketing and Payments
CREATE TABLE TicketTypes (
    TicketTypeID INT PRIMARY KEY AUTO_INCREMENT,
    TypeName VARCHAR(50) NOT NULL,
    Description VARCHAR(200),
    ValidityHours INT,
    IsTransferable TINYINT(1) DEFAULT 0
);

CREATE TABLE DynamicPricingRules (
    RuleID INT PRIMARY KEY AUTO_INCREMENT,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    DayType VARCHAR(20) NOT NULL, -- Weekday, Weekend, Holiday
    Multiplier DECIMAL(3,2) NOT NULL,
    Description VARCHAR(200)
);

CREATE TABLE Tickets (
    TicketID BIGINT PRIMARY KEY AUTO_INCREMENT,
    PassengerID INT NOT NULL,
    TicketTypeID INT NOT NULL,
    PurchaseDateTime DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    ValidFrom DATETIME(6) NOT NULL,
    ValidTo DATETIME(6) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    PaymentMethod VARCHAR(50),
    PaymentStatus VARCHAR(20) DEFAULT 'Completed',
    FOREIGN KEY (PassengerID) REFERENCES Passengers(PassengerID),
    FOREIGN KEY (TicketTypeID) REFERENCES TicketTypes(TicketTypeID)
);

CREATE TABLE TripRecords (
    TripID BIGINT PRIMARY KEY AUTO_INCREMENT,
    TicketID BIGINT NOT NULL,
    VehicleID INT NOT NULL,
    BoardingStopID INT NOT NULL,
    AlightingStopID INT NOT NULL,
    BoardingTime DATETIME(6) NOT NULL,
    AlightingTime DATETIME(6),
    FareCharged DECIMAL(10,2),
    FOREIGN KEY (TicketID) REFERENCES Tickets(TicketID),
    FOREIGN KEY (VehicleID) REFERENCES Vehicles(VehicleID),
    FOREIGN KEY (BoardingStopID) REFERENCES Stops(StopID),
    FOREIGN KEY (AlightingStopID) REFERENCES Stops(StopID)
);

-- 5. Analytics and Reporting
CREATE TABLE DailyRouteAnalytics (
    AnalyticsID INT PRIMARY KEY AUTO_INCREMENT,
    RouteID INT NOT NULL,
    AnalysisDate DATE NOT NULL,
    TotalPassengers INT NOT NULL,
    AverageTravelTime DECIMAL(10,2),
    PeakHour VARCHAR(20),
    Revenue DECIMAL(15,2) NOT NULL,
    FOREIGN KEY (RouteID) REFERENCES Routes(RouteID),
    UNIQUE KEY (RouteID, AnalysisDate)
);

CREATE TABLE VehicleUtilization (
    UtilizationID INT PRIMARY KEY AUTO_INCREMENT,
    VehicleID INT NOT NULL,
    AnalysisDate DATE NOT NULL,
    TotalDistance DECIMAL(10,2),
    TotalHoursOperated DECIMAL(10,2),
    PassengerCount INT,
    FOREIGN KEY (VehicleID) REFERENCES Vehicles(VehicleID),
    UNIQUE KEY (VehicleID, AnalysisDate)
);


-- Create indexes to optimize query performance
CREATE INDEX idx_VehiclePositions_VehicleID_Timestamp ON VehiclePositions(VehicleID, Timestamp DESC);
CREATE INDEX idx_TripRecords_TicketID ON TripRecords(TicketID);
CREATE INDEX idx_TripRecords_VehicleID_BoardingTime ON TripRecords(VehicleID, BoardingTime);
CREATE INDEX idx_Schedules_RouteID_StartTime ON Schedules(RouteID, StartTime);
CREATE INDEX idx_RouteStops_RouteID_SequenceNumber ON RouteStops(RouteID, SequenceNumber);
CREATE INDEX idx_Tickets_PassengerID_ValidTo ON Tickets(PassengerID, ValidTo);
CREATE INDEX idx_Vehicles_Status ON Vehicles(Status);


-- VehicleTypes
INSERT INTO VehicleTypes (TypeName, Capacity, Description) VALUES 
('Standard Bus', 50, 'Regular city bus with seating for 30 and standing room for 20'),
('Articulated Bus', 80, 'Extra-long bus with flexible middle section for high-capacity routes'),
('Electric Minibus', 20, 'Small eco-friendly vehicle for low-demand routes'),
('Express Coach', 45, 'Comfortable long-distance bus with luggage storage'),
('Tram', 120, 'Light rail vehicle for urban transit');

-- Vehicles
INSERT INTO Vehicles (VehicleTypeID, RegistrationNumber, ManufactureYear, LastMaintenanceDate, Status) VALUES 
(1, 'BUS001', 2020, '2023-06-15', 'Active'),
(1, 'BUS002', 2019, '2023-05-20', 'Active'),
(2, 'BUS101', 2021, '2023-06-01', 'Active'),
(3, 'MINI01', 2022, '2023-06-10', 'Maintenance'),
(4, 'EXP201', 2020, '2023-05-30', 'Active'),
(5, 'TRAM01', 2018, '2023-04-15', 'Active');

-- Zones
INSERT INTO Zones (ZoneName, BaseFare) VALUES 
('Central Business District', 2.50),
('Inner City', 2.00),
('Suburban', 1.50),
('Outer Suburban', 1.00),
('Airport Zone', 3.50);

-- Stops
INSERT INTO Stops (StopName, ZoneID, Latitude, Longitude) VALUES 
('Main Station', 1, 34.052235, -118.243683),
('City Hall', 1, 34.053490, -118.245320),
('University', 2, 34.028556, -118.287000),
('Westfield Mall', 2, 34.041345, -118.256789),
('Green Park', 3, 34.062345, -118.308765),
('Riverside', 4, 34.098765, -118.345678),
('Airport Terminal 1', 5, 34.156789, -118.456789),
('Tech Park', 3, 34.067890, -118.298765);

-- Routes
INSERT INTO Routes (RouteName, StartStopID, EndStopID, AverageDurationMinutes, Status) VALUES 
('Downtown Express', 1, 2, 15, 'Active'),
('University Loop', 3, 3, 45, 'Active'),
('Cross-City', 1, 6, 60, 'Active'),
('Airport Shuttle', 1, 7, 35, 'Active'),
('Tech Corridor', 8, 5, 25, 'Active');

-- RouteStops
INSERT INTO RouteStops (RouteID, StopID, SequenceNumber, EstimatedTimeToNextStop) VALUES 
(1, 1, 1, 5),
(1, 2, 2, 10),
(1, 4, 3, NULL),
(2, 3, 1, 8),
(2, 5, 2, 12),
(2, 8, 3, 10),
(2, 3, 4, NULL),
(3, 1, 1, 10),
(3, 2, 2, 15),
(3, 5, 3, 20),
(3, 6, 4, NULL);

-- Schedules
INSERT INTO Schedules (RouteID, VehicleID, StartTime, EndTime, RecurrencePattern, Status) VALUES 
(1, 1, '07:00:00', '19:00:00', 'Weekdays', 'Active'),
(1, 2, '08:00:00', '20:00:00', 'Weekend', 'Active'),
(2, 3, '06:30:00', '22:00:00', 'Daily', 'Active'),
(3, 5, '05:00:00', '23:00:00', 'Weekdays', 'Active'),
(4, 6, '04:00:00', '01:00:00', 'Daily', 'Active');

-- Passengers
INSERT INTO Passengers (FirstName, LastName, Email, Phone, RegistrationDate, LastLogin) VALUES 
('John', 'Smith', 'john.smith@email.com', '555-0101', '2023-01-15 08:30:00', '2023-06-20 17:45:00'),
('Maria', 'Garcia', 'maria.g@email.com', '555-0102', '2023-02-20 12:15:00', '2023-06-20 08:30:00'),
('David', 'Lee', 'david.lee@email.com', '555-0103', '2023-03-05 09:45:00', '2023-06-19 18:20:00'),
('Sarah', 'Johnson', 'sarah.j@email.com', '555-0104', '2023-01-30 14:20:00', '2023-06-20 12:15:00'),
('James', 'Wilson', 'james.w@email.com', '555-0105', '2023-04-10 16:50:00', '2023-06-18 09:30:00');

-- VehiclePositions
INSERT INTO VehiclePositions (VehicleID, Timestamp, Latitude, Longitude, Speed, Bearing) VALUES 
(1, '2023-06-20 08:15:30.123456', 34.051000, -118.242000, 25.5, 45.0),
(1, '2023-06-20 08:16:00.234567', 34.051500, -118.242500, 27.0, 47.5),
(3, '2023-06-20 08:30:15.345678', 34.029000, -118.286500, 18.2, 90.0),
(5, '2023-06-20 09:00:45.456789', 34.060000, -118.300000, 35.7, 180.0),
(6, '2023-06-20 10:15:30.567890', 34.150000, -118.450000, 50.2, 270.0);

-- VehicleStatusLog
INSERT INTO VehicleStatusLog (VehicleID, Status, Timestamp) VALUES 
(1, 'Departed Terminal', '2023-06-20 08:00:00.000000'),
(1, 'In Service', '2023-06-20 08:05:00.000000'),
(3, 'Delayed', '2023-06-20 08:25:00.000000'),
(4, 'Maintenance Started', '2023-06-20 09:00:00.000000'),
(6, 'Arrived at Airport', '2023-06-20 10:30:00.000000');

-- TicketTypes
INSERT INTO TicketTypes (TypeName, Description, ValidityHours, IsTransferable) VALUES 
('Single Ride', 'One-way trip within zone', 2, 0),
('Day Pass', 'Unlimited rides for 24 hours', 24, 1),
('Weekly Pass', 'Unlimited rides for 7 days', 168, 1),
('Airport Express', 'Special fare to/from airport', 4, 0),
('Student Monthly', 'Discounted monthly pass for students', 720, 1);

-- DynamicPricingRules
INSERT INTO DynamicPricingRules (StartTime, EndTime, DayType, Multiplier, Description) VALUES 
('07:00:00', '09:00:00', 'Weekday', 1.25, 'Morning rush hour'),
('16:00:00', '18:00:00', 'Weekday', 1.25, 'Evening rush hour'),
('00:00:00', '23:59:59', 'Holiday', 1.10, 'Holiday surcharge'),
('22:00:00', '05:00:00', 'All', 0.75, 'Night discount');

-- Tickets
INSERT INTO Tickets (PassengerID, TicketTypeID, ValidFrom, ValidTo, Price, PaymentMethod, PaymentStatus) VALUES 
(1, 2, '2023-06-20 08:00:00.000000', '2023-06-21 08:00:00.000000', 7.50, 'Credit Card', 'Completed'),
(2, 1, '2023-06-20 09:30:00.000000', '2023-06-20 11:30:00.000000', 2.50, 'Mobile App', 'Completed'),
(3, 3, '2023-06-19 00:00:00.000000', '2023-06-26 00:00:00.000000', 30.00, 'Debit Card', 'Completed'),
(4, 4, '2023-06-20 15:00:00.000000', '2023-06-20 19:00:00.000000', 5.00, 'Credit Card', 'Completed'),
(5, 5, '2023-06-01 00:00:00.000000', '2023-07-01 00:00:00.000000', 45.00, 'Bank Transfer', 'Completed');

-- TripRecords
INSERT INTO TripRecords (TicketID, VehicleID, BoardingStopID, AlightingStopID, BoardingTime, AlightingTime, FareCharged) VALUES 
(1, 1, 1, 2, '2023-06-20 08:15:00.000000', '2023-06-20 08:30:00.000000', 0.00),
(2, 3, 3, 5, '2023-06-20 09:35:00.000000', '2023-06-20 09:55:00.000000', 2.50),
(3, 5, 1, 6, '2023-06-20 17:20:00.000000', '2023-06-20 18:15:00.000000', 0.00),
(4, 6, 1, 7, '2023-06-20 15:30:00.000000', '2023-06-20 16:05:00.000000', 5.00),
(1, 2, 2, 4, '2023-06-20 12:00:00.000000', '2023-06-20 12:15:00.000000', 0.00);

-- DailyRouteAnalytics
INSERT INTO DailyRouteAnalytics (RouteID, AnalysisDate, TotalPassengers, AverageTravelTime, PeakHour, Revenue) VALUES 
(1, '2023-06-19', 450, 16.5, '08:00-09:00', 1125.00),
(2, '2023-06-19', 320, 42.3, '15:00-16:00', 800.00),
(3, '2023-06-19', 280, 58.7, '17:00-18:00', 700.00),
(4, '2023-06-19', 180, 32.1, '06:00-07:00', 900.00),
(1, '2023-06-20', 500, 15.8, '08:00-09:00', 1250.00);

-- VehicleUtilization
INSERT INTO VehicleUtilization (VehicleID, AnalysisDate, TotalDistance, TotalHoursOperated, PassengerCount) VALUES 
(1, '2023-06-19', 120.5, 8.5, 210),
(2, '2023-06-19', 95.3, 7.0, 180),
(3, '2023-06-19', 150.2, 10.2, 195),
(5, '2023-06-19', 200.7, 12.5, 240),
(6, '2023-06-19', 180.4, 10.8, 160);




DELIMITER //

-- 1. Real-time Vehicle Tracking
CREATE PROCEDURE sp_UpdateVehiclePosition(
    IN p_VehicleID INT,
    IN p_Latitude DECIMAL(9,6),
    IN p_Longitude DECIMAL(9,6),
    IN p_Speed DECIMAL(6,2),
    IN p_Bearing DECIMAL(5,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Insert new position
    INSERT INTO VehiclePositions (VehicleID, Latitude, Longitude, Speed, Bearing)
    VALUES (p_VehicleID, p_Latitude, p_Longitude, p_Speed, p_Bearing);
    
    -- Update vehicle status if needed (e.g., if speed is 0 for extended period)
    -- Additional logic can be added here
    
    COMMIT;
END //



DELIMITER //
CREATE TRIGGER update_maintenance_status
AFTER UPDATE ON Vehicles
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Active' AND OLD.Status = 'Maintenance' THEN
        UPDATE Vehicles 
        SET LastMaintenanceDate = CURDATE()
        WHERE VehicleID = NEW.VehicleID;
    END IF;
END//
DELIMITER ;


DELIMITER //
CREATE TRIGGER log_fare_changes
AFTER UPDATE ON Zones
FOR EACH ROW
BEGIN
    IF OLD.BaseFare <> NEW.BaseFare THEN
        INSERT INTO SystemLogs (LogType, Description, ChangedBy, ChangedValue)
        VALUES ('Fare Change', 
                CONCAT('Zone ', NEW.ZoneID, ' fare changed from ', OLD.BaseFare, ' to ', NEW.BaseFare),
                CURRENT_USER(),
                CONCAT('Old:', OLD.BaseFare, '|New:', NEW.BaseFare));
    END IF;
END//
DELIMITER ;








DELIMITER //
CREATE PROCEDURE CalculateRouteStatistics(IN routeId INT, IN analysisDate DATE)
BEGIN
    DECLARE avgTravelTime DECIMAL(10,2);
    DECLARE peakHour VARCHAR(20);
    DECLARE totalRevenue DECIMAL(15,2);
    
    -- Calculate average travel time
    SELECT AVG(TIMESTAMPDIFF(MINUTE, BoardingTime, AlightingTime)) INTO avgTravelTime
    FROM TripRecords
    WHERE VehicleID IN (SELECT VehicleID FROM Schedules WHERE RouteID = routeId)
    AND DATE(BoardingTime) = analysisDate;
    
    -- Find peak hour
    SELECT CONCAT(HOUR(BoardingTime), ':00-', HOUR(BoardingTime)+1, ':00') INTO peakHour
    FROM TripRecords
    WHERE VehicleID IN (SELECT VehicleID FROM Schedules WHERE RouteID = routeId)
    AND DATE(BoardingTime) = analysisDate
    GROUP BY HOUR(BoardingTime)
    ORDER BY COUNT(*) DESC
    LIMIT 1;
    
    -- Calculate total revenue
    SELECT SUM(FareCharged) INTO totalRevenue
    FROM TripRecords
    WHERE VehicleID IN (SELECT VehicleID FROM Schedules WHERE RouteID = routeId)
    AND DATE(BoardingTime) = analysisDate;
    
    -- Update analytics table
    INSERT INTO DailyRouteAnalytics (RouteID, AnalysisDate, TotalPassengers, AverageTravelTime, PeakHour, Revenue)
    VALUES (routeId, analysisDate, 
           (SELECT COUNT(*) FROM TripRecords 
            WHERE VehicleID IN (SELECT VehicleID FROM Schedules WHERE RouteID = routeId)
            AND DATE(BoardingTime) = analysisDate),
           avgTravelTime, peakHour, totalRevenue)
    ON DUPLICATE KEY UPDATE
        TotalPassengers = VALUES(TotalPassengers),
        AverageTravelTime = VALUES(AverageTravelTime),
        PeakHour = VALUES(PeakHour),
        Revenue = VALUES(Revenue);
END//
DELIMITER ;




DELIMITER //
CREATE PROCEDURE PurchaseTicket(
    IN pPassengerID INT,
    IN pTicketTypeID INT,
    IN pPaymentMethod VARCHAR(50)
)
BEGIN
    DECLARE vPrice DECIMAL(10,2);
    DECLARE vValidityHours INT;
    DECLARE vTicketID BIGINT;
    
    -- Get ticket type details
    SELECT Price, ValidityHours INTO vPrice, vValidityHours
    FROM TicketTypes
    WHERE TicketTypeID = pTicketTypeID;
    
    -- Apply dynamic pricing if applicable
    SELECT vPrice * COALESCE((
        SELECT Multiplier 
        FROM DynamicPricingRules 
        WHERE TIME(NOW()) BETWEEN StartTime AND EndTime
        AND (DayType = 
            CASE 
                WHEN DAYOFWEEK(NOW()) IN (1,7) THEN 'Weekend'
                ELSE 'Weekday'
            END
            OR DayType = 'All')
        ORDER BY Multiplier DESC
        LIMIT 1
    ), 1) INTO vPrice;
    
    -- Create ticket
    INSERT INTO Tickets (PassengerID, TicketTypeID, ValidFrom, ValidTo, Price, PaymentMethod)
    VALUES (pPassengerID, pTicketTypeID, NOW(), DATE_ADD(NOW(), INTERVAL vValidityHours HOUR), vPrice, pPaymentMethod);
    
    SET vTicketID = LAST_INSERT_ID();
    
    -- Return ticket information
    SELECT t.TicketID, tt.TypeName, t.ValidFrom, t.ValidTo, t.Price, t.PaymentMethod
    FROM Tickets t
    JOIN TicketTypes tt ON t.TicketTypeID = tt.TicketTypeID
    WHERE t.TicketID = vTicketID;
END//
DELIMITER ;


CREATE ROLE 'transport_admin', 'transport_operator', 'transport_analyst', 'transport_customer';

-- Admin (full access)
GRANT ALL PRIVILEGES ON SmartTransportSystem.* TO 'transport_admin';

-- Operator (daily operations)
GRANT SELECT, INSERT, UPDATE ON SmartTransportSystem.Vehicles TO 'transport_operator';
GRANT SELECT, INSERT, UPDATE ON SmartTransportSystem.VehiclePositions TO 'transport_operator';
GRANT SELECT, INSERT, UPDATE ON SmartTransportSystem.VehicleStatusLog TO 'transport_operator';
GRANT SELECT, INSERT, UPDATE ON SmartTransportSystem.Schedules TO 'transport_operator';
GRANT SELECT ON SmartTransportSystem.Routes TO 'transport_operator';
GRANT SELECT ON SmartTransportSystem.RouteStops TO 'transport_operator';
GRANT SELECT ON SmartTransportSystem.Stops TO 'transport_operator';

-- Analyst (read access + analytics)
GRANT SELECT ON SmartTransportSystem.* TO 'transport_analyst';
GRANT INSERT, UPDATE ON SmartTransportSystem.DailyRouteAnalytics TO 'transport_analyst';
GRANT INSERT, UPDATE ON SmartTransportSystem.VehicleUtilization TO 'transport_analyst';
GRANT EXECUTE ON PROCEDURE SmartTransportSystem.CalculateRouteStatistics TO 'transport_analyst';

-- Customer (limited access)
GRANT SELECT ON SmartTransportSystem.Routes TO 'transport_customer';
GRANT SELECT ON SmartTransportSystem.RouteStops TO 'transport_customer';
GRANT SELECT ON SmartTransportSystem.Stops TO 'transport_customer';
GRANT SELECT ON SmartTransportSystem.Schedules TO 'transport_customer';
GRANT EXECUTE ON PROCEDURE SmartTransportSystem.PurchaseTicket TO 'transport_customer';
GRANT SELECT, UPDATE ON SmartTransportSystem.Passengers TO 'transport_customer';

CREATE USER 'admin_john' IDENTIFIED BY 'securepassword123';
CREATE USER 'operator_mary' IDENTIFIED BY 'operatorpass456';
CREATE USER 'analyst_sam' IDENTIFIED BY 'analystpass789';
CREATE USER 'customer_alex' IDENTIFIED BY 'customerpass012';

GRANT 'transport_admin' TO 'admin_john';
GRANT 'transport_operator' TO 'operator_mary';
GRANT 'transport_analyst' TO 'analyst_sam';
GRANT 'transport_customer' TO 'customer_alex';

-- Set default roles
SET DEFAULT ROLE ALL TO 'admin_john';
SET DEFAULT ROLE ALL TO 'operator_mary';
SET DEFAULT ROLE ALL TO 'analyst_sam';
SET DEFAULT ROLE ALL TO 'customer_alex';







SELECT v.VehicleID, v.RegistrationNumber, vt.TypeName, vt.Capacity
FROM Vehicles v
JOIN VehicleTypes vt ON v.VehicleTypeID = vt.VehicleTypeID
WHERE v.Status = 'Active';


SELECT r.RouteName, s.StopName, rs.SequenceNumber
FROM Routes r
JOIN RouteStops rs ON r.RouteID = rs.RouteID
JOIN Stops s ON rs.StopID = s.StopID
ORDER BY r.RouteName, rs.SequenceNumber;