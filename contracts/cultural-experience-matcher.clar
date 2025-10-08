;; title: cultural-experience-matcher
;; version: 1.0.0
;; summary: Personalized local activity recommendations based on guest interests and cultural preferences
;; description: This contract manages the personalized recommendation system for matching guests with authentic local experiences.

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_GUEST_NOT_FOUND (err u301))
(define-constant ERR_EXPERIENCE_NOT_FOUND (err u302))
(define-constant ERR_INVALID_RATING (err u303))
(define-constant ERR_INVALID_PREFERENCE (err u304))
(define-constant ERR_DUPLICATE_REGISTRATION (err u305))
(define-constant ERR_INSUFFICIENT_AUTHENTICITY_SCORE (err u306))
(define-constant ERR_BOOKING_FAILED (err u307))

(define-constant MAX_RATING u10)
(define-constant MIN_RATING u1)
(define-constant MIN_AUTHENTICITY_SCORE u7)
(define-constant MAX_RECOMMENDATIONS u20)
(define-constant EXPERIENCE_CATEGORIES_COUNT u10)

;; Cultural categories
(define-constant CATEGORY_FOOD "food")
(define-constant CATEGORY_ART "art")
(define-constant CATEGORY_MUSIC "music")
(define-constant CATEGORY_HISTORY "history")
(define-constant CATEGORY_NATURE "nature")
(define-constant CATEGORY_CRAFTS "crafts")
(define-constant CATEGORY_FESTIVALS "festivals")
(define-constant CATEGORY_SPORTS "sports")
(define-constant CATEGORY_WELLNESS "wellness")
(define-constant CATEGORY_ADVENTURE "adventure")

;; data vars
(define-data-var next-guest-id uint u1)
(define-data-var next-experience-id uint u1)
(define-data-var next-booking-id uint u1)
(define-data-var total-guests uint u0)
(define-data-var total-experiences uint u0)
(define-data-var matching-algorithm-version uint u1)

;; data maps
;; Guest profiles with cultural preferences and interest scores
(define-map guest-profiles
  { guest-id: uint }
  {
    guest-address: principal,
    name: (string-ascii 64),
    cultural-interests: (string-ascii 256),
    preferred-categories: (string-ascii 128),
    budget-range: uint,
    group-size: uint,
    language-preference: (string-ascii 32),
    accessibility-needs: (string-ascii 128),
    registration-date: uint,
    total-bookings: uint,
    average-rating-given: uint
  }
)

;; Local experiences with cultural metadata and authenticity scores
(define-map experience-catalog
  { experience-id: uint }
  {
    provider-address: principal,
    title: (string-ascii 128),
    description: (string-ascii 512),
    category: (string-ascii 32),
    cultural-authenticity-score: uint,
    price-per-person: uint,
    duration-hours: uint,
    max-participants: uint,
    language-offered: (string-ascii 32),
    location: (string-ascii 128),
    available-dates: (string-ascii 256),
    verification-status: bool,
    creation-date: uint,
    total-bookings: uint,
    average-rating: uint
  }
)

;; Preference matrix for matching algorithm
(define-map guest-preferences
  { guest-id: uint, category: (string-ascii 32) }
  {
    interest-score: uint,
    previous-experience-count: uint,
    last-activity-date: uint,
    preferred-price-range: uint,
    satisfaction-history: uint
  }
)

;; Experience ratings and reviews
(define-map experience-ratings
  { guest-id: uint, experience-id: uint }
  {
    rating: uint,
    review-text: (string-ascii 512),
    authenticity-rating: uint,
    value-rating: uint,
    booking-date: uint,
    review-date: uint,
    verified-experience: bool
  }
)

;; Recommendation history and tracking
(define-map recommendation-history
  { guest-id: uint, recommendation-id: uint }
  {
    experience-id: uint,
    recommendation-score: uint,
    generated-date: uint,
    viewed: bool,
    booked: bool,
    booking-id: (optional uint)
  }
)

;; Cultural authenticity verification
(define-map authenticity-verifiers
  { verifier-address: principal }
  {
    name: (string-ascii 64),
    specialization: (string-ascii 64),
    verification-count: uint,
    reputation-score: uint,
    authorized: bool
  }
)

