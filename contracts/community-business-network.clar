;; title: community-business-network
;; version: 1.0.0
;; summary: Partnership platform connecting hotels with local artisans, tour guides, and service providers
;; description: This contract handles the partnership platform connecting hotels with local businesses and service providers.

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_BUSINESS_NOT_FOUND (err u401))
(define-constant ERR_HOTEL_NOT_FOUND (err u402))
(define-constant ERR_PARTNERSHIP_NOT_FOUND (err u403))
(define-constant ERR_INVALID_COMMISSION (err u404))
(define-constant ERR_INSUFFICIENT_BALANCE (err u405))
(define-constant ERR_INVALID_RATING (err u406))
(define-constant ERR_PARTNERSHIP_ALREADY_EXISTS (err u407))
(define-constant ERR_INVALID_SERVICE_TYPE (err u408))

(define-constant MAX_COMMISSION_RATE u50) ;; 50% maximum commission
(define-constant MIN_COMMISSION_RATE u1)  ;; 1% minimum commission
(define-constant MAX_RATING u10)
(define-constant MIN_RATING u1)
(define-constant PARTNERSHIP_DURATION u52560) ;; Blocks in a year (approx)
(define-constant MIN_REPUTATION_SCORE u60)

;; Service categories
(define-constant SERVICE_ARTISAN "artisan")
(define-constant SERVICE_TOUR_GUIDE "tour-guide")
(define-constant SERVICE_RESTAURANT "restaurant")
(define-constant SERVICE_TRANSPORTATION "transportation")
(define-constant SERVICE_WELLNESS "wellness")
(define-constant SERVICE_ENTERTAINMENT "entertainment")
(define-constant SERVICE_EDUCATION "education")
(define-constant SERVICE_CRAFTS "crafts")
(define-constant SERVICE_AGRICULTURE "agriculture")
(define-constant SERVICE_TECHNOLOGY "technology")

;; Partnership statuses
(define-constant STATUS_PENDING "pending")
(define-constant STATUS_ACTIVE "active")
(define-constant STATUS_PAUSED "paused")
(define-constant STATUS_TERMINATED "terminated")

;; data vars
(define-data-var next-business-id uint u1)
(define-data-var next-hotel-id uint u1)
(define-data-var next-partnership-id uint u1)
(define-data-var next-booking-id uint u1)
(define-data-var total-businesses uint u0)
(define-data-var total-hotels uint u0)
(define-data-var total-partnerships uint u0)
(define-data-var network-commission-rate uint u5) ;; 5% network fee

;; data maps
;; Community business registry
(define-map community-businesses
  { business-id: uint }
  {
    business-address: principal,
    business-name: (string-ascii 128),
    service-type: (string-ascii 32),
    description: (string-ascii 512),
    location: (string-ascii 128),
    contact-info: (string-ascii 256),
    specializations: (string-ascii 256),
    years-in-business: uint,
    certification-level: uint,
    verification-status: bool,
    reputation-score: uint,
    total-partnerships: uint,
    total-revenue: uint,
    registration-date: uint,
    last-activity: uint
  }
)

;; Hotel registry
(define-map hotel-registry
  { hotel-id: uint }
  {
    hotel-address: principal,
    hotel-name: (string-ascii 128),
    location: (string-ascii 128),
    star-rating: uint,
    guest-capacity: uint,
    partnership-budget: uint,
    preferred-service-types: (string-ascii 256),
    partnership-criteria: (string-ascii 512),
    total-partnerships: uint,
    total-bookings: uint,
    registration-date: uint,
    verification-status: bool
  }
)

;; Partnership agreements between hotels and businesses
(define-map business-partnerships
  { partnership-id: uint }
  {
    hotel-id: uint,
    business-id: uint,
    partnership-type: (string-ascii 32),
    commission-rate: uint,
    exclusive-agreement: bool,
    service-description: (string-ascii 512),
    terms-and-conditions: (string-ascii 1024),
    start-date: uint,
    end-date: uint,
    status: (string-ascii 32),
    total-bookings: uint,
    total-revenue: uint,
    performance-rating: uint
  }
)

