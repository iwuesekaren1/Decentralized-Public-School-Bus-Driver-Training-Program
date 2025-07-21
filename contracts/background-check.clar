;; Background Check Processing Contract
;; Handles criminal history and reference verification

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-CHECK-NOT-FOUND (err u301))
(define-constant ERR-ALREADY-PROCESSED (err u302))
(define-constant ERR-INVALID-STATUS (err u303))
(define-constant ERR-EXPIRED-CHECK (err u304))
(define-constant ERR-INVALID-INPUT (err u305))

;; Data Variables
(define-data-var contract-admin principal CONTRACT-OWNER)
(define-data-var next-check-id uint u1)
(define-data-var background-check-validity-period uint u26280) ;; Approximately 6 months

;; Data Maps
(define-map background-checks
  { check-id: uint }
  {
    driver-id: principal,
    request-date: uint,
    completion-date: uint,
    status: (string-ascii 20),
    criminal-history-clear: bool,
    reference-checks-complete: bool,
    employment-history-verified: bool,
    expiration-date: uint,
    notes: (string-ascii 300)
  }
)

(define-map criminal-history-records
  { driver-id: principal, check-id: uint }
  {
    has-convictions: bool,
    conviction-details: (string-ascii 500),
    severity-level: uint,
    disqualifying-offenses: bool,
    review-required: bool,
    cleared-date: uint
  }
)

(define-map reference-checks
  { driver-id: principal, reference-number: uint }
  {
    reference-name: (string-ascii 100),
    reference-type: (string-ascii 50),
    contact-info: (string-ascii 200),
    response-received: bool,
    rating: uint,
    comments: (string-ascii 300),
    verification-date: uint
  }
)

(define-map employment-history
  { driver-id: principal, employer-number: uint }
  {
    employer-name: (string-ascii 100),
    position: (string-ascii 100),
    start-date: uint,
    end-date: uint,
    reason-for-leaving: (string-ascii 200),
    verified: bool,
    verification-date: uint,
    performance-rating: uint
  }
)

(define-map appeal-requests
  { driver-id: principal, appeal-id: uint }
  {
    original-check-id: uint,
    appeal-date: uint,
    reason: (string-ascii 500),
    status: (string-ascii 20),
    resolution-date: uint,
    resolution: (string-ascii 500)
  }
)

;; Authorization Functions
(define-private (is-contract-admin (caller principal))
  (is-eq caller (var-get contract-admin))
)

;; Validation Functions
(define-private (is-valid-status (status (string-ascii 20)))
  (or (is-eq status "pending")
      (is-eq status "in-progress")
      (is-eq status "completed")
      (is-eq status "failed")
      (is-eq status "expired"))
)

(define-private (is-valid-rating (rating uint))
  (and (>= rating u1) (<= rating u5))
)

(define-private (is-check-expired (expiration-date uint))
  (< expiration-date block-height)
)

;; Public Functions

;; Initiate background check
(define-public (initiate-background-check (driver-id principal))
  (let ((check-id (var-get next-check-id)))
    (asserts! (is-contract-admin tx-sender) ERR-NOT-AUTHORIZED)

    (map-set background-checks
      { check-id: check-id }
      {
        driver-id: driver-id,
        request-date: block-height,
        completion-date: u0,
        status: "pending",
        criminal-history-clear: false,
        reference-checks-complete: false,
        employment-history-verified: false,
        expiration-date: (+ block-height (var-get background-check-validity-period)),
        notes: "Background check initiated"
      }
    )

    (var-set next-check-id (+ check-id u1))
    (ok check-id)
  )
)

;; Process criminal history check
(define-public (process-criminal-history
  (driver-id principal)
  (check-id uint)
  (has-convictions bool)
  (conviction-details (string-ascii 500))
  (severity-level uint)
  (disqualifying-offenses bool))
  (let ((check-data (unwrap! (map-get? background-checks { check-id: check-id }) ERR-CHECK-NOT-FOUND)))
    (asserts! (is-contract-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get driver-id check-data) driver-id) ERR-INVALID-INPUT)
    (asserts! (not (is-eq (get status check-data) "completed")) ERR-ALREADY-PROCESSED)

    (map-set criminal-history-records
      { driver-id: driver-id, check-id: check-id }
      {
        has-convictions: has-convictions,
        conviction-details: conviction-details,
        severity-level: severity-level,
        disqualifying-offenses: disqualifying-offenses,
        review-required: (or has-convictions (> severity-level u2)),
        cleared-date: (if (not disqualifying-offenses) block-height u0)
      }
    )

    (map-set background-checks
      { check-id: check-id }
      (merge check-data {
        criminal-history-clear: (not disqualifying-offenses),
        status: "in-progress"
      })
    )

    (ok true)
  )
)

;; Add reference check
(define-public (add-reference-check
  (driver-id principal)
  (reference-number uint)
  (reference-name (string-ascii 100))
  (reference-type (string-ascii 50))
  (contact-info (string-ascii 200)))
  (begin
    (asserts! (is-contract-admin tx-sender) ERR-NOT-AUTHORIZED)

    (map-set reference-checks
      { driver-id: driver-id, reference-number: reference-number }
      {
        reference-name: reference-name,
        reference-type: reference-type,
        contact-info: contact-info,
        response-received: false,
        rating: u0,
        comments: "",
        verification-date: u0
      }
    )

    (ok true)
  )
)

