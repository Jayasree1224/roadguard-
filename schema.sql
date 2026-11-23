USE smartroad_db;

-- 1. DISTRICTS

CREATE TABLE IF NOT EXISTS districts (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    state VARCHAR(100) DEFAULT 'Tamil Nadu',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


-- 2. ROLES

CREATE TABLE IF NOT EXISTS roles (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255)
) ENGINE=InnoDB;


-- 3. DEPARTMENTS

CREATE TABLE IF NOT EXISTS departments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    district_id INT UNSIGNED NOT NULL,
    department_name VARCHAR(150) NOT NULL,
    department_type VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (district_id)
    REFERENCES districts(id)
) ENGINE=InnoDB;


-- 4. ROAD DIVISIONS

CREATE TABLE IF NOT EXISTS road_divisions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department_id INT UNSIGNED NOT NULL,
    division_name VARCHAR(150) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (department_id)
    REFERENCES departments(id)
) ENGINE=InnoDB;
-- 5. USERS

CREATE TABLE IF NOT EXISTS users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    role_id INT UNSIGNED NOT NULL,
    district_id INT UNSIGNED,

    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(20),

    password_hash VARCHAR(255) NOT NULL,

    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (role_id)
    REFERENCES roles(id),

    FOREIGN KEY (district_id)
    REFERENCES districts(id)
) ENGINE=InnoDB;


-- 6. OFFICERS

CREATE TABLE IF NOT EXISTS officers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id INT UNSIGNED NOT NULL UNIQUE,
    division_id INT UNSIGNED,

    designation VARCHAR(150) NOT NULL,
    hierarchy_level INT NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
    REFERENCES users(id),

    FOREIGN KEY (division_id)
    REFERENCES road_divisions(id)
) ENGINE=InnoDB;


-- 7. OFFICER HIERARCHY

CREATE TABLE IF NOT EXISTS officer_hierarchy (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    department_id INT UNSIGNED NOT NULL,

    hierarchy_level INT NOT NULL,

    designation VARCHAR(150) NOT NULL,

    next_level INT,

    sla_hours INT,

    FOREIGN KEY (department_id)
    REFERENCES departments(id),

    UNIQUE (department_id, hierarchy_level)
) ENGINE=InnoDB;
-- 8. ROADS

CREATE TABLE IF NOT EXISTS roads (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    road_name VARCHAR(200) NOT NULL,
    road_number VARCHAR(100),

    district_id INT UNSIGNED NOT NULL,
    department_id INT UNSIGNED,
    division_id INT UNSIGNED,

    taluk VARCHAR(100),
    local_body VARCHAR(150),

    road_category VARCHAR(100) NOT NULL,

    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (district_id)
    REFERENCES districts(id),

    FOREIGN KEY (department_id)
    REFERENCES departments(id),

    FOREIGN KEY (division_id)
    REFERENCES road_divisions(id)
) ENGINE=InnoDB;


-- 9. ROAD SEGMENTS

CREATE TABLE IF NOT EXISTS road_segments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    road_id INT UNSIGNED NOT NULL,

    start_latitude DECIMAL(10,7),
    start_longitude DECIMAL(10,7),

    end_latitude DECIMAL(10,7),
    end_longitude DECIMAL(10,7),

    segment_geometry JSON,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (road_id)
    REFERENCES roads(id)
) ENGINE=InnoDB;
-- 10. COMPLAINTS

CREATE TABLE IF NOT EXISTS complaints (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    complaint_number VARCHAR(50) NOT NULL UNIQUE,

    citizen_id INT UNSIGNED NOT NULL,

    road_id INT UNSIGNED,
    road_segment_id INT UNSIGNED,

    department_id INT UNSIGNED,
    division_id INT UNSIGNED,

    assigned_officer_id INT UNSIGNED,

    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),

    severity VARCHAR(20),

    status VARCHAR(50) DEFAULT 'Submitted',

    description TEXT,

    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (citizen_id)
    REFERENCES users(id),

    FOREIGN KEY (road_id)
    REFERENCES roads(id),

    FOREIGN KEY (road_segment_id)
    REFERENCES road_segments(id),

    FOREIGN KEY (department_id)
    REFERENCES departments(id),

    FOREIGN KEY (division_id)
    REFERENCES road_divisions(id),

    FOREIGN KEY (assigned_officer_id)
    REFERENCES officers(id),

    INDEX idx_complaint_status(status),
    INDEX idx_complaint_severity(severity)
) ENGINE=InnoDB;


-- 11. COMPLAINT IMAGES

