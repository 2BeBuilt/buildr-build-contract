// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../lib/solmate/src/tokens/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

error FixTokenId();
error NotEOA();
error TransferFailed();
error NotTokenOwner();
error NotTheBuildr();

/// @title buildr contract
/// @author 2bb.dev
/// @notice this contract spawns buildrs
contract BuildrBuild is ERC721 {
    using Strings for uint256;

    enum Web3District {
        Nomads,
        ContentMaestros,
        Founders,
        Investors,
        Devs
    }

    struct Outputs {
        uint256 tokenId;
        uint256 balance;
        Web3District district;
        uint256 order;
    }

    mapping(uint256 => uint256) private map;
    mapping(uint256 => Web3District) private buildrDistrict;
    mapping(uint256 => string) private buildrInfo;
    mapping(uint256 => mapping(Web3District => uint256)) private buildrBalance;

    Outputs[] public outputs;

    string public baseURI;
    uint256 private constant TOTAL_SUPPLY = 4024;
    uint256 private constant INFRA_COST = 0.005 ether;
    address private buildr;

    event Received(
        address indexed caller,
        uint256 indexed amount,
        string indexed message
    );

    event MapChange(
        uint256 indexed mapToken1,
        uint256 indexed mapToken2,
        uint256 indexed token2
    );

    modifier onlyEOA() {
        if (msg.sender != tx.origin) {
            revert NotEOA();
        }
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        buildr = msg.sender;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value, "Kudos");
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value, "Fallback was called");
    }

    function mintBuildr(uint256 _tokenId) external payable onlyEOA {
        if (msg.value < INFRA_COST) {
            revert TransferFailed();
        }
        if (_tokenId > TOTAL_SUPPLY || _tokenId < 1) {
            revert FixTokenId();
        }
        _mint(msg.sender, _tokenId);
    }

    /// @notice destination token is burned
    /// _token1 -> _token2 => _token2 is burned afterwards
    function mapChange(uint256 _token1, uint256 _token2) external {
        if (
            ownerOf(_token1) != ownerOf(_token2) ||
            ownerOf(_token2) != msg.sender
        ) {
            revert NotTokenOwner();
        }

        uint256 tmp_token1 = mapView(_token1);
        uint256 tmp_token2 = mapView(_token2);

        resetBuildrInfo(_token2);
        _burn(_token2);

        map[_token1] = tmp_token2;
        map[_token2] = tmp_token1;

        emit MapChange(map[_token1], map[_token2], _token2);
    }

    function fundBuildr(
        uint256 _tokenId,
        Web3District _district
    ) external payable {
        if (_tokenId > TOTAL_SUPPLY || _tokenId < 1) {
            revert FixTokenId();
        }
        buildrBalance[_tokenId][_district] += msg.value;
    }

    function withdrawETH() external {
        uint256 balance = address(this).balance;
        (bool transferTx /*memory data*/, ) = buildr.call{value: balance}("");
        if (!transferTx) {
            revert TransferFailed();
        }
    }

    function editAllDetails_v2(
        Web3District _district,
        uint256 _tokenId,
        string calldata _ipfsCID
    ) external {
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotTokenOwner();
        }
        editDistrict(_district, _tokenId);
        editBuildrDetail(_ipfsCID, _tokenId);
    }

    function editBuildrDistrict(
        Web3District _district,
        uint256 _tokenId
    ) external {
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotTokenOwner();
        }
        editDistrict(_district, _tokenId);
    }

    function editBuildrInfo(
        string calldata _ipfsCID,
        uint256 _tokenId
    ) external {
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotTokenOwner();
        }
        editBuildrDetail(_ipfsCID, _tokenId);
    }

    function changeBuildr(address _buildr) external {
        if (msg.sender != buildr) {
            revert NotTheBuildr();
        }
        buildr = _buildr;
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        super.transferFrom(from, to, id);
        resetBuildrInfo(id);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function getBuildrInfo(
        uint256 _tokenId
    ) public view returns (string memory) {
        if (_tokenId > TOTAL_SUPPLY || _tokenId < 1) {
            revert FixTokenId();
        }
        return buildrInfo[_tokenId];
    }

    function getInfraCosts() public pure returns (uint256) {
        return INFRA_COST;
    }

    function getTokenMap(uint256 _tokenId) public view returns (uint256) {
        if (_tokenId > TOTAL_SUPPLY || _tokenId < 1) {
            revert FixTokenId();
        }
        return mapView(_tokenId);
    }

    function getFullMap(
        uint256 _start,
        uint256 _limit
    ) public view returns (Outputs[] memory) {
        if (_start < 1) {
            revert FixTokenId();
        }
        Outputs[] memory mapOutput = new Outputs[](_limit);
        for (uint256 i = 0; i < _limit; i++) {
            uint256 id = _start + i;
            if (id <= 4024) {
                mapOutput[i].tokenId = id;
                mapOutput[i].balance = getBuildrTotalBalance(id);
                mapOutput[i].district = buildrDistrict[id];
                mapOutput[i].order = mapView(id);
            }
        }
        return mapOutput;
    }

    function getFullMap_v2(
        uint256 _start,
        uint256 _limit
    ) public view returns (Outputs[] memory) {
        if (_start < 1) {
            revert FixTokenId();
        }
        Outputs[] memory mapOutput = new Outputs[](_limit);
        for (uint256 i = 0; i < _limit; i++) {
            uint256 id = _start + i;
            if (id <= 4024) {
                mapOutput[i].district = buildrDistrict[id];
                mapOutput[i].balance = getBuildrDistrictBalance(
                    _start + i,
                    buildrDistrict[id]
                );
                mapOutput[i].tokenId = id;
            }
        }
        return mapOutput;
    }

    function getDistrictMap_v2(
        Web3District _district,
        uint256 _start,
        uint256 _limit
    ) public view returns (Outputs[] memory) {
        if (_start < 1) {
            revert FixTokenId();
        }
        Outputs[] memory mapOutput = new Outputs[](_limit);
        uint256 temp;
        for (uint256 i = 0; i < _limit; i++) {
            uint256 id = _start + i;
            if (
                (buildrDistrict[id] == _district) &&
                (_ownerOf[id] != address(0))
            ) {
                mapOutput[temp].tokenId = id;
                mapOutput[temp].balance = getBuildrDistrictBalance(
                    id,
                    _district
                );
                mapOutput[temp].district = buildrDistrict[id];
                temp++;
            }
        }
        return mapOutput;
    }

    function getUnassignedBuildrs(
        uint256 _start,
        uint256 _limit
    ) public view returns (Outputs[] memory) {
        if (_start < 1) {
            revert FixTokenId();
        }
        Outputs[] memory mapOutput = new Outputs[](_limit);
        uint256 temp;
        for (uint256 i = 0; i < _limit; i++) {
            uint256 id = _start + i;
            if (
                (buildrDistrict[id] == Web3District(0)) &&
                (_ownerOf[id] == address(0) && (id <= 4024))
            ) {
                mapOutput[temp].tokenId = id;
                mapOutput[temp].balance = getBuildrTotalBalance(id);
                temp++;
            }
        }
        return mapOutput;
    }

    function getDistrict(uint256 _tokenId) public view returns (Web3District) {
        if (_tokenId > TOTAL_SUPPLY || _tokenId < 1) {
            revert FixTokenId();
        }
        return buildrDistrict[_tokenId];
    }

    function getBuildrDistrictBalance(
        uint256 _tokenId,
        Web3District _district
    ) public view returns (uint256) {
        return buildrBalance[_tokenId][_district];
    }

    function getBuildrTotalBalance(
        uint256 _tokenId
    ) public view returns (uint256) {
        uint256 balance;
        for (uint256 i = 0; i < 5; i++) {
            Web3District district = Web3District(i);
            balance += buildrBalance[_tokenId][district];
        }
        return balance;
    }

    function totalSupply() public pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function getBuildr() public view returns (address) {
        return buildr;
    }

    function resetBuildrInfo(uint256 _tokenId) private {
        delete buildrInfo[_tokenId];
        buildrDistrict[_tokenId] = Web3District.Nomads;
    }

    function editDistrict(Web3District _district, uint256 _tokenId) private {
        buildrDistrict[_tokenId] = _district;
    }

    function editBuildrDetail(
        string calldata _ipfsCID,
        uint256 _tokenId
    ) private {
        buildrInfo[_tokenId] = _ipfsCID;
    }

    function mapView(uint256 _tokenId) private view returns (uint256) {
        return map[_tokenId] == 0 ? _tokenId : map[_tokenId];
    }
}
