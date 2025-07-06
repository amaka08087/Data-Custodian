;; PRIVACY COMPLIANCE MANAGEMENT SYSTEM SMART CONTRACT
;;
;; A comprehensive blockchain-based privacy compliance platform that enables
;; organizations to maintain GDPR, CCPA, and multi-jurisdictional regulatory
;; compliance through automated consent management, immutable audit trails,
;; and transparent data processing governance. The system provides users with
;; complete control over their personal data while ensuring organizations can
;; demonstrate compliance through cryptographically verifiable records.
;;
;; Core Capabilities:
;; - Automated privacy policy lifecycle management with versioning
;; - Granular user consent tracking and verification
;; - Immutable compliance audit trails for regulatory reporting
;; - Automated data subject rights fulfillment (GDPR Articles 15-22)
;; - Emergency data processing controls and system lockdown
;; - Cross-jurisdictional privacy regulation compliance framework

;; SYSTEM CONSTANTS AND ERROR CODES

(define-constant contract-owner tx-sender)

;; Authorization and Access Control Errors
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INSUFFICIENT-PERMISSIONS (err u101))
(define-constant ERR-SYSTEM-LOCKDOWN-ACTIVE (err u102))

;; Policy Management Errors
(define-constant ERR-POLICY-NOT-FOUND (err u200))
(define-constant ERR-INVALID-POLICY-VERSION (err u201))
(define-constant ERR-DUPLICATE-POLICY-EXISTS (err u202))
(define-constant ERR-POLICY-ALREADY-INACTIVE (err u203))
(define-constant ERR-POLICY-EXPIRY-INVALID (err u204))

;; Consent Management Errors
(define-constant ERR-CONSENT-ALREADY-EXISTS (err u300))
(define-constant ERR-CONSENT-RECORD-MISSING (err u301))
(define-constant ERR-CONSENT-WITHDRAWAL-BLOCKED (err u302))
(define-constant ERR-CONSENT-TYPE-INVALID (err u303))
(define-constant ERR-ACTIVE-CONSENT-REQUIRED (err u304))

;; Data Processing Errors
(define-constant ERR-INVALID-DATA-CATEGORY (err u400))
(define-constant ERR-INVALID-PROCESSING-PURPOSE (err u401))
(define-constant ERR-RETENTION-PERIOD-INVALID (err u402))
(define-constant ERR-PROCESSING-UNAUTHORIZED (err u403))

;; Request Management Errors
(define-constant ERR-REQUEST-NOT-FOUND (err u500))
(define-constant ERR-REQUEST-ALREADY-PROCESSED (err u501))
(define-constant ERR-REQUEST-STATUS-INVALID (err u502))
(define-constant ERR-INVALID-REQUEST-ID (err u503))

;; Input Validation Errors
(define-constant ERR-MALFORMED-INPUT (err u600))
(define-constant ERR-INVALID-ADDRESS (err u601))
(define-constant ERR-INVALID-TIMESTAMP (err u602))
(define-constant ERR-INVALID-TEXT-LENGTH (err u603))

;; System Configuration Constants
(define-constant maximum-policy-title-length u100)
(define-constant maximum-processing-operations u10)
(define-constant maximum-data-categories u10)
(define-constant maximum-retention-blocks u525600)
(define-constant maximum-admin-notes-length u200)
(define-constant hash-length u32)
(define-constant maximum-request-id u1000000)

;; ===========================
;; GLOBAL SYSTEM STATE TRACKING
;; ===========================

(define-data-var current-policy-version uint u0)
(define-data-var total-policies-created uint u0)
(define-data-var emergency-lockdown-enabled bool false)
(define-data-var next-activity-counter uint u1)
(define-data-var next-request-counter uint u1)


;; CORE DATA STRUCTURE DEFINITIONS


;; Privacy Policy Registry - Stores all policy versions with metadata
(define-map policy-registry
  { policy-version: uint }
  {
    title: (string-ascii 100),
    content-hash: (buff 32),
    effective-date: uint,
    expiration-date: (optional uint),
    created-by: principal,
    is-active: bool,
    creation-timestamp: uint
  }
)

;; User Consent Database - Tracks individual consent records
(define-map consent-database
  { user-principal: principal, policy-version: uint }
  {
    granted-timestamp: uint,
    consent-status: (string-ascii 20),
    authorized-operations: (list 10 (string-ascii 50)),
    retention-period: uint,
    withdrawal-permitted: bool,
    last-updated: uint
  }
)