;; Service bookings through partnerships
(define-map partnership-bookings
  { booking-id: uint }
  {
    partnership-id: uint,
    guest-principal: principal,
    service-date: uint,
    service-duration: uint,
    number-of-guests: uint,
    service-price: uint,
    commission-amount: uint,
    booking-status: (string-ascii 32),
    payment-status: (string-ascii 32),
    special-requirements: (string-ascii 256),
    booking-timestamp: uint
  }
)

;; Business performance metrics
(define-map business-performance
  { business-id: uint, period: uint }
  {
    total-bookings: uint,
    total-revenue: uint,
    average-rating: uint,
    customer-satisfaction: uint,
    partnership-growth: uint,
    reliability-score: uint
  }
)

;; Hotel partnership preferences and criteria
(define-map hotel-preferences
  { hotel-id: uint }
  {
    preferred-commission-range: uint,
    quality-requirements: (string-ascii 256),
    geographic-radius: uint,
    minimum-business-rating: uint,
    partnership-priorities: (string-ascii 256),
    budget-allocation: uint
  }
)

;; Reviews and ratings for partnerships
(define-map partnership-reviews
  { partnership-id: uint, reviewer: principal }
  {
    rating: uint,
    review-text: (string-ascii 512),
    service-quality: uint,
    reliability: uint,
    value-for-money: uint,
    communication: uint,
    review-date: uint,
    verified-booking: bool
  }
)

;; Revenue sharing and payment tracking
(define-map revenue-tracking
  { partnership-id: uint, period: uint }
  {
    total-revenue: uint,
    business-share: uint,
    hotel-commission: uint,
    network-fee: uint,
    payment-status: (string-ascii 32),
    payment-date: uint
  }
)

;; Business verification and certification
(define-map business-certifications
  { business-id: uint, certification-type: (string-ascii 64) }
  {
    issuer: principal,
    certification-date: uint,
    expiry-date: uint,
    verification-score: uint,
    active-status: bool
  }
)

;; public functions

;; Register a new community business
(define-public (register-community-business
  (business-name (string-ascii 128))
  (service-type (string-ascii 32))
  (description (string-ascii 512))
  (location (string-ascii 128))
  (contact-info (string-ascii 256))
  (specializations (string-ascii 256))
  (years-in-business uint)
  )
  (let 
    (
      (business-id (var-get next-business-id))
    )
    ;; Validate input parameters
    (asserts! (> (len business-name) u0) (err u409))
    (asserts! (is-valid-service-type service-type) ERR_INVALID_SERVICE_TYPE)
    (asserts! (> (len location) u0) (err u410))
    (asserts! (<= years-in-business u100) (err u411))
    
    ;; Store business information
    (map-set community-businesses
      {business-id: business-id}
      {
        business-address: tx-sender,
        business-name: business-name,
        service-type: service-type,
        description: description,
        location: location,
        contact-info: contact-info,
        specializations: specializations,
        years-in-business: years-in-business,
        certification-level: u1, ;; Basic level initially
        verification-status: false,
        reputation-score: u50, ;; Starting reputation
        total-partnerships: u0,
        total-revenue: u0,
        registration-date: stacks-block-height,
        last-activity: stacks-block-height
      }
    )
    
    ;; Update counters
    (var-set next-business-id (+ business-id u1))
    (var-set total-businesses (+ (var-get total-businesses) u1))
    
    (ok business-id)
  )
)

