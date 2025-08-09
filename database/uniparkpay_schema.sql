-- Create database
CREATE DATABASE IF NOT EXISTS uniparkpay;
USE uniparkpay;

-- User table
CREATE TABLE USER (
    id INT AUTO_INCREMENT PRIMARY KEY,
    university_id VARCHAR(255) UNIQUE NULL,
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    role ENUM('student', 'lecturer', 'admin', 'guest') NOT NULL,
    expiry_date DATETIME NULL,
    car_plate_no VARCHAR(20)
);

-- Parking Lot table
CREATE TABLE PARKING_AREA (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    radius DECIMAL(10,2) NOT NULL DEFAULT 100.00,
    asset_name VARCHAR(255)
);

-- Payment QR Code table
CREATE TABLE PAYMENT_QR_CODE (
    id INT AUTO_INCREMENT PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    qr_image LONGBLOB,
    proof_mime_type VARCHAR(50),
    user_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES USER(id) ON DELETE CASCADE
);

-- Parking Session table
CREATE TABLE PARKING_SESSION (
    id INT AUTO_INCREMENT PRIMARY KEY,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    user_id INT NOT NULL,
    parking_area_id INT NOT NULL,
    payment_qr_code_id INT NOT NULL,
    status ENUM('approved', 'unverified', 'rejected') NOT NULL DEFAULT 'unverified',
    payment_proof LONGBLOB,
    proof_filename VARCHAR(255),
    proof_mime_type VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES USER(id) ON DELETE CASCADE,
    FOREIGN KEY (parking_area_id) REFERENCES PARKING_AREA(id) ON DELETE CASCADE,
    FOREIGN KEY (payment_qr_code_id) REFERENCES PAYMENT_QR_CODE(id) ON DELETE CASCADE
);

-- Add admin user
INSERT INTO USER (university_id, name, phone_number, role)
VALUES ('ADMN', 'Admin', '0123456789', 'admin');
INSERT INTO USER (name, phone_number, role)
VALUES ('Guest', '0123456780', 'guest');
INSERT INTO USER (university_id, name, phone_number, role, expiry_date)
VALUES ('1234','Lecturer Name', '0123456788', 'lecturer', CURRENT_TIMESTAMP);

-- Add sample parking area
INSERT INTO PARKING_AREA (name, latitude, longitude, radius, asset_name)
VALUES
('UNISEL Bestari Jaya', 3.41609, 101.43882, 900.00, 'uni-logo.png');

-- Add dummy QR code for admin user
INSERT INTO PAYMENT_QR_CODE (filename, bank_name, qr_image, proof_mime_type, user_id)
VALUES ('admin_qr_sample.png', 'Maybank', NULL, 'image/png', 1);