;; Experience bookings and status
(define-map experience-bookings
  { booking-id: uint }
  {
    guest-id: uint,
    experience-id: uint,
    booking-date: uint,
    scheduled-date: uint,
    participants: uint,
    total-price: uint,
    status: (string-ascii 32),
    payment-status: (string-ascii 32),
    special-requests: (string-ascii 256)
  }
)

;; Dynamic recommendation weights
(define-map recommendation-weights
  { category: (string-ascii 32) }
  {
    base-weight: uint,
    seasonal-modifier: uint,
    popularity-weight: uint,
    authenticity-weight: uint,
    price-sensitivity: uint
  }
)

;; public functions

;; Register a new guest profile with cultural preferences
(define-public (register-guest-profile
  (name (string-ascii 64))
  (cultural-interests (string-ascii 256))
  (preferred-categories (string-ascii 128))
  (budget-range uint)
  (group-size uint)
  (language-preference (string-ascii 32))
  (accessibility-needs (string-ascii 128))
  )
  (let 
    (
      (guest-id (var-get next-guest-id))
    )
    ;; Validate input parameters
    (asserts! (> (len name) u0) (err u308))
    (asserts! (> budget-range u0) (err u309))
    (asserts! (and (>= group-size u1) (<= group-size u50)) (err u310))
    
    ;; Store guest profile
    (map-set guest-profiles
      {guest-id: guest-id}
      {
        guest-address: tx-sender,
        name: name,
        cultural-interests: cultural-interests,
        preferred-categories: preferred-categories,
        budget-range: budget-range,
        group-size: group-size,
        language-preference: language-preference,
        accessibility-needs: accessibility-needs,
        registration-date: stacks-block-height,
        total-bookings: u0,
        average-rating-given: u0
      }
    )
    
    ;; Initialize preference weights for common categories
    (unwrap-panic (initialize-guest-preferences guest-id preferred-categories))
    
    ;; Update counters
    (var-set next-guest-id (+ guest-id u1))
    (var-set total-guests (+ (var-get total-guests) u1))
    
    (ok guest-id)
  )
)

;; Add a new local experience to the catalog
(define-public (add-experience
  (title (string-ascii 128))
  (description (string-ascii 512))
  (category (string-ascii 32))
  (price-per-person uint)
  (duration-hours uint)
  (max-participants uint)
  (language-offered (string-ascii 32))
  (location (string-ascii 128))
  (available-dates (string-ascii 256))
  )
  (let 
    (
      (experience-id (var-get next-experience-id))
    )
    ;; Validate input parameters
    (asserts! (> (len title) u0) (err u311))
    (asserts! (> price-per-person u0) (err u312))
    (asserts! (and (> duration-hours u0) (<= duration-hours u24)) (err u313))
    (asserts! (and (> max-participants u0) (<= max-participants u100)) (err u314))
    (asserts! (is-valid-category category) (err u315))
    
    ;; Store experience
    (map-set experience-catalog
      {experience-id: experience-id}
      {
        provider-address: tx-sender,
        title: title,
        description: description,
        category: category,
        cultural-authenticity-score: u5, ;; Default score, needs verification
        price-per-person: price-per-person,
        duration-hours: duration-hours,
        max-participants: max-participants,
        language-offered: language-offered,
        location: location,
        available-dates: available-dates,
        verification-status: false,
        creation-date: stacks-block-height,
        total-bookings: u0,
        average-rating: u0
      }
    )
    
    ;; Update counters
    (var-set next-experience-id (+ experience-id u1))
    (var-set total-experiences (+ (var-get total-experiences) u1))
    
    (ok experience-id)
  )
)

;; Generate personalized recommendations for a guest
(define-public (generate-recommendations (guest-id uint))
  (let 
    (
      (guest-profile (unwrap! (map-get? guest-profiles {guest-id: guest-id}) ERR_GUEST_NOT_FOUND))
      (recommendation-id (+ (* guest-id u1000) stacks-block-height)) ;; Unique recommendation ID
    )
    ;; Calculate recommendation scores using guest preferences
    ;; This is a simplified version - in practice, this would involve complex algorithms
    (let 
      (
        (top-experience-id (calculate-best-match guest-id))
        (recommendation-score (calculate-match-score guest-id top-experience-id))
      )
      ;; Store recommendation
      (map-set recommendation-history
        {guest-id: guest-id, recommendation-id: recommendation-id}
        {
          experience-id: top-experience-id,
          recommendation-score: recommendation-score,
          generated-date: stacks-block-height,
          viewed: false,
          booked: false,
          booking-id: none
        }
      )
      (ok recommendation-id)
    )
  )
)