;; Register a new hotel
(define-public (register-hotel
  (hotel-name (string-ascii 128))
  (location (string-ascii 128))
  (star-rating uint)
  (guest-capacity uint)
  (partnership-budget uint)
  (preferred-service-types (string-ascii 256))
  (partnership-criteria (string-ascii 512))
  )
  (let 
    (
      (hotel-id (var-get next-hotel-id))
    )
    ;; Validate input parameters
    (asserts! (> (len hotel-name) u0) (err u412))
    (asserts! (and (>= star-rating u1) (<= star-rating u5)) (err u413))
    (asserts! (> guest-capacity u0) (err u414))
    (asserts! (> partnership-budget u0) (err u415))
    
    ;; Store hotel information
    (map-set hotel-registry
      {hotel-id: hotel-id}
      {
        hotel-address: tx-sender,
        hotel-name: hotel-name,
        location: location,
        star-rating: star-rating,
        guest-capacity: guest-capacity,
        partnership-budget: partnership-budget,
        preferred-service-types: preferred-service-types,
        partnership-criteria: partnership-criteria,
        total-partnerships: u0,
        total-bookings: u0,
        registration-date: stacks-block-height,
        verification-status: false
      }
    )
    
    ;; Initialize hotel preferences
    (map-set hotel-preferences
      {hotel-id: hotel-id}
      {
        preferred-commission-range: u15, ;; Default 15%
        quality-requirements: "high-quality-authentic-local-experiences",
        geographic-radius: u50, ;; 50km radius
        minimum-business-rating: u70,
        partnership-priorities: preferred-service-types,
        budget-allocation: partnership-budget
      }
    )
    
    ;; Update counters
    (var-set next-hotel-id (+ hotel-id u1))
    (var-set total-hotels (+ (var-get total-hotels) u1))
    
    (ok hotel-id)
  )
)

;; Create a partnership agreement between hotel and business
(define-public (create-partnership
  (hotel-id uint)
  (business-id uint)
  (partnership-type (string-ascii 32))
  (commission-rate uint)
  (exclusive-agreement bool)
  (service-description (string-ascii 512))
  (terms-and-conditions (string-ascii 1024))
  (duration-months uint)
  )
  (let 
    (
      (partnership-id (var-get next-partnership-id))
      (hotel (unwrap! (map-get? hotel-registry {hotel-id: hotel-id}) ERR_HOTEL_NOT_FOUND))
      (business (unwrap! (map-get? community-businesses {business-id: business-id}) ERR_BUSINESS_NOT_FOUND))
      (end-date (+ stacks-block-height (* duration-months u4380))) ;; Approximate blocks per month
    )
    ;; Validate partnership parameters
    (asserts! (or (is-eq (get hotel-address hotel) tx-sender) (is-eq (get business-address business) tx-sender)) ERR_UNAUTHORIZED)
    (asserts! (and (>= commission-rate MIN_COMMISSION_RATE) (<= commission-rate MAX_COMMISSION_RATE)) ERR_INVALID_COMMISSION)
    (asserts! (get verification-status business) (err u416))
    (asserts! (>= (get reputation-score business) MIN_REPUTATION_SCORE) (err u417))
    
    ;; Create partnership
    (map-set business-partnerships
      {partnership-id: partnership-id}
      {
        hotel-id: hotel-id,
        business-id: business-id,
        partnership-type: partnership-type,
        commission-rate: commission-rate,
        exclusive-agreement: exclusive-agreement,
        service-description: service-description,
        terms-and-conditions: terms-and-conditions,
        start-date: stacks-block-height,
        end-date: end-date,
        status: STATUS_PENDING,
        total-bookings: u0,
        total-revenue: u0,
        performance-rating: u0
      }
    )
    
    ;; Update partnership statistics
    (unwrap-panic (update-business-partnership-count business-id))
    (unwrap-panic (update-hotel-partnership-count hotel-id))
    
    ;; Update counters
    (var-set next-partnership-id (+ partnership-id u1))
    (var-set total-partnerships (+ (var-get total-partnerships) u1))
    
    (ok partnership-id)
  )
)