;; Complete reference check
(define-public (complete-reference-check
  (driver-id principal)
  (reference-number uint)
  (rating uint)
  (comments (string-ascii 300)))
  (let ((reference-data (unwrap! (map-get? reference-checks { driver-id: driver-id, reference-number: reference-number }) ERR-CHECK-NOT-FOUND)))
    (asserts! (is-contract-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-rating rating) ERR-INVALID-INPUT)

    (map-set reference-checks
      { driver-id: driver-id, reference-number: reference-number }
      (merge reference-data {
        response-received: true,
        rating: rating,
        comments: comments,
        verification-date: block-height
      })
    )

    (ok true)
  )
)

;; Add employment history
(define-public (add-employment-history
  (driver-id principal)
  (employer-number uint)
  (employer-name (string-ascii 100))
  (position (string-ascii 100))
  (start-date uint)
  (end-date uint)
  (reason-for-leaving (string-ascii 200)))
  (begin
    (asserts! (is-contract-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (< start-date end-date) ERR-INVALID-INPUT)

    (map-set employment-history
      { driver-id: driver-id, employer-number: employer-number }
      {
        employer-name: employer-name,
        position: position,
        start-date: start-date,
        end-date: end-date,
        reason-for-leaving: reason-for-leaving,
        verified: false,
        verification-date: u0,
        performance-rating: u0
      }
    )

    (ok true)
  )
)

;; Verify employment history
(define-public (verify-employment-history
  (driver-id principal)
  (employer-number uint)
  (performance-rating uint))
  (let ((employment-data (unwrap! (map-get? employment-history { driver-id: driver-id, employer-number: employer-number }) ERR-CHECK-NOT-FOUND)))
    (asserts! (is-contract-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-rating performance-rating) ERR-INVALID-INPUT)

    (map-set employment-history
      { driver-id: driver-id, employer-number: employer-number }
      (merge employment-data {
        verified: true,
        verification-date: block-height,
        performance-rating: performance-rating
      })
    )

    (ok true)
  )
)

;; Complete background check
(define-public (complete-background-check
  (check-id uint)
  (notes (string-ascii 300)))
  (let ((check-data (unwrap! (map-get? background-checks { check-id: check-id }) ERR-CHECK-NOT-FOUND)))
    (asserts! (is-contract-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq (get status check-data) "completed")) ERR-ALREADY-PROCESSED)

    (map-set background-checks
      { check-id: check-id }
      (merge check-data {
        completion-date: block-height,
        status: "completed",
        reference-checks-complete: true,
        employment-history-verified: true,
        notes: notes
      })
    )

    (ok true)
  )
)

;; Submit appeal
(define-public (submit-appeal
  (driver-id principal)
  (appeal-id uint)
  (original-check-id uint)
  (reason (string-ascii 500)))
  (begin
    (asserts! (is-some (map-get? background-checks { check-id: original-check-id })) ERR-CHECK-NOT-FOUND)

    (map-set appeal-requests
      { driver-id: driver-id, appeal-id: appeal-id }
      {
        original-check-id: original-check-id,
        appeal-date: block-height,
        reason: reason,
        status: "pending",
        resolution-date: u0,
        resolution: ""
      }
    )

    (ok true)
  )
)

;; Process appeal
(define-public (process-appeal
  (driver-id principal)
  (appeal-id uint)
  (resolution (string-ascii 500)))
  (let ((appeal-data (unwrap! (map-get? appeal-requests { driver-id: driver-id, appeal-id: appeal-id }) ERR-CHECK-NOT-FOUND)))
    (asserts! (is-contract-admin tx-sender) ERR-NOT-AUTHORIZED)

    (map-set appeal-requests
      { driver-id: driver-id, appeal-id: appeal-id }
      (merge appeal-data {
        status: "resolved",
        resolution-date: block-height,
        resolution: resolution
      })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get background check info
(define-read-only (get-background-check (check-id uint))
  (map-get? background-checks { check-id: check-id })
)

;; Get criminal history record
(define-read-only (get-criminal-history (driver-id principal) (check-id uint))
  (map-get? criminal-history-records { driver-id: driver-id, check-id: check-id })
)

;; Get reference check
(define-read-only (get-reference-check (driver-id principal) (reference-number uint))
  (map-get? reference-checks { driver-id: driver-id, reference-number: reference-number })
)

;; Get employment history
(define-read-only (get-employment-history (driver-id principal) (employer-number uint))
  (map-get? employment-history { driver-id: driver-id, employer-number: employer-number })
)

;; Get appeal request
(define-read-only (get-appeal-request (driver-id principal) (appeal-id uint))
  (map-get? appeal-requests { driver-id: driver-id, appeal-id: appeal-id })
)

;; Check if background check is valid
(define-read-only (is-background-check-valid (check-id uint))
  (match (map-get? background-checks { check-id: check-id })
    check-data (and
      (is-eq (get status check-data) "completed")
      (not (is-check-expired (get expiration-date check-data)))
      (get criminal-history-clear check-data)
      (get reference-checks-complete check-data)
      (get employment-history-verified check-data)
    )
    false
  )
)

;; Administrative Functions

;; Update contract admin
(define-public (set-contract-admin (new-admin principal))
  (begin
    (asserts! (is-contract-admin tx-sender) ERR-NOT-AUTHORIZED)
    (var-set contract-admin new-admin)
    (ok true)
  )
)

;; Update validity period
(define-public (set-validity-period (new-period uint))
  (begin
    (asserts! (is-contract-admin tx-sender) ERR-NOT-AUTHORIZED)
    (var-set background-check-validity-period new-period)
    (ok true)
  )
)

;; Get contract admin
(define-read-only (get-contract-admin)
  (var-get contract-admin)
)
