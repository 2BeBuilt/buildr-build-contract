# BuildrBuild Contract Overview

The `BuildrBuild` contract is designed for creating, funding, and managing NFTs across various Web3 Districts, offering functionalities like minting, funding, and information editing. The contract operates within a predefined total supply limit and allows interactions with NFTs through a range of public functions.

## Contract Address
`0xD8d21E5f6ee5C70c5Cdf993e86c3ED6e3D6aC0DE`

## Constants
- **Total Supply**: 4024 tokens
- **Infrastructure Cost (INFRA_COST)**: 0.005 ether

## Enum: Web3District
- `Nomads == 0`
- `ContentMaestros == 1`
- `Founders == 2`
- `Investors == 3`
- `Devs == 4`

## Struct: Outputs
Contains `tokenId`, `balance`, `district`, and `order` for representing buildr details.

## Public Functions

### Minting
- **mintBuildr(uint256 _tokenId)**: Mints a new NFT. Requires sending at least `INFRA_COST`.

### Funding
- **fundBuildr(uint256 _tokenId, Web3District _district)**: Allocates ETH to fund a buildr within a specified district.

### Withdrawal
- **withdrawETH()**: Allows contract owner to withdraw all accumulated ETH.

### Editing Details
- **editAllDetails_v2(Web3District _district, uint256 _tokenId, string _ipfsCID)**: Updates a buildr's district and IPFS CID.
- **editBuildrDistrict(Web3District _district, uint256 _tokenId)**: Updates the district of a buildr.
- **editBuildrInfo(string _ipfsCID, uint256 _tokenId)**: Updates the IPFS CID of a buildr.

### Transfers
- **transferFrom(address from, address to, uint256 id)**: Transfers a buildr to a new owner and resets its info.

## View Functions

### Information Retrieval
- **tokenURI(uint256 tokenId)**: Fetches the metadata URI for a buildr.
- **getBuildrInfo(uint256 _tokenId)**: Retrieves the IPFS CID containing a buildr's details.
- **getInfraCosts()**: Returns the cost required to mint a buildr.
- **getTokenMap(uint256 _tokenId)**: Retrieves the token mapping.
- **getDistrict(uint256 _tokenId)**: Gets the district assignment of a buildr.

### Balances and Mapping
- **getBuildrDistrictBalance(uint256 _tokenId, Web3District _district)**: Shows the balance of a buildr within a district.
- **getBuildrTotalBalance(uint256 _tokenId)**: Displays the total balance of a buildr across all districts.

### Advanced Mapping and Listings
- **getFullMap(uint256 _start, uint256 _limit)**: Lists mappings with additional details.
- **getFullMap_v2(uint256 _start, uint256 _limit)**: Displays buildrs with district assignments.
- **getDistrictMap_v2(Web3District _district, uint256 _start, uint256 _limit)**: Shows all buildrs within a specified district with pagination.
- **getUnassignedBuildrs(uint256 _start, uint256 _limit)**: Retrieves unassigned buildrs with pagination.

## Modifiers and Errors
- **onlyEOA**: Ensures functions are called by externally owned accounts only.
- **Errors**: Includes `FixTokenId`, `NotEOA`, `TransferFailed`, and `NotTokenOwner`.

## Author
- **alexthebuildr**
