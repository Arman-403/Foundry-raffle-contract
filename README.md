# 🎰 Provably Fair Raffle

A decentralized, verifiably random lottery system built with Solidity and Chainlink.

## ✨ What It Does

Players enter a raffle by paying an entrance fee. After a set time interval, Chainlink Automation triggers the winner selection. Chainlink VRF provides cryptographically secure randomness to pick the winner. The entire prize pool is automatically sent to the winner, and the raffle resets for the next round.

## 🏗️ Architecture

```
┌─────────────────┐
│   Players Enter │
│  (Pay ETH Fee)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Time Interval  │
│   (30 seconds)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Chainlink Auto  │
│ (checkUpkeep)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Chainlink VRF   │
│ (Random Winner) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Winner Paid    │
│  Raffle Resets  │
└─────────────────┘
```

## 🛠️ Built With

- **Solidity 0.8.19** - Smart contract language
- **Foundry** - Development framework
- **Chainlink VRF v2.5** - Verifiable randomness
- **Chainlink Automation** - Automated winner selection

## 📁 Project Structure

```
src/
├── Raffle.sol              # Main raffle contract

script/
├── DeployRaffle.s.sol      # Deployment script
├── HelperConfig.s.sol      # Network configurations
└── interaction.s.sol       # Subscription management

test/
├── unit/
│   └── RaffleTest.sol      # Unit tests
└── integration/
    ├── RaffleIntegration.t.sol        # Integration tests
    ├── InteractionTest.t.sol          # Script tests
    └── EdgeCasesTest.t.sol            # Edge cases
```

## 🚀 Quick Start

### Prerequisites

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Installation

```bash
git clone <your-repo>
cd raffle-project
forge install
```

### Run Tests

```bash
# Run all tests
forge test

# Run with gas report
forge test --gas-report

# Run with detailed output
forge test -vvvv
```

## 📝 Contract Details

### Raffle.sol

**Key Functions:**
- `enterRaffle()` - Players enter by paying entrance fee
- `checkUpkeep()` - Chainlink checks if winner selection is needed
- `performUpkeep()` - Triggers VRF request for random number
- `fulfillRandomWords()` - VRF callback that selects winner

**States:**
- `OPEN` - Accepting entries
- `CALCULATING` - Winner being selected (entries blocked)

## 🧪 Testing

**30 comprehensive tests** covering:
- ✅ Complete raffle lifecycle
- ✅ Multiple players and rounds
- ✅ VRF integration
- ✅ Chainlink Automation
- ✅ Subscription management
- ✅ Edge cases and reverts

```bash
forge test
```

## 🌐 Deploy

### Local (Anvil)

```bash
# Start local node
anvil

# Deploy
forge script script/DeployRaffle.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Sepolia Testnet

```bash
# Set environment variables
export SEPOLIA_RPC_URL=<your_rpc_url>
export PRIVATE_KEY=<your_private_key>

# Deploy
forge script script/DeployRaffle.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

## ⚙️ Configuration

**HelperConfig.s.sol** manages network-specific settings:

```solidity
entranceFee: 0.01 ether
interval: 30 seconds
vrfCoordinator: <network_specific>
subscriptionId: <your_subscription>
```

## 🔐 Security

- ✅ Checks-Effects-Interactions pattern
- ✅ State locking during winner selection
- ✅ Proper access control
- ✅ No reentrancy vulnerabilities
- ✅ Verifiable randomness via Chainlink VRF

## 📊 Gas Optimization

- Immutable variables for deployment values
- Packed storage variables
- Efficient array operations
- Minimal external calls

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repo
2. Create a feature branch
3. Write tests for new features
4. Submit a pull request

## 📄 License

MIT

## 🙏 Acknowledgments

- **Patrick Collins** - Foundry course
- **Chainlink** - VRF and Automation
- **Foundry** - Development framework

---

**~ arman**

*Provably fair. Cryptographically secure. Unstoppable.*