;; Activate a partnership (requires both parties' approval)
(define-public (activate-partnership (partnership-id uint))
  (let 
    (
      (partnership (unwrap! (map-get? business-partnerships {partnership-id: partnership-id}) ERR_PARTNERSHIP_NOT_FOUND))
      (hotel (unwrap! (map-get? hotel-registry {hotel-id: (get hotel-id partnership)}) ERR_HOTEL_NOT_FOUND))
      (business (unwrap! (map-get? community-businesses {business-id: (get business-id partnership)}) ERR_BUSINESS_NOT_FOUND))
    )
    ;; Verify authorization (either hotel or business can activate)
    (asserts! (or (is-eq (get hotel-address hotel) tx-sender) (is-eq (get business-address business) tx-sender)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status partnership) STATUS_PENDING) (err u418))
    
    ;; Activate partnership
    (map-set business-partnerships
      {partnership-id: partnership-id}
      (merge partnership {status: STATUS_ACTIVE})
    )
    
    (ok true)
  )
)

;; Book a service through a partnership
(define-public (book-partnership-service
  (partnership-id uint)
  (service-date uint)
  (service-duration uint)
  (number-of-guests uint)
  (service-price uint)
  (special-requirements (string-ascii 256))
  )
  (let 
    (
      (booking-id (var-get next-booking-id))
      (partnership (unwrap! (map-get? business-partnerships {partnership-id: partnership-id}) ERR_PARTNERSHIP_NOT_FOUND))
      (commission-amount (/ (* service-price (get commission-rate partnership)) u100))
    )
    ;; Validate booking parameters
    (asserts! (is-eq (get status partnership) STATUS_ACTIVE) (err u419))
    (asserts! (> service-price u0) (err u420))
    (asserts! (> number-of-guests u0) (err u421))
    
    ;; Create booking
    (map-set partnership-bookings
      {booking-id: booking-id}
      {
        partnership-id: partnership-id,
        guest-principal: tx-sender,
        service-date: service-date,
        service-duration: service-duration,
        number-of-guests: number-of-guests,
        service-price: service-price,
        commission-amount: commission-amount,
        booking-status: "confirmed",
        payment-status: "pending",
        special-requirements: special-requirements,
        booking-timestamp: stacks-block-height
      }
    )
    
    ;; Update partnership statistics
    (unwrap-panic (update-partnership-booking-stats partnership-id service-price))
    
    ;; Update booking counter
    (var-set next-booking-id (+ booking-id u1))
    
    (ok booking-id)
  )
)

;; Submit rating and review for a partnership
(define-public (submit-partnership-review
  (partnership-id uint)
  (rating uint)
  (review-text (string-ascii 512))
  (service-quality uint)
  (reliability uint)
  (value-for-money uint)
  (communication uint)
  )
  (let 
    (
      (partnership (unwrap! (map-get? business-partnerships {partnership-id: partnership-id}) ERR_PARTNERSHIP_NOT_FOUND))
    )
    ;; Validate rating parameters
    (asserts! (and (>= rating MIN_RATING) (<= rating MAX_RATING)) ERR_INVALID_RATING)
    (asserts! (and (>= service-quality MIN_RATING) (<= service-quality MAX_RATING)) ERR_INVALID_RATING)
    (asserts! (and (>= reliability MIN_RATING) (<= reliability MAX_RATING)) ERR_INVALID_RATING)
    (asserts! (and (>= value-for-money MIN_RATING) (<= value-for-money MAX_RATING)) ERR_INVALID_RATING)
    (asserts! (and (>= communication MIN_RATING) (<= communication MAX_RATING)) ERR_INVALID_RATING)
    
    ;; Store review
    (map-set partnership-reviews
      {partnership-id: partnership-id, reviewer: tx-sender}
      {
        rating: rating,
        review-text: review-text,
        service-quality: service-quality,
        reliability: reliability,
        value-for-money: value-for-money,
        communication: communication,
        review-date: stacks-block-height,
        verified-booking: true
      }
    )
    
    ;; Update business reputation
    (unwrap-panic (update-business-reputation (get business-id partnership) rating))
    
    (ok true)
  )
)

;; read only functions

;; Get community business information
(define-read-only (get-community-business (business-id uint))
  (map-get? community-businesses {business-id: business-id})
)

