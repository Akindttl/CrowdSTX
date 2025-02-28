;; CrowdSTX - Crowdfunding smart contract 
;; Allows users to create campaigns, contribute funds, 
;; withdraw funds if the goal is met, and refund contributions if the campaign fails, 
;; all managed securely on the blockchain.

;; Define constants for contract owner and error codes
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100)) ;; Unauthorized access error
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u101)) ;; Campaign not found error
(define-constant ERR-GOAL-NOT-REACHED (err u102)) ;; Campaign goal not reached error
(define-constant ERR-ALREADY-ENDED (err u103)) ;; Campaign already ended error
(define-constant ERR-ACTIVE-CAMPAIGN (err u104)) ;; Campaign is still active error

;; Define a map to store campaign details
(define-map Campaigns
  { campaign-id: uint } ;; Unique ID for each campaign
  {
    owner: principal, ;; Owner of the campaign
    goal: uint, ;; Funding goal in STX
    total-funded: uint, ;; Total funds raised so far
    deadline: uint, ;; Block height when the campaign ends
    active: bool ;; Whether the campaign is still active
  }
)

;; Define a map to store contributions made by users
(define-map Contributions
  { campaign-id: uint, contributor: principal } ;; Composite key: campaign ID + contributor address
  { amount: uint } ;; Amount contributed by the user
)

;; Define a variable to track the last campaign ID
(define-data-var last-campaign-id uint u0)

;; Function to create a new campaign
(define-public (create-campaign (goal uint) (duration uint))
  (let
    (
      (campaign-id (+ (var-get last-campaign-id) u1)) ;; Generate a new campaign ID
      (deadline (+ block-height duration)) ;; Calculate the deadline based on current block height
    )
    (var-set last-campaign-id campaign-id) ;; Update the last campaign ID
    (map-insert Campaigns
      { campaign-id: campaign-id }
      {
        owner: tx-sender, ;; Set the campaign owner
        goal: goal, ;; Set the funding goal
        total-funded: u0, ;; Initialize total funded amount to 0
        deadline: deadline, ;; Set the deadline
        active: true ;; Mark the campaign as active
      }
    )
    (ok campaign-id) ;; Return the new campaign ID
  )
)

;; Function to contribute to a campaign
(define-public (contribute (campaign-id uint) (amount uint))
  (let
    (
      (campaign (unwrap! (map-get? Campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND)) ;; Fetch campaign details
    )
    (asserts! (get active campaign) ERR-ALREADY-ENDED) ;; Ensure the campaign is still active
    (asserts! (< block-height (get deadline campaign)) ERR-ALREADY-ENDED) ;; Ensure the campaign has not ended
    
    ;; Update or insert the contributor's contribution
    (match (map-get? Contributions { campaign-id: campaign-id, contributor: tx-sender })
      contribution
      (map-set Contributions
        { campaign-id: campaign-id, contributor: tx-sender }
        { amount: (+ (get amount contribution) amount) }) ;; Add to existing contribution
      (map-insert Contributions
        { campaign-id: campaign-id, contributor: tx-sender }
        { amount: amount }) ;; Insert new contribution
    )
    
    ;; Update the total funded amount in the campaign
    (map-set Campaigns
      { campaign-id: campaign-id }
      (merge campaign { total-funded: (+ (get total-funded campaign) amount) })
    )
    
    ;; Transfer STX from the contributor to the contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (ok true)
  )
)

;; Function for the campaign owner to withdraw funds
(define-public (withdraw-funds (campaign-id uint))
  (let
    (
      (campaign (unwrap! (map-get? Campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND)) ;; Fetch campaign details
    )
    (asserts! (is-eq (get owner campaign) tx-sender) ERR-NOT-AUTHORIZED) ;; Ensure the caller is the campaign owner
    (asserts! (get active campaign) ERR-ALREADY-ENDED) ;; Ensure the campaign is still active
    (asserts! (>= (get total-funded campaign) (get goal campaign)) ERR-GOAL-NOT-REACHED) ;; Ensure the goal is met
    
    ;; Mark the campaign as inactive
    (map-set Campaigns
      { campaign-id: campaign-id }
      (merge campaign { active: false })
    )
    
    ;; Transfer the total funded amount to the campaign owner
    (as-contract (stx-transfer? (get total-funded campaign) tx-sender (get owner campaign)))
  )
)

;; Function to get campaign details
(define-read-only (get-campaign (campaign-id uint))
  (map-get? Campaigns { campaign-id: campaign-id })
)

;; Function to get a contributor's contribution amount
(define-read-only (get-contribution (campaign-id uint) (contributor principal))
  (map-get? Contributions { campaign-id: campaign-id, contributor: contributor })
)

;; Function to get the last campaign ID
(define-read-only (get-last-campaign-id)
  (var-get last-campaign-id)
)

;; Function to refund a contributor if the campaign fails
(define-public (refund (campaign-id uint))
  (let
    (
      (campaign (unwrap! (map-get? Campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND)) ;; Fetch campaign details
      (contribution (unwrap! (map-get? Contributions { campaign-id: campaign-id, contributor: tx-sender }) ERR-NOT-AUTHORIZED)) ;; Fetch contributor's contribution
      (current-block block-height) ;; Get current block height
      (campaign-deadline (get deadline campaign)) ;; Get campaign deadline
      (campaign-goal (get goal campaign)) ;; Get campaign goal
      (total-funded (get total-funded campaign)) ;; Get total funded amount
      (refund-amount (get amount contribution)) ;; Get contributor's refund amount
    )
    ;; Ensure the campaign has ended and the goal was not met
    (asserts! (> current-block campaign-deadline) ERR-ACTIVE-CAMPAIGN)
    (asserts! (< total-funded campaign-goal) ERR-GOAL-NOT-REACHED)
    (asserts! (get active campaign) ERR-ALREADY-ENDED)
    (asserts! (> refund-amount u0) ERR-NOT-AUTHORIZED)
    
    ;; Delete the contributor's contribution record
    (map-delete Contributions 
      { campaign-id: campaign-id, contributor: tx-sender })
    
    ;; Log the refund event for auditing
    (print { 
      event: "refund",
      campaign-id: campaign-id,
      contributor: tx-sender,
      amount: refund-amount,
      block-height: current-block
    })
    
    ;; Transfer the refund amount back to the contributor
    (try! (as-contract (stx-transfer? refund-amount tx-sender tx-sender)))
    
    (ok true)
  )
)