;; Privacy Preferences Store - User-specific privacy settings
(define-map user-preferences
  { owner-principal: principal }
  {
    marketing-allowed: bool,
    analytics-allowed: bool,
    sharing-permitted: bool,
    preferred-retention: uint,
    contact-method: (string-ascii 20),
    preferences-updated: uint
  }
)

;; Processing Activity Ledger - Immutable audit trail
(define-map processing-ledger
  { activity-id: uint }
  {
    subject-principal: principal,
    data-category: (string-ascii 30),
    processing-purpose: (string-ascii 50),
    timestamp: uint,
    legal-basis: (string-ascii 50),
    retention-expires: uint,
    processor-principal: principal
  }
)

;; Data Subject Rights Queue - Manages user rights requests
(define-map rights-requests-queue
  { requester-principal: principal, request-id: uint }
  {
    submitted-date: uint,
    request-type: (string-ascii 30),
    target-categories: (list 10 (string-ascii 30)),
    current-status: (string-ascii 20),
    completed-date: (optional uint),
    admin-notes: (optional (string-ascii 200))
  }
)

;; INPUT VALIDATION HELPER FUNCTIONS

(define-private (validate-policy-title (title (string-ascii 100)))
  (let ((title-length (len title)))
    (and (> title-length u0) (<= title-length maximum-policy-title-length))
  )
)

(define-private (validate-content-hash (hash (buff 32)))
  (is-eq (len hash) hash-length)
)

(define-private (validate-timestamp (timestamp uint))
  (and (> timestamp u0) (<= timestamp u4294967295))
)

(define-private (validate-retention-period (blocks uint))
  (and (> blocks u0) (<= blocks maximum-retention-blocks))
)

(define-private (validate-policy-version (version uint))
  (and (> version u0) (<= version u1000000))
)

(define-private (validate-request-id (request-id uint))
  (and (> request-id u0) (<= request-id maximum-request-id))
)

(define-private (validate-text-content (content (string-ascii 50)))
  (let ((content-length (len content)))
    (and (> content-length u0) (<= content-length u50))
  )
)

(define-private (validate-data-category (category (string-ascii 30)))
  (or
    (is-eq category "personal-identifiers")
    (is-eq category "financial-information")
    (is-eq category "health-records")
    (is-eq category "behavioral-data")
    (is-eq category "technical-metadata")
    (is-eq category "biometric-data")
    (is-eq category "location-data")
  )
)

(define-private (validate-contact-method (method (string-ascii 20)))
  (or 
    (is-eq method "email")
    (is-eq method "phone")
    (is-eq method "postal")
    (is-eq method "none")
  )
)

(define-private (validate-consent-status (status (string-ascii 20)))
  (or 
    (is-eq status "granted-explicit")
    (is-eq status "granted-implicit")
    (is-eq status "withdrawn")
    (is-eq status "expired")
  )
)

(define-private (validate-request-status (status (string-ascii 20)))
  (or
    (is-eq status "pending-review")
    (is-eq status "processing")
    (is-eq status "completed")
    (is-eq status "rejected")
    (is-eq status "cancelled")
  )
)

(define-private (validate-request-type (request-type (string-ascii 30)))
  (or
    (is-eq request-type "data-access")
    (is-eq request-type "data-rectification")
    (is-eq request-type "data-erasure")
    (is-eq request-type "data-portability")
    (is-eq request-type "processing-restriction")
  )
)

(define-private (validate-operations-list (operations (list 10 (string-ascii 50))))
  (and 
    (> (len operations) u0)
    (<= (len operations) maximum-processing-operations)
  )
)

(define-private (validate-categories-list (categories (list 10 (string-ascii 30))))
  (and 
    (> (len categories) u0)
    (<= (len categories) maximum-data-categories)
  )
)

