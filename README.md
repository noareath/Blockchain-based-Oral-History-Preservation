# 📜 Blockchain-based Oral History Preservation

Welcome to a revolutionary platform for safeguarding the voices of endangered cultures! This Web3 project uses the Stacks blockchain and Clarity smart contracts to immutably record, store, and share oral histories—narratives, stories, and traditions that are at risk of being lost due to cultural erosion, language extinction, and globalization. By leveraging blockchain's tamper-proof nature, we ensure these invaluable cultural artifacts are preserved for future generations, with community-driven verification and incentives for contributors.

## ✨ Features

📝 Submit oral narratives as text, audio hashes, or IPFS links for immutable storage  
🔒 Authenticate contributors from endangered communities via verified identities  
✅ Community verification and curation to ensure authenticity  
💰 Token rewards for storytellers and verifiers to encourage participation  
🌍 Global access with optional privacy controls for sensitive cultural content  
📊 Search and discovery tools for researchers and educators  
🤝 Governance for community-led updates and dispute resolution  
🚫 Anti-duplication checks to maintain uniqueness  
🔄 Versioning for evolving narratives while preserving originals  
📈 Analytics for tracking cultural preservation impact  

## 🛠 How It Works

This project addresses the real-world problem of cultural heritage loss by providing a decentralized, secure repository for oral histories. It involves 8 smart contracts written in Clarity, handling everything from user registration to governance. Here's a breakdown:

### Smart Contracts Overview
1. **UserRegistry.clar**: Manages user registration and identity verification (e.g., linking to cultural affiliations).  
2. **NarrativeSubmission.clar**: Handles submission of oral histories, including hashing content for immutability.  
3. **StorageVault.clar**: Stores metadata and IPFS/content hashes on-chain for tamper-proof preservation.  
4. **VerificationEngine.clar**: Enables community voting to verify narrative authenticity.  
5. **RewardToken.clar**: A fungible token (STX-based or custom) for incentivizing contributors and verifiers.  
6. **AccessControl.clar**: Controls who can view or edit sensitive narratives (e.g., public vs. restricted access).  
7. **GovernanceDAO.clar**: Allows token holders to propose and vote on platform changes.  
8. **SearchIndexer.clar**: Provides querying functionality for discovering narratives by tags, languages, or regions.  

**For Storytellers (from Endangered Cultures)**  
- Register your identity using UserRegistry.clar to prove cultural affiliation.  
- Prepare your narrative (e.g., record audio, transcribe text, upload to IPFS).  
- Call NarrativeSubmission.clar with:  
  - A unique content hash (e.g., SHA-256 of the narrative).  
  - Title, description, language, and cultural tags.  
  - Optional IPFS CID for full content storage.  
Boom! Your story is timestamped and stored immutably via StorageVault.clar, earning you reward tokens from RewardToken.clar.  

**For Verifiers and Community Members**  
- Use VerificationEngine.clar to vote on narrative authenticity (requires holding reward tokens).  
- Call verify-narrative to confirm details and add endorsements.  
- Access GovernanceDAO.clar to propose improvements, like adding new cultural categories.  

**For Researchers and Educators**  
- Query narratives using SearchIndexer.clar with filters (e.g., by region or language).  
- View details via get-narrative-metadata in StorageVault.clar.  
- Respect access rules enforced by AccessControl.clar for protected content.  

That's it! A decentralized archive that empowers communities to preserve their heritage while fostering global awareness and collaboration.