(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_CREDENTIAL_NOT_FOUND (err u101))
(define-constant ERR_CREDENTIAL_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_CREDENTIAL (err u103))
(define-constant ERR_CREDENTIAL_REVOKED (err u104))
(define-constant ERR_ISSUER_NOT_AUTHORIZED (err u105))
(define-constant ERR_INVALID_SKILL_LEVEL (err u106))
(define-constant ERR_TRANSFER_NOT_ALLOWED (err u107))

(define-data-var credential-id-nonce uint u0)
(define-data-var skill-badge-id-nonce uint u0)

(define-map credentials
  { credential-id: uint }
  {
    issuer: principal,
    recipient: principal,
    credential-type: (string-ascii 64),
    skill-name: (string-ascii 128),
    skill-level: uint,
    institution: (string-ascii 128),
    issue-date: uint,
    expiry-date: (optional uint),
    metadata-uri: (optional (string-ascii 256)),
    is-revoked: bool,
    verification-hash: (buff 32)
  }
)

(define-map skill-badges
  { badge-id: uint }
  {
    issuer: principal,
    recipient: principal,
    skill-name: (string-ascii 128),
    badge-level: uint,
    issue-date: uint,
    prerequisites: (list 10 uint),
    metadata-uri: (optional (string-ascii 256)),
    is-active: bool
  }
)

(define-map authorized-issuers
  { issuer: principal }
  {
    institution-name: (string-ascii 128),
    authorized-by: principal,
    authorization-date: uint,
    is-active: bool,
    authority-level: uint
  }
)

(define-map recipient-credentials
  { recipient: principal }
  { credential-ids: (list 100 uint) }
)

(define-map recipient-badges
  { recipient: principal }
  { badge-ids: (list 100 uint) }
)

(define-map credential-verifications
  { credential-id: uint, verifier: principal }
  {
    verification-date: uint,
    verification-result: bool,
    notes: (optional (string-ascii 256))
  }
)

(define-map skill-endorsements
  { skill-name: (string-ascii 128), endorser: principal, recipient: principal }
  {
    endorsement-date: uint,
    endorsement-level: uint,
    notes: (optional (string-ascii 256))
  }
)

(define-public (authorize-issuer (issuer principal) (institution-name (string-ascii 128)) (authority-level uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= authority-level u5) ERR_INVALID_CREDENTIAL)
    (ok (map-set authorized-issuers
      { issuer: issuer }
      {
        institution-name: institution-name,
        authorized-by: tx-sender,
        authorization-date: stacks-block-height,
        is-active: true,
        authority-level: authority-level
      }
    ))
  )
)

(define-public (revoke-issuer-authorization (issuer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? authorized-issuers { issuer: issuer })
      issuer-data (ok (map-set authorized-issuers
        { issuer: issuer }
        (merge issuer-data { is-active: false })
      ))
      ERR_ISSUER_NOT_AUTHORIZED
    )
  )
)

(define-public (issue-credential 
  (recipient principal)
  (credential-type (string-ascii 64))
  (skill-name (string-ascii 128))
  (skill-level uint)
  (institution (string-ascii 128))
  (expiry-date (optional uint))
  (metadata-uri (optional (string-ascii 256)))
  (verification-hash (buff 32))
)
  (let
    (
      (credential-id (+ (var-get credential-id-nonce) u1))
      (current-height stacks-block-height)
    )
    (asserts! (is-authorized-issuer tx-sender) ERR_ISSUER_NOT_AUTHORIZED)
    (asserts! (<= skill-level u10) ERR_INVALID_SKILL_LEVEL)
    (asserts! (is-none (map-get? credentials { credential-id: credential-id })) ERR_CREDENTIAL_ALREADY_EXISTS)
    
    (map-set credentials
      { credential-id: credential-id }
      {
        issuer: tx-sender,
        recipient: recipient,
        credential-type: credential-type,
        skill-name: skill-name,
        skill-level: skill-level,
        institution: institution,
        issue-date: current-height,
        expiry-date: expiry-date,
        metadata-uri: metadata-uri,
        is-revoked: false,
        verification-hash: verification-hash
      }
    )
    
    (var-set credential-id-nonce credential-id)
    (update-recipient-credentials recipient credential-id)
    (ok credential-id)
  )
)

(define-public (issue-skill-badge
  (recipient principal)
  (skill-name (string-ascii 128))
  (badge-level uint)
  (prerequisites (list 10 uint))
  (metadata-uri (optional (string-ascii 256)))
)
  (let
    (
      (badge-id (+ (var-get skill-badge-id-nonce) u1))
      (current-height stacks-block-height)
    )
    (asserts! (is-authorized-issuer tx-sender) ERR_ISSUER_NOT_AUTHORIZED)
    (asserts! (<= badge-level u5) ERR_INVALID_SKILL_LEVEL)
    
    (map-set skill-badges
      { badge-id: badge-id }
      {
        issuer: tx-sender,
        recipient: recipient,
        skill-name: skill-name,
        badge-level: badge-level,
        issue-date: current-height,
        prerequisites: prerequisites,
        metadata-uri: metadata-uri,
        is-active: true
      }
    )
    
    (var-set skill-badge-id-nonce badge-id)
    (update-recipient-badges recipient badge-id)
    (ok badge-id)
  )
)

