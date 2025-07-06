# Privacy Compliance Management System (PCMS)

A comprehensive blockchain-based privacy compliance platform that enables organizations to maintain GDPR, CCPA, and multi-jurisdictional regulatory compliance through automated consent management, immutable audit trails, and transparent data processing governance.

## Core Features

- **Automated Privacy Policy Management**: Version-controlled policy lifecycle with immutable storage
- **Granular Consent Tracking**: Individual user consent with cryptographic verification
- **Immutable Audit Trails**: Blockchain-based compliance records for regulatory reporting
- **Data Subject Rights Automation**: GDPR Articles 15-22 compliance (access, rectification, erasure, portability)
- **Emergency Controls**: System-wide lockdown capabilities for data breach scenarios
- **Multi-Jurisdictional Support**: Framework for GDPR, CCPA, and other privacy regulations

## Installation

### Prerequisites

- Stacks CLI
- Clarinet (for local development and testing)
- Node.js 16+ (for integration scripts)


## Contract Architecture

### Data Structures

#### Policy Registry
Stores versioned privacy policies with metadata:
- Policy version and title
- Content hash for immutable verification
- Effective and expiration dates
- Creator information and status

#### Consent Database
Tracks individual user consent records:
- User principal and policy version
- Consent type (explicit/implicit)
- Authorized operations list
- Retention periods and withdrawal permissions

#### Processing Ledger
Immutable audit trail of data processing activities:
- Subject principal and data categories
- Processing purposes and legal basis
- Timestamps and retention expiry
- Processor identification

#### Rights Request Queue
Manages data subject rights requests:
- Request types (access, rectification, erasure, portability)
- Target data categories
- Processing status and completion dates
- Administrative notes

### Key Components

1. **Authorization Layer**: Role-based access control with owner privileges
2. **Validation Engine**: Comprehensive input validation and sanitization
3. **State Management**: Global system state tracking and versioning
4. **Audit System**: Immutable logging of all privacy-related activities

## Core Functions

### Policy Management

#### `create-privacy-policy`
Creates a new privacy policy version.

```clarity
(create-privacy-policy 
  "Privacy Policy v2.0" 
  0x1234567890abcdef... 
  u1000 
  (some u2000))
```

**Parameters:**
- `policy-title`: Human-readable policy title (max 100 chars)
- `content-hash`: SHA-256 hash of policy content
- `effective-date`: Block height when policy becomes active
- `expiration-date`: Optional expiration block height

#### `deactivate-privacy-policy`
Deactivates a specific policy version.

```clarity
(deactivate-privacy-policy u1)
```

### Consent Management

#### `grant-consent`
Records user consent for data processing.

```clarity
(grant-consent 
  "granted-explicit" 
  (list "analytics" "marketing" "essential") 
  u525600)
```

**Parameters:**
- `consent-type`: Type of consent granted
- `authorized-operations`: List of permitted processing operations
- `retention-blocks`: Data retention period in blocks

#### `withdraw-consent`
Allows users to withdraw previously granted consent.

```clarity
(withdraw-consent)
```

### Privacy Preferences

#### `update-privacy-preferences`
Updates user privacy preferences.

```clarity
(update-privacy-preferences 
  true 
  false 
  false 
  u262800 
  "email")
```

**Parameters:**
- `allow-marketing`: Marketing communications preference
- `allow-analytics`: Analytics tracking preference
- `allow-sharing`: Data sharing preference
- `preferred-retention`: Preferred retention period
- `contact-preference`: Preferred contact method

### Data Processing Audit

#### `log-processing-activity`
Records data processing activities for audit trails.

```clarity
(log-processing-activity 
  'SP1234567890ABCDEF... 
  "personal-identifiers" 
  "user-authentication" 
  "contract-performance" 
  u525600)
```

**Parameters:**
- `subject-principal`: Data subject's principal
- `data-category`: Category of data processed
- `processing-purpose`: Purpose of processing
- `legal-basis`: Legal basis for processing
- `retention-blocks`: Retention period in blocks

### Data Subject Rights

#### `submit-rights-request`
Submits a data subject rights request.

```clarity
(submit-rights-request 
  "data-access" 
  (list "personal-identifiers" "behavioral-data"))
```

**Parameters:**
- `request-type`: Type of rights request
- `target-categories`: Data categories affected

#### `process-rights-request`
Processes pending rights requests (admin only).

```clarity
(process-rights-request 
  'SP1234567890ABCDEF... 
  u1 
  "completed" 
  (some "Request processed successfully"))
```

### Emergency Controls

#### `enable-emergency-lockdown`
Activates emergency system lockdown.

```clarity
(enable-emergency-lockdown)
```

#### `disable-emergency-lockdown`
Deactivates emergency system lockdown.

```clarity
(disable-emergency-lockdown)
```

## Error Codes

### Authorization Errors (100-199)
- `ERR-UNAUTHORIZED-ACCESS (u100)`: Caller lacks required permissions
- `ERR-INSUFFICIENT-PERMISSIONS (u101)`: Operation requires higher privileges
- `ERR-SYSTEM-LOCKDOWN-ACTIVE (u102)`: System is in emergency lockdown

### Policy Management Errors (200-299)
- `ERR-POLICY-NOT-FOUND (u200)`: Referenced policy does not exist
- `ERR-INVALID-POLICY-VERSION (u201)`: Invalid policy version number
- `ERR-DUPLICATE-POLICY-EXISTS (u202)`: Policy version already exists
- `ERR-POLICY-ALREADY-INACTIVE (u203)`: Policy is already deactivated
- `ERR-POLICY-EXPIRY-INVALID (u204)`: Invalid expiration date

