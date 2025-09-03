# 🎓 Verifiable Credentials & Skill Ledger

A decentralized, tamper-proof registry for educational credentials, micro-certifications, and skill badges built on the Stacks blockchain. 🚀

## 🌟 Features

- **🔐 Tamper-Proof**: All credentials are stored immutably on the blockchain
- **🌍 Universal Verification**: Verify credentials globally without central authority
- **🎯 Skill Badges**: Issue and manage micro-certifications and skill badges
- **👨‍🏫 Authorized Issuers**: Only authorized institutions can issue credentials
- **📋 Endorsements**: Peer-to-peer skill endorsements system
- **⏰ Expiry Management**: Set expiration dates for time-sensitive credentials
- **🔍 Verification History**: Track all verification attempts with results

## 📋 Contract Overview

This smart contract enables:

- Educational institutions to issue verifiable credentials
- Professionals to collect and showcase skill badges
- Employers to verify candidate qualifications instantly
- Peer-to-peer skill endorsements
- Credential revocation by issuers when necessary

## 🛠 Core Functions

### For Contract Owner

#### `authorize-issuer`
Authorize an institution to issue credentials
```clarity
(authorize-issuer principal "Institution Name" authority-level)
```

#### `revoke-issuer-authorization`
Revoke an institution's authorization
```clarity
(revoke-issuer-authorization principal)
```

### For Authorized Issuers

#### `issue-credential`
Issue a new verifiable credential
```clarity
(issue-credential 
  recipient-principal
  "credential-type"
  "skill-name"
  skill-level
  "institution"
  expiry-date
  metadata-uri
  verification-hash
)
```

#### `issue-skill-badge`
Issue a skill badge or micro-certification
```clarity
(issue-skill-badge 
  recipient-principal
  "skill-name"
  badge-level
  prerequisites-list
  metadata-uri
)
```

#### `revoke-credential`
Revoke a previously issued credential
```clarity
(revoke-credential credential-id)
```

### For Anyone

#### `verify-credential`
Verify a credential and record the verification
```clarity
(verify-credential credential-id verification-result notes)
```

#### `endorse-skill`
Endorse someone's skill
```clarity
(endorse-skill "skill-name" recipient-principal endorsement-level notes)
```

## 🔍 Read-Only Functions

### Query Functions

- `get-credential(credential-id)` - Get credential details
- `get-skill-badge(badge-id)` - Get skill badge details
- `get-recipient-credentials(principal)` - Get all credentials for a user
- `get-recipient-badges(principal)` - Get all badges for a user
- `get-issuer-authorization(principal)` - Check issuer authorization status
- `is-credential-valid(credential-id)` - Check if credential is valid and not expired
- `is-authorized-issuer(principal)` - Check if principal can issue credentials

### Statistics

- `get-total-credentials()` - Total number of credentials issued
- `get-total-skill-badges()` - Total number of skill badges issued

## 🚀 Usage Examples

### 1. Authorize an Institution
```clarity
;; Only contract owner can do this
(contract-call? .verifiable-credentials-skill-ledger authorize-issuer 'SP123...UNIVERSITY "MIT" u5)
```

### 2. Issue a Degree Credential
```clarity
;; Authorized issuer issues a credential
(contract-call? .verifiable-credentials-skill-ledger issue-credential 
  'SP456...STUDENT 
  "Bachelor Degree"
  "Computer Science"
  u4
  "Massachusetts Institute of Technology"
  (some u1000000)  ;; expires at block 1000000
  (some "https://mit.edu/credentials/cs-bachelor")
  0x1234567890abcdef...
)
```

### 3. Issue a Skill Badge
```clarity
;; Issue a programming skill badge
(contract-call? .verifiable-credentials-skill-ledger issue-skill-badge
  'SP789...DEVELOPER
  "JavaScript Programming"
  u3
  (list u1 u2)  ;; requires credentials 1 and 2
  (some "https://badges.com/js-intermediate")
)
```

### 4. Verify a Credential
```clarity
;; Anyone can verify and record verification
(contract-call? .verifiable-credentials-skill-ledger verify-credential 
  u1 
  true 
  (some "Verified by employer during hiring process")
)
```

### 5. Endorse a Skill
```clarity
;; Endorse someone's skill
(contract-call? .verifiable-credentials-skill-ledger endorse-skill 
  "Python Programming" 
  'SP123...COLLEAGUE 
  u4 
  (some "Great work on the machine learning project")
)
```

## 🏗 Data Structure

### Credentials
- Unique ID with issuer and recipient information
- Skill name, level (1-10), and credential type
- Issue and expiry dates
- Metadata URI for additional information
- Verification hash for integrity
- Revocation status

### Skill Badges
- Badge-specific information with prerequisites
- Badge levels (1-5) for progression tracking
- Active/inactive status

### Authorizations
- Institution authorization with authority levels
- Authorization tracking and management

## 🔒 Security Features

- **Access Control**: Only authorized issuers can create credentials
- **Immutable Records**: All credentials are permanently recorded
- **Verification Tracking**: Complete audit trail of all verifications
- **Expiry Management**: Automatic validity checking with expiry dates
- **Revocation Support**: Issuers can revoke credentials when necessary

## 📊 Skill Levels

- **Credentials**: 1-10 (1=Beginner, 10=Expert)
- **Badges**: 1-5 (1=Basic, 5=Master)
- **Endorsements**: 1-5 (1=Novice, 5=Expert)

## 🔗 Integration

This contract can be integrated with:
- Educational institution systems
- HR and recruitment platforms
- Professional networking applications
- Skill assessment tools
- Corporate learning management systems

## 📞 Support

For questions about implementation or integration, please refer to the Stacks documentation or open an issue in this repository.

---

*Built with ❤️ on the Stacks blockchain for a decentralized future of education and skills verification.*