CREATE TABLE IF NOT EXISTS complaint_images (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    complaint_id INT UNSIGNED NOT NULL,

    image_path VARCHAR(500) NOT NULL,

    capture_method VARCHAR(30),

    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (complaint_id)
    REFERENCES complaints(id)
) ENGINE=InnoDB;


-- 12. IMAGE METADATA

CREATE TABLE IF NOT EXISTS image_metadata (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    image_id INT UNSIGNED NOT NULL UNIQUE,

    original_filename VARCHAR(255),

    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),

    captured_at DATETIME,

    uploaded_at DATETIME,

    gps_accuracy DECIMAL(10,2),

    exif_data JSON,

    sha256_hash VARCHAR(64),

    FOREIGN KEY (image_id)
    REFERENCES complaint_images(id)
) ENGINE=InnoDB;


-- 13. IMAGE VERIFICATION

CREATE TABLE IF NOT EXISTS image_verification (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    image_id INT UNSIGNED NOT NULL UNIQUE,

    verification_status VARCHAR(30),

    confidence_score DECIMAL(5,2),

    duplicate_detected BOOLEAN DEFAULT FALSE,

    verification_reason TEXT,

    verified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (image_id)
    REFERENCES complaint_images(id)
) ENGINE=InnoDB;


-- 14. LOCATION VERIFICATION

CREATE TABLE IF NOT EXISTS location_verification (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    complaint_id INT UNSIGNED NOT NULL,

    verification_status VARCHAR(30),

    original_latitude DECIMAL(10,7),
    original_longitude DECIMAL(10,7),

    verified_latitude DECIMAL(10,7),
    verified_longitude DECIMAL(10,7),

    remarks TEXT,

    verified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (complaint_id)
    REFERENCES complaints(id)
) ENGINE=InnoDB;
-- 15. DETECTION RESULTS

CREATE TABLE IF NOT EXISTS detection_results (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    complaint_id INT UNSIGNED NOT NULL,
    image_id INT UNSIGNED NOT NULL,

    hazard_type VARCHAR(100),

    confidence_score DECIMAL(5,2),

    severity VARCHAR(20),

    detected_count INT DEFAULT 0,

    bounding_boxes JSON,

    model_version VARCHAR(100),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (complaint_id)
    REFERENCES complaints(id),

    FOREIGN KEY (image_id)
    REFERENCES complaint_images(id)
) ENGINE=InnoDB;


-- 16. ESCALATION RULES

CREATE TABLE IF NOT EXISTS escalation_rules (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    department_id INT UNSIGNED NOT NULL,

    severity VARCHAR(20) NOT NULL,

    response_hours INT NOT NULL,

    escalation_hours INT NOT NULL,

    is_active BOOLEAN DEFAULT TRUE,

    FOREIGN KEY (department_id)
    REFERENCES departments(id),

    UNIQUE (department_id, severity)
) ENGINE=InnoDB;


-- 17. ESCALATION HISTORY

CREATE TABLE IF NOT EXISTS escalation_history (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    complaint_id INT UNSIGNED NOT NULL,

    from_officer_id INT UNSIGNED,

    to_officer_id INT UNSIGNED,

    escalation_level INT,

    reason TEXT,

    escalated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (complaint_id)
    REFERENCES complaints(id),

    FOREIGN KEY (from_officer_id)
    REFERENCES officers(id),

    FOREIGN KEY (to_officer_id)
    REFERENCES officers(id)
) ENGINE=InnoDB;
-- 18. REPAIR UPDATES

CREATE TABLE IF NOT EXISTS repair_updates (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    complaint_id INT UNSIGNED NOT NULL,

    officer_id INT UNSIGNED,

    repair_status VARCHAR(50),

    remarks TEXT,

    before_image_path VARCHAR(500),

    after_image_path VARCHAR(500),

    completion_time DATETIME,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (complaint_id)
    REFERENCES complaints(id),

    FOREIGN KEY (officer_id)
    REFERENCES officers(id)
) ENGINE=InnoDB;


-- 19. NOTIFICATIONS

CREATE TABLE IF NOT EXISTS notifications (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id INT UNSIGNED NOT NULL,

    complaint_id INT UNSIGNED,

    title VARCHAR(200),

    message TEXT,

    is_read BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
    REFERENCES users(id),

    FOREIGN KEY (complaint_id)
    REFERENCES complaints(id)
) ENGINE=InnoDB;


-- 20. AUDIT LOGS

CREATE TABLE IF NOT EXISTS audit_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id INT UNSIGNED,

    action VARCHAR(150),

    description TEXT,

    ip_address VARCHAR(45),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
    REFERENCES users(id)
) ENGINE=InnoDB;