(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-INVALID-HASH u101)
(define-constant ERR-INVALID-TITLE u102)
(define-constant ERR-INVALID-DESCRIPTION u103)
(define-constant ERR-INVALID_LANGUAGE u104)
(define-constant ERR-INVALID_TAGS u105)
(define-constant ERR-DUPLICATE_NARRATIVE u106)
(define-constant ERR_INVALID_NARRATIVE_ID u107)
(define-constant ERR_NARRATIVE_NOT_FOUND u108)
(define-constant ERR_INVALID_TIMESTAMP u109)
(define-constant ERR_AUTHORITY_NOT_VERIFIED u110)
(define-constant ERR_INVALID_IPFS_CID u111)
(define-constant ERR_INVALID_CULTURAL_AFFILIATION u112)
(define-constant ERR_UPDATE_NOT_ALLOWED u113)
(define-constant ERR_INVALID_UPDATE_HASH u114)
(define-constant ERR_MAX_NARRATIVES_EXCEEDED u115)
(define-constant ERR_INVALID_NARRATIVE_TYPE u116)
(define-constant ERR_INVALID_DURATION u117)
(define-constant ERR_INVALID_FORMAT u118)
(define-constant ERR_INVALID_SENSITIVITY_LEVEL u119)
(define-constant ERR_INVALID_VERIFICATION_STATUS u120)
(define-constant ERR_INVALID_REWARD_AMOUNT u121)

(define-data-var next-narrative-id uint u0)
(define-data-var max-narratives uint u10000)
(define-data-var submission-fee uint u500)
(define-data-var authority-contract (optional principal) none)

(define-map narratives
  uint
  {
    content-hash: (buff 32),
    ipfs-cid: (optional (string-ascii 46)),
    title: (string-ascii 100),
    description: (string-utf8 500),
    language: (string-ascii 50),
    cultural-tags: (list 10 (string-ascii 50)),
    timestamp: uint,
    submitter: principal,
    narrative-type: (string-ascii 50),
    duration: uint,
    format: (string-ascii 20),
    sensitivity-level: uint,
    verification-status: bool,
    reward-amount: uint
  }
)

(define-map narratives-by-hash
  (buff 32)
  uint)

(define-map narrative-updates
  uint
  {
    update-hash: (buff 32),
    update-title: (string-ascii 100),
    update-description: (string-utf8 500),
    update-timestamp: uint,
    updater: principal
  }
)

(define-read-only (get-narrative (id uint))
  (map-get? narratives id)
)

(define-read-only (get-narrative-updates (id uint))
  (map-get? narrative-updates id)
)

(define-read-only (is-narrative-registered (h (buff 32)))
  (is-some (map-get? narratives-by-hash h))
)

(define-private (validate-hash (h (buff 32)))
  (if (is-eq (len h) u32)
      (ok true)
      ERR-INVALID-HASH)
)

(define-private (validate-title (t (string-ascii 100)))
  (if (and (> (len t) u0) (<= (len t) u100))
      (ok true)
      ERR-INVALID_TITLE)
)

(define-private (validate-description (desc (string-utf8 500)))
  (if (and (> (len desc) u0) (<= (len desc) u500))
      (ok true)
      ERR-INVALID-DESCRIPTION)
)

(define-private (validate-language (lang (string-ascii 50)))
  (if (> (len lang) u0)
      (ok true)
      ERR-INVALID_LANGUAGE)
)

(define-private (validate-tags (tags (list 10 (string-ascii 50))))
  (if (<= (len tags) u10)
      (ok true)
      ERR-INVALID_TAGS)
)

(define-private (validate-ipfs-cid (cid (optional (string-ascii 46))))
  (match cid
    value (if (is-eq (len value) u46)
              (ok true)
              ERR-INVALID_IPFS_CID)
    (ok true))
)

(define-private (validate-timestamp (ts uint))
  (if (>= ts block-height)
      (ok true)
      ERR-INVALID_TIMESTAMP)
)

(define-private (validate-narrative-type (nt (string-ascii 50)))
  (if (or (is-eq nt "oral-history") (is-eq nt "folktale") (is-eq nt "myth"))
      (ok true)
      ERR-INVALID_NARRATIVE_TYPE)
)

(define-private (validate-duration (d uint))
  (if (<= d u3600)
      (ok true)
      ERR-INVALID_DURATION)
)

(define-private (validate-format (f (string-ascii 20)))
  (if (or (is-eq f "audio") (is-eq f "text") (is-eq f "video"))
      (ok true)
      ERR-INVALID_FORMAT)
)

(define-private (validate-sensitivity-level (sl uint))
  (if (and (>= sl u1) (<= sl u5))
      (ok true)
      ERR-INVALID_SENSITIVITY_LEVEL)
)

(define-private (validate-reward-amount (ra uint))
  (if (<= ra u10000)
      (ok true)
      ERR-INVALID_REWARD_AMOUNT)
)