;; Get hotel information
(define-read-only (get-hotel-info (hotel-id uint))
  (map-get? hotel-registry {hotel-id: hotel-id})
)

;; Get partnership details
(define-read-only (get-partnership-details (partnership-id uint))
  (map-get? business-partnerships {partnership-id: partnership-id})
)

;; Get booking information
(define-read-only (get-booking-info (booking-id uint))
  (map-get? partnership-bookings {booking-id: booking-id})
)

;; Get partnership review
(define-read-only (get-partnership-review (partnership-id uint) (reviewer principal))
  (map-get? partnership-reviews {partnership-id: partnership-id, reviewer: reviewer})
)

;; Get business performance metrics
(define-read-only (get-business-performance (business-id uint) (period uint))
  (map-get? business-performance {business-id: business-id, period: period})
)

;; Get contract statistics
(define-read-only (get-network-stats)
  {
    total-businesses: (var-get total-businesses),
    total-hotels: (var-get total-hotels),
    total-partnerships: (var-get total-partnerships),
    next-business-id: (var-get next-business-id),
    next-hotel-id: (var-get next-hotel-id),
    network-commission-rate: (var-get network-commission-rate)
  }
)

;; private functions

;; Validate service type
(define-private (is-valid-service-type (service-type (string-ascii 32)))
  (or
    (is-eq service-type SERVICE_ARTISAN)
    (is-eq service-type SERVICE_TOUR_GUIDE)
    (is-eq service-type SERVICE_RESTAURANT)
    (is-eq service-type SERVICE_TRANSPORTATION)
    (is-eq service-type SERVICE_WELLNESS)
    (is-eq service-type SERVICE_ENTERTAINMENT)
    (is-eq service-type SERVICE_EDUCATION)
    (is-eq service-type SERVICE_CRAFTS)
    (is-eq service-type SERVICE_AGRICULTURE)
    (is-eq service-type SERVICE_TECHNOLOGY)
  )
)

;; Update business partnership count
(define-private (update-business-partnership-count (business-id uint))
  (match (map-get? community-businesses {business-id: business-id})
    business
    (begin
      (map-set community-businesses
        {business-id: business-id}
        (merge business
          {
            total-partnerships: (+ (get total-partnerships business) u1),
            last-activity: stacks-block-height
          }
        )
      )
      (ok true)
    )
    (err u422)
  )
)

;; Update hotel partnership count
(define-private (update-hotel-partnership-count (hotel-id uint))
  (match (map-get? hotel-registry {hotel-id: hotel-id})
    hotel
    (begin
      (map-set hotel-registry
        {hotel-id: hotel-id}
        (merge hotel
          {
            total-partnerships: (+ (get total-partnerships hotel) u1)
          }
        )
      )
      (ok true)
    )
    (err u423)
  )
)

;; Update partnership booking statistics
(define-private (update-partnership-booking-stats (partnership-id uint) (revenue uint))
  (match (map-get? business-partnerships {partnership-id: partnership-id})
    partnership
    (begin
      (map-set business-partnerships
        {partnership-id: partnership-id}
        (merge partnership
          {
            total-bookings: (+ (get total-bookings partnership) u1),
            total-revenue: (+ (get total-revenue partnership) revenue)
          }
        )
      )
      (ok true)
    )
    (err u424)
  )
)

;; Update business reputation score
(define-private (update-business-reputation (business-id uint) (new-rating uint))
  (match (map-get? community-businesses {business-id: business-id})
    business
    (let 
      (
        (current-score (get reputation-score business))
        (partnership-count (get total-partnerships business))
        (new-score (if (is-eq partnership-count u0)
                    new-rating
                    (/ (+ (* current-score partnership-count) new-rating) (+ partnership-count u1))))
      )
      (map-set community-businesses
        {business-id: business-id}
        (merge business
          {
            reputation-score: new-score,
            last-activity: stacks-block-height
          }
        )
      )
      (ok true)
    )
    (err u425)
  )
)
