-- Optional: Manual database table creation
-- Note: The script creates this table automatically on first run
-- Only use this if you prefer manual database setup

CREATE TABLE IF NOT EXISTS `fake_plates` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `vehicle_plate` VARCHAR(10) NOT NULL UNIQUE,
    `original_plate` VARCHAR(10) NOT NULL,
    `fake_plate` VARCHAR(10) NOT NULL,
    `owner` VARCHAR(50) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_vehicle_plate` (`vehicle_plate`),
    INDEX `idx_fake_plate` (`fake_plate`),
    INDEX `idx_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;