(define-public (set-authority-contract (contract-principal principal))
  (begin
    (asserts! (is-none (var-get authority-contract)) ERR_AUTHORITY_NOT_VERIFIED)
    (var-set authority-contract (some contract-principal))
    (ok true))
)

(define-public (set-max-narratives (new-max uint))
  (begin
    (asserts! (is-some (var-get authority-contract)) ERR_AUTHORITY_NOT_VERIFIED)
    (var-set max-narratives new-max)
    (ok true))
)

(define-public (set-submission-fee (new-fee uint))
  (begin
    (asserts! (is-some (var-get authority-contract)) ERR_AUTHORITY_NOT_VERIFIED)
    (var-set submission-fee new-fee)
    (ok true))
)

(define-public (submit-narrative
  (content-hash (buff 32))
  (ipfs-cid (optional (string-ascii 46)))
  (title (string-ascii 100))
  (description (string-utf8 500))
  (language (string-ascii 50))
  (cultural-tags (list 10 (string-ascii 50)))
  (narrative-type (string-ascii 50))
  (duration uint)
  (format (string-ascii 20))
  (sensitivity-level uint)
  (reward-amount uint))
  (let (
        (next-id (var-get next-narrative-id))
        (current-max (var-get max-narratives))
        (authority-check (contract-call? .user-registry is-verified-user tx-sender))
      )
    (asserts! (< next-id current-max) ERR_MAX_NARRATIVES_EXCEEDED)
    (try! (validate-hash content-hash))
    (try! (validate-ipfs-cid ipfs-cid))
    (try! (validate-title title))
    (try! (validate-description description))
    (try! (validate-language language))
    (try! (validate-tags cultural-tags))
    (try! (validate-narrative-type narrative-type))
    (try! (validate-duration duration))
    (try! (validate-format format))
    (try! (validate-sensitivity-level sensitivity-level))
    (try! (validate-reward-amount reward-amount))
    (asserts! (is-ok authority-check) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? narratives-by-hash content-hash)) ERR-DUPLICATE_NARRATIVE)
    (map-set narratives next-id
      {
        content-hash: content-hash,
        ipfs-cid: ipfs-cid,
        title: title,
        description: description,
        language: language,
        cultural-tags: cultural-tags,
        timestamp: block-height,
        submitter: tx-sender,
        narrative-type: narrative-type,
        duration: duration,
        format: format,
        sensitivity-level: sensitivity-level,
        verification-status: false,
        reward-amount: reward-amount
      })
    (map-set narratives-by-hash content-hash next-id)
    (var-set next-narrative-id (+ next-id u1))
    (print { event: "narrative-submitted", id: next-id })
    (ok next-id))
)

(define-public (update-narrative
  (narrative-id uint)
  (update-hash (buff 32))
  (update-title (string-ascii 100))
  (update-description (string-utf8 500)))
  (let (
        (narrative (map-get? narratives narrative-id))
        (authority-check (contract-call? .user-registry is-verified-user tx-sender))
      )
    (match narrative
      n
        (begin
          (asserts! (is-eq (get submitter n) tx-sender) ERR_NOT-AUTHORIZED)
          (try! (validate-hash update-hash))
          (try! (validate-title update-title))
          (try! (validate-description update-description))
          (asserts! (is-ok authority-check) ERR_NOT-AUTHORIZED)
          (let ((existing (map-get? narratives-by-hash update-hash)))
            (asserts!
              (or (is-none existing)
                  (is-eq (default-to u18446744073709551615 existing) narrative-id))
              ERR-DUPLICATE_NARRATIVE))
          (let ((old-hash (get content-hash n)))
            (map-delete narratives-by-hash old-hash)
            (map-set narratives-by-hash update-hash narrative-id))
          (map-set narratives narrative-id
            (merge n
              {
                content-hash: update-hash,
                title: update-title,
                description: update-description,
                timestamp: block-height
              }))
          (map-set narrative-updates narrative-id
            {
              update-hash: update-hash,
              update-title: update-title,
              update-description: update-description,
              update-timestamp: block-height,
              updater: tx-sender
            })
          (print { event: "narrative-updated", id: narrative-id })
          (ok true))
      ERR-NARRATIVE_NOT_FOUND))
)

(define-public (set-verification-status (narrative-id uint) (status bool))
  (let ((narrative (map-get? narratives narrative-id)))
    (match narrative
      n
        (begin
          (asserts! (is-some (var-get authority-contract)) ERR_AUTHORITY_NOT_VERIFIED)
          (map-set narratives narrative-id
            (merge n { verification-status: status }))
          (ok true))
      ERR-NARRATIVE_NOT_FOUND))
)

(define-public (get-narrative-count)
  (ok (var-get next-narrative-id))
)

(define-public (check-narrative-existence (hash (buff 32)))
  (ok (is-narrative-registered hash))
)