(define-public (revoke-credential (credential-id uint))
  (match (map-get? credentials { credential-id: credential-id })
    credential-data
    (begin
      (asserts! (is-eq (get issuer credential-data) tx-sender) ERR_UNAUTHORIZED)
      (asserts! (not (get is-revoked credential-data)) ERR_CREDENTIAL_REVOKED)
      (ok (map-set credentials
        { credential-id: credential-id }
        (merge credential-data { is-revoked: true })
      ))
    )
    ERR_CREDENTIAL_NOT_FOUND
  )
)

(define-public (verify-credential (credential-id uint) (verification-result bool) (notes (optional (string-ascii 256))))
  (match (map-get? credentials { credential-id: credential-id })
    credential-data
    (begin
      (asserts! (not (get is-revoked credential-data)) ERR_CREDENTIAL_REVOKED)
      (ok (map-set credential-verifications
        { credential-id: credential-id, verifier: tx-sender }
        {
          verification-date: stacks-block-height,
          verification-result: verification-result,
          notes: notes
        }
      ))
    )
    ERR_CREDENTIAL_NOT_FOUND
  )
)

(define-public (endorse-skill (skill-name (string-ascii 128)) (recipient principal) (endorsement-level uint) (notes (optional (string-ascii 256))))
  (begin
    (asserts! (<= endorsement-level u5) ERR_INVALID_SKILL_LEVEL)
    (ok (map-set skill-endorsements
      { skill-name: skill-name, endorser: tx-sender, recipient: recipient }
      {
        endorsement-date: stacks-block-height,
        endorsement-level: endorsement-level,
        notes: notes
      }
    ))
  )
)

(define-read-only (get-credential (credential-id uint))
  (map-get? credentials { credential-id: credential-id })
)

(define-read-only (get-skill-badge (badge-id uint))
  (map-get? skill-badges { badge-id: badge-id })
)

(define-read-only (get-recipient-credentials (recipient principal))
  (map-get? recipient-credentials { recipient: recipient })
)

(define-read-only (get-recipient-badges (recipient principal))
  (map-get? recipient-badges { recipient: recipient })
)

(define-read-only (get-issuer-authorization (issuer principal))
  (map-get? authorized-issuers { issuer: issuer })
)

(define-read-only (get-credential-verification (credential-id uint) (verifier principal))
  (map-get? credential-verifications { credential-id: credential-id, verifier: verifier })
)

(define-read-only (get-skill-endorsement (skill-name (string-ascii 128)) (endorser principal) (recipient principal))
  (map-get? skill-endorsements { skill-name: skill-name, endorser: endorser, recipient: recipient })
)

(define-read-only (is-credential-valid (credential-id uint))
  (match (map-get? credentials { credential-id: credential-id })
    credential-data
    (and 
      (not (get is-revoked credential-data))
      (match (get expiry-date credential-data)
        expiry (< stacks-block-height expiry)
        true
      )
    )
    false
  )
)

(define-read-only (is-authorized-issuer (issuer principal))
  (match (map-get? authorized-issuers { issuer: issuer })
    issuer-data (get is-active issuer-data)
    false
  )
)

(define-read-only (get-total-credentials)
  (var-get credential-id-nonce)
)

(define-read-only (get-total-skill-badges)
  (var-get skill-badge-id-nonce)
)

(define-private (update-recipient-credentials (recipient principal) (credential-id uint))
  (let
    (
      (current-list (default-to { credential-ids: (list) } (map-get? recipient-credentials { recipient: recipient })))
      (updated-list (unwrap-panic (as-max-len? (append (get credential-ids current-list) credential-id) u100)))
    )
    (map-set recipient-credentials
      { recipient: recipient }
      { credential-ids: updated-list }
    )
  )
)

(define-private (update-recipient-badges (recipient principal) (badge-id uint))
  (let
    (
      (current-list (default-to { badge-ids: (list) } (map-get? recipient-badges { recipient: recipient })))
      (updated-list (unwrap-panic (as-max-len? (append (get badge-ids current-list) badge-id) u100)))
    )
    (map-set recipient-badges
      { recipient: recipient }
      { badge-ids: updated-list }
    )
  )
)

(define-public (transfer-credential (credential-id uint) (new-recipient principal))
  (match (map-get? credentials { credential-id: credential-id })
    credential-data
    (begin
      (asserts! (is-eq (get recipient credential-data) tx-sender) ERR_UNAUTHORIZED)
      (asserts! (not (get is-revoked credential-data)) ERR_CREDENTIAL_REVOKED)
      (asserts! (not (is-eq tx-sender new-recipient)) ERR_TRANSFER_NOT_ALLOWED)
      
      (update-recipient-credentials new-recipient credential-id)
      
      (ok (map-set credentials
        { credential-id: credential-id }
        (merge credential-data { recipient: new-recipient })
      ))
    )
    ERR_CREDENTIAL_NOT_FOUND
  )
)

(define-read-only (can-transfer-credential (credential-id uint) (sender principal))
  (match (map-get? credentials { credential-id: credential-id })
    credential-data
    (and 
      (is-eq (get recipient credential-data) sender)
      (not (get is-revoked credential-data))
    )
    false
  )
)