;; Book an experience
(define-public (book-experience
  (guest-id uint)
  (experience-id uint)
  (scheduled-date uint)
  (participants uint)
  (special-requests (string-ascii 256))
  )
  (let 
    (
      (booking-id (var-get next-booking-id))
      (guest-profile (unwrap! (map-get? guest-profiles {guest-id: guest-id}) ERR_GUEST_NOT_FOUND))
      (experience (unwrap! (map-get? experience-catalog {experience-id: experience-id}) ERR_EXPERIENCE_NOT_FOUND))
      (total-price (* (get price-per-person experience) participants))
    )
    ;; Validate booking parameters
    (asserts! (is-eq (get guest-address guest-profile) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (<= participants (get max-participants experience)) (err u316))
    (asserts! (get verification-status experience) ERR_INSUFFICIENT_AUTHENTICITY_SCORE)
    
    ;; Create booking
    (map-set experience-bookings
      {booking-id: booking-id}
      {
        guest-id: guest-id,
        experience-id: experience-id,
        booking-date: stacks-block-height,
        scheduled-date: scheduled-date,
        participants: participants,
        total-price: total-price,
        status: "confirmed",
        payment-status: "pending",
        special-requests: special-requests
      }
    )
    
    ;; Update statistics
    (unwrap-panic (update-experience-booking-stats experience-id))
    (unwrap-panic (update-guest-booking-stats guest-id))
    
    ;; Update booking counter
    (var-set next-booking-id (+ booking-id u1))
    
    (ok booking-id)
  )
)

;; Submit rating and review for an experience
(define-public (submit-experience-rating
  (guest-id uint)
  (experience-id uint)
  (rating uint)
  (review-text (string-ascii 512))
  (authenticity-rating uint)
  (value-rating uint)
  )
  (let 
    (
      (guest-profile (unwrap! (map-get? guest-profiles {guest-id: guest-id}) ERR_GUEST_NOT_FOUND))
    )
    ;; Validate inputs
    (asserts! (is-eq (get guest-address guest-profile) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (and (>= rating MIN_RATING) (<= rating MAX_RATING)) ERR_INVALID_RATING)
    (asserts! (and (>= authenticity-rating MIN_RATING) (<= authenticity-rating MAX_RATING)) ERR_INVALID_RATING)
    (asserts! (and (>= value-rating MIN_RATING) (<= value-rating MAX_RATING)) ERR_INVALID_RATING)
    
    ;; Store rating and review
    (map-set experience-ratings
      {guest-id: guest-id, experience-id: experience-id}
      {
        rating: rating,
        review-text: review-text,
        authenticity-rating: authenticity-rating,
        value-rating: value-rating,
        booking-date: stacks-block-height,
        review-date: stacks-block-height,
        verified-experience: true
      }
    )
    
    ;; Update experience average rating
    (unwrap-panic (update-experience-rating experience-id rating))
    
    (ok true)
  )
)

;; Verify experience authenticity (for authorized verifiers only)
(define-public (verify-experience-authenticity
  (experience-id uint)
  (authenticity-score uint)
  )
  (let 
    (
      (verifier (unwrap! (map-get? authenticity-verifiers {verifier-address: tx-sender}) ERR_UNAUTHORIZED))
      (experience (unwrap! (map-get? experience-catalog {experience-id: experience-id}) ERR_EXPERIENCE_NOT_FOUND))
    )
    ;; Check if verifier is authorized
    (asserts! (get authorized verifier) ERR_UNAUTHORIZED)
    (asserts! (and (>= authenticity-score MIN_RATING) (<= authenticity-score MAX_RATING)) ERR_INVALID_RATING)
    
    ;; Update experience with verified authenticity score
    (map-set experience-catalog
      {experience-id: experience-id}
      (merge experience
        {
          cultural-authenticity-score: authenticity-score,
          verification-status: (>= authenticity-score MIN_AUTHENTICITY_SCORE)
        }
      )
    )
    
    ;; Update verifier statistics
    (map-set authenticity-verifiers
      {verifier-address: tx-sender}
      (merge verifier
        {
          verification-count: (+ (get verification-count verifier) u1)
        }
      )
    )
    
    (ok true)
  )
)

;; read only functions

;; Get guest profile information
(define-read-only (get-guest-profile (guest-id uint))
  (map-get? guest-profiles {guest-id: guest-id})
)

;; Get experience details
(define-read-only (get-experience-details (experience-id uint))
  (map-get? experience-catalog {experience-id: experience-id})
)

;; Get recommendation history for a guest
(define-read-only (get-recommendation-history (guest-id uint) (recommendation-id uint))
  (map-get? recommendation-history {guest-id: guest-id, recommendation-id: recommendation-id})
)

;; Get experience rating
(define-read-only (get-experience-rating (guest-id uint) (experience-id uint))
  (map-get? experience-ratings {guest-id: guest-id, experience-id: experience-id})
)

;; Get booking details
(define-read-only (get-booking-details (booking-id uint))
  (map-get? experience-bookings {booking-id: booking-id})
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-guests: (var-get total-guests),
    total-experiences: (var-get total-experiences),
    next-guest-id: (var-get next-guest-id),
    next-experience-id: (var-get next-experience-id),
    matching-algorithm-version: (var-get matching-algorithm-version)
  }
)

;; private functions

;; Validate cultural category
(define-private (is-valid-category (category (string-ascii 32)))
  (or
    (is-eq category CATEGORY_FOOD)
    (is-eq category CATEGORY_ART)
    (is-eq category CATEGORY_MUSIC)
    (is-eq category CATEGORY_HISTORY)
    (is-eq category CATEGORY_NATURE)
    (is-eq category CATEGORY_CRAFTS)
    (is-eq category CATEGORY_FESTIVALS)
    (is-eq category CATEGORY_SPORTS)
    (is-eq category CATEGORY_WELLNESS)
    (is-eq category CATEGORY_ADVENTURE)
  )
)

;; Initialize guest preferences based on selected categories
(define-private (initialize-guest-preferences (guest-id uint) (categories (string-ascii 128)))
  ;; This is a simplified implementation
  ;; In practice, this would parse the categories string and set individual preferences
  (begin
    (map-set guest-preferences
      {guest-id: guest-id, category: CATEGORY_FOOD}
      {
        interest-score: u7,
        previous-experience-count: u0,
        last-activity-date: u0,
        preferred-price-range: u100,
        satisfaction-history: u0
      }
    )
    (ok true)
  )
)

;; Calculate best matching experience for a guest (simplified)
(define-private (calculate-best-match (guest-id uint))
  ;; This is a simplified matching algorithm
  ;; In practice, this would analyze all experiences and rank them by compatibility
  (var-get next-experience-id) ;; Returns latest experience ID as simplified match
)

;; Calculate match score between guest and experience
(define-private (calculate-match-score (guest-id uint) (experience-id uint))
  ;; Simplified scoring algorithm
  ;; In practice, this would consider multiple factors like preferences, price, location, etc.
  u85 ;; Default score
)

;; Update experience booking statistics
(define-private (update-experience-booking-stats (experience-id uint))
  (match (map-get? experience-catalog {experience-id: experience-id})
    experience
    (begin
      (map-set experience-catalog
        {experience-id: experience-id}
        (merge experience
          {
            total-bookings: (+ (get total-bookings experience) u1)
          }
        )
      )
      (ok true)
    )
    (err u317)
  )
)

;; Update guest booking statistics
(define-private (update-guest-booking-stats (guest-id uint))
  (match (map-get? guest-profiles {guest-id: guest-id})
    guest-profile
    (begin
      (map-set guest-profiles
        {guest-id: guest-id}
        (merge guest-profile
          {
            total-bookings: (+ (get total-bookings guest-profile) u1)
          }
        )
      )
      (ok true)
    )
    (err u318)
  )
)

;; Update experience average rating
(define-private (update-experience-rating (experience-id uint) (new-rating uint))
  (match (map-get? experience-catalog {experience-id: experience-id})
    experience
    (let 
      (
        (current-rating (get average-rating experience))
        (booking-count (get total-bookings experience))
        (new-average (if (is-eq booking-count u0)
                      new-rating
                      (/ (+ (* current-rating booking-count) new-rating) (+ booking-count u1))))
      )
      (map-set experience-catalog
        {experience-id: experience-id}
        (merge experience
          {
            average-rating: new-average
          }
        )
      )
      (ok true)
    )
    (err u319)
  )
)