### Consent Management Errors (300-399)
- `ERR-CONSENT-ALREADY-EXISTS (u300)`: Consent already granted for this policy
- `ERR-CONSENT-RECORD-MISSING (u301)`: No consent record found
- `ERR-CONSENT-WITHDRAWAL-BLOCKED (u302)`: Consent withdrawal not permitted
- `ERR-CONSENT-TYPE-INVALID (u303)`: Invalid consent type specified
- `ERR-ACTIVE-CONSENT-REQUIRED (u304)`: Operation requires active consent

### Data Processing Errors (400-499)
- `ERR-INVALID-DATA-CATEGORY (u400)`: Invalid data category specified
- `ERR-INVALID-PROCESSING-PURPOSE (u401)`: Invalid processing purpose
- `ERR-RETENTION-PERIOD-INVALID (u402)`: Invalid retention period
- `ERR-PROCESSING-UNAUTHORIZED (u403)`: Unauthorized processing activity

### Request Management Errors (500-599)
- `ERR-REQUEST-NOT-FOUND (u500)`: Rights request not found
- `ERR-REQUEST-ALREADY-PROCESSED (u501)`: Request already processed
- `ERR-REQUEST-STATUS-INVALID (u502)`: Invalid request status

### Input Validation Errors (600-699)
- `ERR-MALFORMED-INPUT (u600)`: Input format is invalid
- `ERR-INVALID-ADDRESS (u601)`: Invalid principal address
- `ERR-INVALID-TIMESTAMP (u602)`: Invalid timestamp value
- `ERR-INVALID-TEXT-LENGTH (u603)`: Text exceeds maximum length

## Usage Examples

### Complete Workflow Example

```clarity
;; 1. Deploy contract and create initial policy
(create-privacy-policy 
  "Company Privacy Policy v1.0" 
  0x1234567890abcdef1234567890abcdef12345678 
  block-height 
  (some (+ block-height u525600)))

;; 2. User grants consent
(grant-consent 
  "granted-explicit" 
  (list "essential" "analytics" "marketing") 
  u262800)

;; 3. Set user preferences
(update-privacy-preferences 
  true 
  true 
  false 
  u262800 
  "email")

;; 4. Log processing activity
(log-processing-activity 
  tx-sender 
  "personal-identifiers" 
  "service-provision" 
  "contract-performance" 
  u262800)

;; 5. Submit rights request
(submit-rights-request 
  "data-access" 
  (list "personal-identifiers" "behavioral-data"))

;; 6. Process rights request (admin)
(process-rights-request 
  'SP1234567890ABCDEF... 
  u1 
  "completed" 
  (some "Data export provided via secure link"))
```

### Query Examples

```clarity
;; Check current policy version
(get-current-policy-version)

;; Get user's consent status
(get-current-user-consent tx-sender)

;; Check if user has active consent
(check-active-consent-status tx-sender)

;; Get user's privacy preferences
(get-user-privacy-preferences tx-sender)

;; Get processing activity details
(get-processing-activity u1)

;; Get rights request status
(get-rights-request tx-sender u1)
```
## Security Considerations

### Access Control
- Contract owner has administrative privileges
- Users can only modify their own consent and preferences
- Emergency lockdown prevents all non-read operations

### Data Integrity
- All policy content is stored as cryptographic hashes
- Consent records are immutable once created
- Processing activities create permanent audit trails

### Privacy Protection
- No personal data is stored on-chain
- Only metadata and consent records are maintained
- Users retain full control over their consent status

### Validation
- Comprehensive input validation prevents malformed data
- Principal address validation prevents invalid operations
- Timestamp validation ensures data consistency

## Compliance Features

### GDPR Compliance
- **Article 6**: Legal basis tracking for all processing
- **Article 7**: Consent management and withdrawal
- **Article 13-14**: Privacy policy version control
- **Article 15**: Data access request handling
- **Article 16**: Data rectification request support
- **Article 17**: Data erasure request processing
- **Article 18**: Processing restriction capabilities
- **Article 20**: Data portability request handling
- **Article 30**: Processing activity records

### CCPA Compliance
- Consumer rights request processing
- Data category tracking
- Processing purpose documentation
- Opt-out preference management

### Audit Trail Features
- Immutable processing activity logs
- Consent change tracking
- Policy version history
- Request processing records

## API Reference

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-current-policy-version` | Current active policy version | `uint` |
| `get-policy-information` | Policy details by version | `(optional policy-record)` |
| `get-user-consent-record` | User consent for specific policy | `(optional consent-record)` |
| `get-current-user-consent` | User's current consent status | `(optional consent-record)` |
| `get-user-privacy-preferences` | User's privacy preferences | `(optional preferences-record)` |
| `check-active-consent-status` | Whether user has active consent | `bool` |
| `get-processing-activity` | Processing activity by ID | `(optional activity-record)` |
| `get-rights-request` | Rights request details | `(optional request-record)` |
| `get-system-lockdown-status` | Emergency lockdown status | `bool` |

### State-Changing Functions

| Function | Access Level | Description |
|----------|--------------|-------------|
| `create-privacy-policy` | Owner | Creates new policy version |
| `deactivate-privacy-policy` | Owner | Deactivates policy version |
| `grant-consent` | User | Grants processing consent |
| `withdraw-consent` | User | Withdraws consent |
| `update-privacy-preferences` | User | Updates privacy preferences |
| `log-processing-activity` | Owner | Logs processing activity |
| `submit-rights-request` | User | Submits rights request |
| `process-rights-request` | Owner | Processes rights request |
| `enable-emergency-lockdown` | Owner | Activates emergency lockdown |
| `disable-emergency-lockdown` | Owner | Deactivates emergency lockdown |