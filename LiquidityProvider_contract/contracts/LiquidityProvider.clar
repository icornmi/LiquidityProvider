
;; title: LiquidityProvider
;; version: 1.0.0
;; summary: Address reputation system for LP token provision and stability scoring
;; description: A smart contract that tracks liquidity provider reputation based on
;;              their token provision history and calculates stability scores

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-PROVIDER-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INSUFFICIENT-SCORE (err u104))

;; Minimum liquidity amount to be considered for scoring
(define-constant MIN-LIQUIDITY-AMOUNT u1000)

;; Maximum stability score
(define-constant MAX-STABILITY-SCORE u100)

;; data vars
(define-data-var contract-owner principal CONTRACT-OWNER)
(define-data-var total-providers uint u0)

;; data maps
;; Provider information
(define-map providers
    principal
    {
        total-provided: uint,
        provision-count: uint,
        last-provision-block: uint,
        stability-score: uint,
        is-active: bool
    }
)

;; Provider provision history
(define-map provision-history
    {provider: principal, provision-id: uint}
    {
        amount: uint,
        block-height: uint,
        duration: uint
    }
)

;; Provider provision counter
(define-map provider-provision-count principal uint)

;; public functions

;; Register a new liquidity provider
(define-public (register-provider)
    (let
        (
            (provider tx-sender)
            (existing-provider (map-get? providers provider))
        )
        (if (is-some existing-provider)
            ERR-ALREADY-EXISTS
            (begin
                (map-set providers provider
                    {
                        total-provided: u0,
                        provision-count: u0,
                        last-provision-block: block-height,
                        stability-score: u0,
                        is-active: true
                    }
                )
                (map-set provider-provision-count provider u0)
                (var-set total-providers (+ (var-get total-providers) u1))
                (ok true)
            )
        )
    )
)

;; Record a liquidity provision
(define-public (record-provision (amount uint) (duration uint))
    (let
        (
            (provider tx-sender)
            (provider-data (unwrap! (map-get? providers provider) ERR-PROVIDER-NOT-FOUND))
            (current-count (default-to u0 (map-get? provider-provision-count provider)))
            (new-count (+ current-count u1))
        )
        (asserts! (>= amount MIN-LIQUIDITY-AMOUNT) ERR-INVALID-AMOUNT)

        ;; Record provision history
        (map-set provision-history
            {provider: provider, provision-id: new-count}
            {
                amount: amount,
                block-height: block-height,
                duration: duration
            }
        )

        ;; Update provider data
        (map-set providers provider
            {
                total-provided: (+ (get total-provided provider-data) amount),
                provision-count: (+ (get provision-count provider-data) u1),
                last-provision-block: block-height,
                stability-score: (calculate-stability-score provider amount duration),
                is-active: true
            }
        )

        ;; Update provision count
        (map-set provider-provision-count provider new-count)

        (ok new-count)
    )
)

;; Deactivate a provider (only contract owner)
(define-public (deactivate-provider (provider principal))
    (let
        (
            (provider-data (unwrap! (map-get? providers provider) ERR-PROVIDER-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)

        (map-set providers provider
            (merge provider-data {is-active: false})
        )

        (ok true)
    )
)

;; Update contract owner (only current owner)
(define-public (update-owner (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
        (var-set contract-owner new-owner)
        (ok true)
    )
)

;; read only functions

;; Get provider information
(define-read-only (get-provider-info (provider principal))
    (map-get? providers provider)
)

;; Get provider provision history
(define-read-only (get-provision-history (provider principal) (provision-id uint))
    (map-get? provision-history {provider: provider, provision-id: provision-id})
)

;; Get provider's total provisions count
(define-read-only (get-provider-provision-count (provider principal))
    (default-to u0 (map-get? provider-provision-count provider))
)

;; Get total number of registered providers
(define-read-only (get-total-providers)
    (var-get total-providers)
)

;; Get contract owner
(define-read-only (get-contract-owner)
    (var-get contract-owner)
)

;; Check if provider is eligible for rewards (based on stability score)
(define-read-only (is-eligible-for-rewards (provider principal) (min-score uint))
    (match (map-get? providers provider)
        provider-data (and
                        (get is-active provider-data)
                        (>= (get stability-score provider-data) min-score)
                      )
        false
    )
)

;; Get top providers by stability score (simplified version - returns if provider meets threshold)
(define-read-only (is-top-provider (provider principal) (threshold uint))
    (match (map-get? providers provider)
        provider-data (and
                        (get is-active provider-data)
                        (>= (get stability-score provider-data) threshold)
                      )
        false
    )
)

;; private functions

;; Helper function to get minimum of two values
(define-private (min-uint (a uint) (b uint))
    (if (< a b) a b)
)

;; Calculate stability score based on provision amount, duration, and frequency
(define-private (calculate-stability-score (provider principal) (amount uint) (duration uint))
    (let
        (
            (provider-data (unwrap-panic (map-get? providers provider)))
            (provision-count (get provision-count provider-data))
            (total-provided (get total-provided provider-data))

            ;; Base score from amount (max 40 points)
            (amount-score (min-uint u40 (/ (* amount u40) (* MIN-LIQUIDITY-AMOUNT u10))))

            ;; Duration score (max 30 points) - longer duration = higher score
            (duration-score (min-uint u30 (/ duration u100)))

            ;; Frequency score (max 30 points) - more provisions = higher score
            (frequency-score (min-uint u30 provision-count))

            ;; Total score
            (total-score (+ amount-score (+ duration-score frequency-score)))
        )
        (min-uint MAX-STABILITY-SCORE total-score)
    )
)
