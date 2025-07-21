# Decentralized Public School Bus Driver Training Program

A comprehensive blockchain-based system for managing school bus driver certification, training, and performance evaluation using Clarity smart contracts on the Stacks blockchain.

## System Overview

This decentralized system manages the complete lifecycle of school bus driver training and certification through five interconnected smart contracts:

### 1. Driver Certification Contract (`driver-certification.clar`)
- Manages commercial driver's license (CDL) validation
- Tracks license renewal dates and status
- Maintains driver certification levels
- Handles certification upgrades and downgrades

### 2. Safety Training Scheduling Contract (`safety-training.clar`)
- Coordinates mandatory defensive driving courses
- Schedules training sessions and tracks attendance
- Manages training completion certificates
- Handles make-up sessions for missed training

### 3. Background Check Processing Contract (`background-check.clar`)
- Processes criminal history verification
- Manages reference checks and employment history
- Tracks background check status and expiration
- Handles appeals and re-evaluations

### 4. Route Familiarization Contract (`route-familiarization.clar`)
- Manages new driver training on specific bus routes
- Tracks route completion and proficiency testing
- Assigns mentors and supervising drivers
- Records route-specific certifications

### 5. Performance Evaluation Contract (`performance-evaluation.clar`)
- Tracks driver safety records and incident reports
- Manages performance reviews and ratings
- Records disciplinary actions and improvements
- Maintains historical performance data

## Key Features

- **Decentralized Governance**: No single point of failure or control
- **Transparent Records**: All training and certification data on-chain
- **Automated Compliance**: Smart contract enforcement of requirements
- **Immutable History**: Permanent record of driver qualifications
- **Real-time Status**: Instant verification of driver credentials

## Data Types

### Driver Information
- Driver ID (principal)
- Personal details (name, contact)
- License information (CDL number, class, expiration)
- Certification status and level

### Training Records
- Training type and completion status
- Instructor information and ratings
- Completion dates and certificates
- Make-up sessions and remedial training

### Performance Metrics
- Safety incident counts and severity
- Performance review scores
- Disciplinary actions and resolutions
- Route-specific performance data

## Contract Interactions

While contracts operate independently, they share common data structures:

1. **Driver Registration**: Initial setup across all contracts
2. **Status Updates**: Certification changes affect training requirements
3. **Compliance Checking**: Background and training status validation
4. **Performance Impact**: Incidents affect certification and training needs

## Security Features

- **Access Control**: Role-based permissions for different user types
- **Data Validation**: Input sanitization and format checking
- **Error Handling**: Comprehensive error codes and messages
- **Audit Trail**: Complete history of all changes and updates

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for deployment

### Installation

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts: \`clarinet deploy\`

### Usage

Each contract provides public functions for:
- Registration and enrollment
- Status updates and modifications
- Query functions for data retrieval
- Administrative functions for management

## Testing

Comprehensive test suite covers:
- Contract deployment and initialization
- All public function calls
- Error conditions and edge cases
- Data integrity and validation
- Performance and gas optimization

## Deployment

Contracts are designed for deployment on:
- Stacks mainnet for production use
- Stacks testnet for development and testing
- Local Clarinet environment for development

## Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit pull request

## License

MIT License - see LICENSE file for details

## Support

For questions or issues:
- Create GitHub issue
- Contact development team
- Check documentation wiki
