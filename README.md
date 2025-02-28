 CrowdSTX: Decentralized Crowdfunding on Stacks
==============================================

CrowdSTX is a trustless crowdfunding platform built on the Stacks blockchain, enabling anyone to launch and contribute to campaigns with full transparency and security.

Overview
--------

CrowdSTX is a smart contract implementation that facilitates decentralized fundraising campaigns on the Stacks blockchain. The platform allows creators to launch campaigns with specific funding goals and timeframes, while contributors can support campaigns with STX tokens. The funds are held securely in the smart contract until either the campaign reaches its goal (allowing the creator to withdraw) or fails (allowing contributors to claim refunds).

Features
--------

-   **Campaign Creation**: Anyone can create a crowdfunding campaign with customizable funding goals and durations
-   **Secure Contribution Management**: All contributions are tracked and stored securely on-chain
-   **Automated Fund Distribution**: Successful campaigns automatically enable fund withdrawal for creators
-   **Built-in Refund System**: Failed campaigns allow contributors to claim refunds automatically
-   **Full Transparency**: All campaign data is publicly available and verifiable on the blockchain

Contract Functions
------------------

### For Campaign Creators

#### `create-campaign`

Creates a new crowdfunding campaign.

```
(create-campaign (goal uint) (duration uint))

```

-   `goal`: Target amount in microSTX
-   `duration`: Campaign duration in blocks
-   Returns: Campaign ID

#### `withdraw-funds`

Allows campaign owner to withdraw funds after successful campaign.

```
(withdraw-funds (campaign-id uint))

```

-   `campaign-id`: ID of the campaign
-   Requirements:
    -   Caller must be campaign owner
    -   Campaign must still be active
    -   Campaign must have reached its goal

### For Contributors

#### `contribute`

Allows users to contribute STX to a campaign.

```
(contribute (campaign-id uint) (amount uint))

```

-   `campaign-id`: ID of the campaign
-   `amount`: Contribution amount in microSTX
-   Requirements:
    -   Campaign must be active
    -   Campaign must not have passed its deadline

#### `refund`

Allows contributors to claim refunds from failed campaigns.

```
(refund (campaign-id uint))

```

-   `campaign-id`: ID of the campaign
-   Requirements:
    -   Campaign deadline must have passed
    -   Campaign must not have reached its goal
    -   Campaign must still be marked as active
    -   Caller must have contributed to the campaign

### Read-Only Functions

#### `get-campaign`

Retrieves campaign details.

```
(get-campaign (campaign-id uint))

```

-   Returns campaign information including owner, goal, total funded, deadline, and active status

#### `get-contribution`

Retrieves contribution details for a specific contributor.

```
(get-contribution (campaign-id uint) (contributor principal))

```

-   Returns contribution amount for a specific user in a campaign

#### `get-last-campaign-id`

Returns the ID of the most recently created campaign.

```
(get-last-campaign-id)

```

Error Codes
-----------

| Code | Description |
| --- | --- |
| `u100` | Not authorized to perform this action |
| `u101` | Campaign not found |
| `u102` | Campaign goal not reached |
| `u103` | Campaign already ended |
| `u104` | Campaign is still active |

Usage Examples
--------------

### Creating a Campaign

```
;; Create a campaign with 10,000 STX goal and 1440 blocks duration (~10 days)
(contract-call? .crowdstx create-campaign u10000000000 u1440)

```

### Contributing to a Campaign

```
;; Contribute 100 STX to campaign #1
(contract-call? .crowdstx contribute u1 u100000000)

```

### Withdrawing Funds (for campaign creators)

```
;; Withdraw funds from successful campaign #1
(contract-call? .crowdstx withdraw-funds u1)

```

### Claiming a Refund

```
;; Claim refund from failed campaign #1
(contract-call? .crowdstx refund u1)

```

Security Considerations
-----------------------

-   The contract implements multiple safety checks to ensure funds are properly managed
-   All state changes are validated with appropriate assertions before execution
-   Fund transfers are properly encapsulated with `as-contract` to maintain contract authority
-   Campaign deadlines are enforced at the block level for deterministic outcomes

Development and Deployment
--------------------------

### Requirements

-   Clarity language support
-   Stacks blockchain access
-   Clarity CLI or similar tools for deployment

### Deployment

1.  Deploy the contract to the Stacks blockchain:

```
clarity-cli deploy crowdstx.clar

```

1.  Interact with the contract using Stacks wallet or CLI tools

Contributing
------------

Contributions are welcome! Please feel free to submit a Pull Request.

1.  Fork the repository
2.  Create your feature branch
3.  Commit your changes
4.  Push to the branch
5.  Open a Pull Request

Contact
-------

For questions or support, please open an issue in the repository.