(define-private (validate-principal-address (address principal))
  (not (is-eq address 'SP000000000000000000002Q6VF78))
)

(define-private (validate-optional-timestamp (optional-timestamp (optional uint)))
  (match optional-timestamp
    timestamp-value (validate-timestamp timestamp-value)
    true
  )
)

(define-private (validate-admin-notes (notes (optional (string-ascii 200))))
  (match notes
    note-content (and (> (len note-content) u0) (<= (len note-content) maximum-admin-notes-length))
    true
  )
)

;; AUTHORIZATION HELPER FUNCTIONS

(define-private (verify-contract-owner)
  (is-eq tx-sender contract-owner)
)

(define-private (verify-system-operational)
  (not (var-get emergency-lockdown-enabled))
)

(define-private (verify-policy-exists (version uint))
  (is-some (map-get? policy-registry { policy-version: version }))
)

(define-private (verify-user-has-active-consent (user-principal principal))
  (let (
    (active-version (var-get current-policy-version))
    (consent-record (map-get? consent-database { user-principal: user-principal, policy-version: active-version }))
  )
    (match consent-record
      consent-data (and 
        (not (is-eq (get consent-status consent-data) "withdrawn"))
        (not (is-eq (get consent-status consent-data) "expired"))
        (get withdrawal-permitted consent-data)
      )
      false
    )
  )
)


;; PUBLIC READ-ONLY QUERY FUNCTIONS


(define-read-only (get-current-policy-version)
  (var-get current-policy-version)
)

(define-read-only (get-policy-information (version uint))
  (map-get? policy-registry { policy-version: version })
)

(define-read-only (get-user-consent-record (user-principal principal) (version uint))
  (map-get? consent-database { user-principal: user-principal, policy-version: version })
)

(define-read-only (get-current-user-consent (user-principal principal))
  (let ((active-version (var-get current-policy-version)))
    (map-get? consent-database { user-principal: user-principal, policy-version: active-version })
  )
)

(define-read-only (get-user-privacy-preferences (user-principal principal))
  (map-get? user-preferences { owner-principal: user-principal })
)

(define-read-only (check-active-consent-status (user-principal principal))
  (verify-user-has-active-consent user-principal)
)

(define-read-only (get-processing-activity (activity-id uint))
  (map-get? processing-ledger { activity-id: activity-id })
)

(define-read-only (get-rights-request (requester-principal principal) (request-id uint))
  (map-get? rights-requests-queue { requester-principal: requester-principal, request-id: request-id })
)

(define-read-only (get-system-lockdown-status)
  (var-get emergency-lockdown-enabled)
)

(define-read-only (get-total-policies-count)
  (var-get total-policies-created)
)

(define-read-only (get-next-activity-id)
  (var-get next-activity-counter)
)

(define-read-only (get-next-request-id)
  (var-get next-request-counter)
)

;; PRIVACY POLICY MANAGEMENT FUNCTIONS

(define-public (create-privacy-policy 
  (policy-title (string-ascii 100))
  (content-hash (buff 32))
  (effective-date uint)
  (expiration-date (optional uint))
)
  (let (
    (new-version (+ (var-get total-policies-created) u1))
    (current-block block-height)
  )
    ;; Authorization checks
    (asserts! (verify-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (verify-system-operational) ERR-SYSTEM-LOCKDOWN-ACTIVE)
    
    ;; Input validation
    (asserts! (validate-policy-title policy-title) ERR-MALFORMED-INPUT)
    (asserts! (validate-content-hash content-hash) ERR-MALFORMED-INPUT)
    (asserts! (validate-timestamp effective-date) ERR-INVALID-TIMESTAMP)
    (asserts! (validate-optional-timestamp expiration-date) ERR-INVALID-TIMESTAMP)
    (asserts! (>= effective-date current-block) ERR-POLICY-EXPIRY-INVALID)
    
    ;; Validate expiration date if provided
    (match expiration-date
      expiry-timestamp (asserts! (> expiry-timestamp effective-date) ERR-POLICY-EXPIRY-INVALID)
      true
    )
    
    ;; Ensure policy version doesn't already exist
    (asserts! (is-none (map-get? policy-registry { policy-version: new-version })) ERR-DUPLICATE-POLICY-EXISTS)
    
    ;; Create new policy record
    (map-set policy-registry
      { policy-version: new-version }
      {
        title: policy-title,
        content-hash: content-hash,
        effective-date: effective-date,
        expiration-date: expiration-date,
        created-by: tx-sender,
        is-active: true,
        creation-timestamp: current-block
      }
    )
    
    ;; Update system state
    (var-set total-policies-created new-version)
    (var-set current-policy-version new-version)
    
    (ok new-version)
  )
)

(define-public (deactivate-privacy-policy (version uint))
  (let (
    (policy-record (map-get? policy-registry { policy-version: version }))
  )
    ;; Authorization checks
    (asserts! (verify-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (verify-system-operational) ERR-SYSTEM-LOCKDOWN-ACTIVE)
    (asserts! (validate-policy-version version) ERR-MALFORMED-INPUT)
    
    (match policy-record
      policy-data (begin
        (asserts! (get is-active policy-data) ERR-POLICY-ALREADY-INACTIVE)
        
        (map-set policy-registry
          { policy-version: version }
          (merge policy-data { is-active: false })
        )
        (ok true)
      )
      ERR-POLICY-NOT-FOUND
    )
  )
)

;; USER CONSENT MANAGEMENT FUNCTIONS

(define-public (grant-consent 
  (consent-type (string-ascii 20))
  (authorized-operations (list 10 (string-ascii 50)))
  (retention-blocks uint)
)
  (let (
    (active-version (var-get current-policy-version))
    (current-timestamp block-height)
    (existing-consent (map-get? consent-database { user-principal: tx-sender, policy-version: active-version }))
  )
    ;; System checks
    (asserts! (verify-system-operational) ERR-SYSTEM-LOCKDOWN-ACTIVE)
    (asserts! (> active-version u0) ERR-POLICY-NOT-FOUND)
    
    ;; Input validation
    (asserts! (validate-consent-status consent-type) ERR-CONSENT-TYPE-INVALID)
    (asserts! (validate-operations-list authorized-operations) ERR-MALFORMED-INPUT)
    (asserts! (validate-retention-period retention-blocks) ERR-RETENTION-PERIOD-INVALID)
    
    ;; Check for existing consent
    (match existing-consent
      consent-data (asserts! (is-eq (get consent-status consent-data) "withdrawn") ERR-CONSENT-ALREADY-EXISTS)
      true
    )
    
    ;; Create consent record
    (map-set consent-database
      { user-principal: tx-sender, policy-version: active-version }
      {
        granted-timestamp: current-timestamp,
        consent-status: consent-type,
        authorized-operations: authorized-operations,
        retention-period: retention-blocks,
        withdrawal-permitted: true,
        last-updated: current-timestamp
      }
    )
    
    (ok true)
  )
)

(define-public (withdraw-consent)
  (let (
    (active-version (var-get current-policy-version))
    (existing-consent (map-get? consent-database { user-principal: tx-sender, policy-version: active-version }))
  )
    ;; System checks
    (asserts! (verify-system-operational) ERR-SYSTEM-LOCKDOWN-ACTIVE)
    
    (match existing-consent
      consent-data (begin
        (asserts! (not (is-eq (get consent-status consent-data) "withdrawn")) ERR-CONSENT-RECORD-MISSING)
        (asserts! (get withdrawal-permitted consent-data) ERR-CONSENT-WITHDRAWAL-BLOCKED)
        
        (map-set consent-database
          { user-principal: tx-sender, policy-version: active-version }
          (merge consent-data { 
            consent-status: "withdrawn",
            last-updated: block-height
          })
        )
        (ok true)
      )
      ERR-CONSENT-RECORD-MISSING
    )
  )
)


;; PRIVACY PREFERENCES MANAGEMENT


(define-public (update-privacy-preferences
  (allow-marketing bool)
  (allow-analytics bool)
  (allow-sharing bool)
  (preferred-retention uint)
  (contact-preference (string-ascii 20))
)
  (begin
    ;; Authorization checks
    (asserts! (verify-system-operational) ERR-SYSTEM-LOCKDOWN-ACTIVE)
    (asserts! (verify-user-has-active-consent tx-sender) ERR-ACTIVE-CONSENT-REQUIRED)
    
    ;; Input validation
    (asserts! (validate-retention-period preferred-retention) ERR-RETENTION-PERIOD-INVALID)
    (asserts! (validate-contact-method contact-preference) ERR-MALFORMED-INPUT)
    
    ;; Update preferences
    (map-set user-preferences
      { owner-principal: tx-sender }
      {
        marketing-allowed: allow-marketing,
        analytics-allowed: allow-analytics,
        sharing-permitted: allow-sharing,
        preferred-retention: preferred-retention,
        contact-method: contact-preference,
        preferences-updated: block-height
      }
    )
    
    (ok true)
  )
)

;; DATA PROCESSING AUDIT FUNCTIONS

(define-public (log-processing-activity
  (subject-principal principal)
  (data-category (string-ascii 30))
  (processing-purpose (string-ascii 50))
  (legal-basis (string-ascii 50))
  (retention-blocks uint)
)
  (let (
    (activity-id (var-get next-activity-counter))
    (current-timestamp block-height)
    (expiry-timestamp (+ current-timestamp retention-blocks))
  )
    ;; Authorization checks
    (asserts! (verify-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (verify-system-operational) ERR-SYSTEM-LOCKDOWN-ACTIVE)
    (asserts! (verify-user-has-active-consent subject-principal) ERR-ACTIVE-CONSENT-REQUIRED)
    
    ;; Input validation
    (asserts! (validate-principal-address subject-principal) ERR-INVALID-ADDRESS)
    (asserts! (validate-data-category data-category) ERR-INVALID-DATA-CATEGORY)
    (asserts! (validate-text-content processing-purpose) ERR-INVALID-PROCESSING-PURPOSE)
    (asserts! (validate-text-content legal-basis) ERR-MALFORMED-INPUT)
    (asserts! (validate-retention-period retention-blocks) ERR-RETENTION-PERIOD-INVALID)
    (asserts! (> expiry-timestamp current-timestamp) ERR-RETENTION-PERIOD-INVALID)
    
    ;; Create activity record
    (map-set processing-ledger
      { activity-id: activity-id }
      {
        subject-principal: subject-principal,
        data-category: data-category,
        processing-purpose: processing-purpose,
        timestamp: current-timestamp,
        legal-basis: legal-basis,
        retention-expires: expiry-timestamp,
        processor-principal: tx-sender
      }
    )
    
    ;; Update counter
    (var-set next-activity-counter (+ activity-id u1))
    (ok activity-id)
  )
)


;; DATA SUBJECT RIGHTS FUNCTIONS


(define-public (submit-rights-request 
  (request-type (string-ascii 30))
  (target-categories (list 10 (string-ascii 30)))
)
  (let (
    (request-id (var-get next-request-counter))
    (current-timestamp block-height)
  )
    ;; System checks
    (asserts! (verify-system-operational) ERR-SYSTEM-LOCKDOWN-ACTIVE)
    
    ;; Input validation
    (asserts! (validate-request-type request-type) ERR-MALFORMED-INPUT)
    (asserts! (validate-categories-list target-categories) ERR-INVALID-DATA-CATEGORY)
    
    ;; Create request record
    (map-set rights-requests-queue
      { requester-principal: tx-sender, request-id: request-id }
      {
        submitted-date: current-timestamp,
        request-type: request-type,
        target-categories: target-categories,
        current-status: "pending-review",
        completed-date: none,
        admin-notes: none
      }
    )
    
    ;; Update counter
    (var-set next-request-counter (+ request-id u1))
    (ok request-id)
  )
)

(define-public (process-rights-request
  (requester-principal principal)
  (request-id uint)
  (new-status (string-ascii 20))
  (admin-notes (optional (string-ascii 200)))
)
  (begin
    ;; Authorization checks
    (asserts! (verify-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (verify-system-operational) ERR-SYSTEM-LOCKDOWN-ACTIVE)
    
    ;; Input validation - validate request-id first before using it
    (asserts! (validate-principal-address requester-principal) ERR-INVALID-ADDRESS)
    (asserts! (validate-request-id request-id) ERR-INVALID-REQUEST-ID)
    (asserts! (validate-request-status new-status) ERR-REQUEST-STATUS-INVALID)
    (asserts! (validate-admin-notes admin-notes) ERR-MALFORMED-INPUT)
    
    ;; Now that request-id is validated, we can safely use it
    (let (
      (request-record (map-get? rights-requests-queue { requester-principal: requester-principal, request-id: request-id }))
    )
      (match request-record
        request-data (begin
          (asserts! (is-eq (get current-status request-data) "pending-review") ERR-REQUEST-ALREADY-PROCESSED)
          
          (map-set rights-requests-queue
            { requester-principal: requester-principal, request-id: request-id }
            (merge request-data {
              current-status: new-status,
              completed-date: (if (is-eq new-status "completed") (some block-height) none),
              admin-notes: admin-notes
            })
          )
          (ok true)
        )
        ERR-REQUEST-NOT-FOUND
      )
    )
  )
)

;; EMERGENCY SYSTEM CONTROLS

(define-public (enable-emergency-lockdown)
  (begin
    (asserts! (verify-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (var-set emergency-lockdown-enabled true)
    (ok true)
  )
)

(define-public (disable-emergency-lockdown)
  (begin
    (asserts! (verify-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (var-set emergency-lockdown-enabled false)
    (ok true)
  )
)