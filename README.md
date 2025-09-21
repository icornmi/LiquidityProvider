# LiquidityProvider

A Clarity smart contract for the Stacks blockchain that implements an address reputation system for liquidity provider (LP) token provision and stability scoring.

## Description

LiquidityProvider is a smart contract that tracks liquidity provider reputation based on their token provision history and calculates stability scores. The contract enables DeFi protocols to assess the reliability and commitment of liquidity providers through a comprehensive scoring system that considers provision amounts, duration, and frequency.

## Features

- **Provider Registration**: Register new liquidity providers in the system
- **Provision Tracking**: Record and track liquidity provision events with amounts and durations
- **Stability Scoring**: Calculate provider stability scores based on multiple factors:
  - Provision amount (up to 40 points)
  - Duration of provision (up to 30 points)
  - Provision frequency (up to 30 points)
- **Provider Management**: Administrative functions to manage provider status
- **Reputation System**: Track provider history and eligibility for rewards
- **Query Functions**: Comprehensive read-only functions for data retrieval

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Epoch**: 2.5
- **Minimum Liquidity Amount**: 1,000 tokens
- **Maximum Stability Score**: 100 points

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v2.0 or later
- Node.js v16 or later
- npm or yarn

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd LiquidityProvider
```

2. Navigate to the contract directory:
```bash
cd LiquidityProvider_contract
```

3. Install dependencies:
```bash
npm install
```

4. Check contract syntax:
```bash
clarinet check
```

## Usage Examples

### Provider Registration

```clarity
;; Register as a new liquidity provider
(contract-call? .LiquidityProvider register-provider)
```

### Recording Provisions

```clarity
;; Record a liquidity provision of 5000 tokens for 1000 blocks
(contract-call? .LiquidityProvider record-provision u5000 u1000)
```

### Querying Provider Information

```clarity
;; Get provider information
(contract-call? .LiquidityProvider get-provider-info 'ST1234...)

;; Check if provider is eligible for rewards (minimum score of 50)
(contract-call? .LiquidityProvider is-eligible-for-rewards 'ST1234... u50)
```

## Contract Functions

### Public Functions

#### `register-provider()`
Registers a new liquidity provider in the system.
- **Returns**: `(response bool uint)`
- **Errors**: `ERR-ALREADY-EXISTS` if provider is already registered

#### `record-provision(amount, duration)`
Records a liquidity provision event for the caller.
- **Parameters**:
  - `amount` (uint): Amount of liquidity provided (minimum 1,000)
  - `duration` (uint): Duration of the provision in blocks
- **Returns**: `(response uint uint)`
- **Errors**:
  - `ERR-PROVIDER-NOT-FOUND` if provider not registered
  - `ERR-INVALID-AMOUNT` if amount below minimum

#### `deactivate-provider(provider)`
Deactivates a provider (admin only).
- **Parameters**:
  - `provider` (principal): Address of provider to deactivate
- **Returns**: `(response bool uint)`
- **Errors**:
  - `ERR-UNAUTHORIZED` if not contract owner
  - `ERR-PROVIDER-NOT-FOUND` if provider doesn't exist

#### `update-owner(new-owner)`
Updates the contract owner (current owner only).
- **Parameters**:
  - `new-owner` (principal): New contract owner address
- **Returns**: `(response bool uint)`
- **Errors**: `ERR-UNAUTHORIZED` if not current owner

### Read-Only Functions

#### `get-provider-info(provider)`
Returns complete provider information including total provided, provision count, last provision block, stability score, and active status.

#### `get-provision-history(provider, provision-id)`
Returns details of a specific provision including amount, block height, and duration.

#### `get-provider-provision-count(provider)`
Returns the total number of provisions made by a provider.

#### `get-total-providers()`
Returns the total number of registered providers in the system.

#### `get-contract-owner()`
Returns the current contract owner address.

#### `is-eligible-for-rewards(provider, min-score)`
Checks if a provider meets the minimum stability score requirement for rewards.

#### `is-top-provider(provider, threshold)`
Determines if a provider meets a specific stability score threshold.

## Stability Score Calculation

The stability score is calculated using three components:

1. **Amount Score** (0-40 points): Based on the provision amount relative to the minimum
2. **Duration Score** (0-30 points): Longer provision durations receive higher scores
3. **Frequency Score** (0-30 points): More frequent provisions increase the score

**Formula**: `min(100, amount-score + duration-score + frequency-score)`

## Deployment

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contracts
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## Testing

Run the test suite:
```bash
npm test
```

Run tests with coverage:
```bash
npm run test:report
```

Watch mode for development:
```bash
npm run test:watch
```

## Security Notes

### Access Control
- Contract owner has administrative privileges to deactivate providers and transfer ownership
- Provider-specific functions are restricted to the respective provider addresses
- All state-changing functions include appropriate authorization checks

### Validation
- Minimum liquidity amount enforcement prevents spam registrations
- Provider existence validation ensures data integrity
- Input validation prevents invalid state transitions

### Best Practices
- Use the contract in conjunction with proper frontend validation
- Regularly monitor provider activities and scores
- Consider implementing additional reward distribution mechanisms
- Audit the contract before mainnet deployment

## Error Codes

- `u100`: ERR-UNAUTHORIZED - Caller lacks required permissions
- `u101`: ERR-INVALID-AMOUNT - Provision amount below minimum threshold
- `u102`: ERR-PROVIDER-NOT-FOUND - Provider not registered in system
- `u103`: ERR-ALREADY-EXISTS - Provider already registered
- `u104`: ERR-INSUFFICIENT-SCORE - Provider doesn't meet minimum score requirement

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the ISC License.