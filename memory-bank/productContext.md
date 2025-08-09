# Product Context

## User Roles & Flows

### Admin
- **Authentication**: University ID (as username) + Telephone number (as password)
- **Account Type**: Permanent (no expiry handling)
- **Key Actions**:
  - Full CRUD operations on all user data
  - Can modify any user including other admins
  - Generate Excel reports (FUTURE DEVELOPMENT)
  - View parking sessions on map
  - Free parking (no payment required)
  - Upload and manage static QR codes for guest payments (single QR code, latest upload overwrites)
  - Review guest parking sessions and approve/reject based on payment proof
  - **QR Management**: Only update allowed, no create/delete operations

### Student & lecturer
- **Authentication**: University ID (as username) + Telephone number (as password)
- **Registration**: ID, Name, Phone, Expiry, Plate
- **Role Determination**:
  - **lecturer**: Exactly 4 alphabetic characters
  - **Student**: Exactly 10 alphabetic characters
- **Key Actions**:
  - Free parking
  - View parking spot on map
  - Access user profile
  - **Expiry Handling**:
      - Delete user and all associated parking sessions
      - Logout and prompt re-registration
      - Trigger on login and app startup
  - Cannot access admin functions

### Guest
- **Authentication**: Name + Telephone number
- **Registration**: Name, Phone, Plate
- **Key Actions**:
  - Paid parking: RM1 per hour
  - View single static QR code (latest admin upload)
  - Upload payment proof (PNG, JPEG, WebP supported)
  - Wait for admin approval
  - Cannot access admin functions
  - **Account Type**: Permanent (no expiry handling)
  - **Extension**: USER HAVE TO Create new parking session when duration expires

## Parking Functionality
- GPS-based location detection
- **Parking Area System**: Central coordinates + radius (meters) define valid parking areas
- Real-time calculation to determine if user is within parking area
- **Overlapping Areas**: First matching area is considered valid
- Session submission with area validation
- Map visualization with current location marker
- Time tracking
- Current date and time display

## Guest-Specific Features
- Duration selection (time-based parking)
- **Static QR Code Display**: Single admin-uploaded QR code for RM payment
- **Payment Proof Upload**: PNG image upload for bank transfer proof
- **Approval Flow**: Admin reviews proof before approving parking session
- **Session Expiry**: Display overtime warning, allow new session creation

## Parking Area Detection
- **Central Coordinates**: Each parking area has defined center point
- **Radius**: Circular boundary in meters around center point
- **Real-time Calculation**: System calculates distance from current GPS to area center
- **Validation**: Parking only allowed within defined area boundaries
- **Multiple Areas**: System supports multiple parking areas with different centers/radius
- **GPS Accuracy**: No accuracy threshold enforced

## Database Schema Details
- **USER table**: Stores user information including university_id, name, phone_number, role, expiry_date, and car_plate_no
- **PARKING_AREA table**: Defines parking areas with name, latitude, longitude, and radius (meters)
- **PAYMENT_QR_CODE table**: Stores single admin-uploaded QR code with filename, bank_name, qr_image (BLOB), and user_id reference
- **PARKING_SESSION table**: Tracks parking sessions with start_time, end_time, latitude, longitude, user_id, parking_area_id, payment_qr_code_id, status, payment_proof (BLOB), proof_filename, proof_mime_type, and created_at timestamp

## Admin Session Review Workflow
- **Interface**: Split view - guest sessions (with payment) and lecturer/student sessions (free parking)
- **Review Process**: 
  - View session details on map
  - View payment proof image
  - Set status: approved/unverified/rejected
- **Notification**: No push notifications, guest must check session status manually

## Error Handling
- **Payment Proof Upload Failure**: Show error message, allow retry
- **Network Issues**: Show error message, allow retry later
- **Session Creation Failure**: Display error, allow retry
- **GPS Issues**: Manual retry with refresh button