// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title BaseLoop NFT Pass
 * @notice Exclusive NFT for early $BLUP holders on Base Network.
 * Only wallets holding >=200 BLUP can mint, max 2 per wallet.
 */

interface IBaseLoopToken {
    function balanceOf(address account) external view returns (uint256);
}

contract BaseLoopNFTPass {
    string public name = "BaseLoop OG Pass";
    string public symbol = "BLOOPASS";

    uint256 public constant MAX_SUPPLY = 100;
    uint8 public constant MAX_PER_WALLET = 2;
    uint256 public constant REQUIRED_BLUP = 200 * (10 ** 18);

    address public owner;
    address public immutable blupTokenAddress;
    uint256 public totalMinted;
    string public baseURI;

    mapping(uint256 => address) private _owners;
    mapping(address => uint8) public mintedCount;
    mapping(uint256 => string) private _tokenURIs;

    event Mint(address indexed minter, uint256 indexed tokenId);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    modifier onlyOwner() {
        require(msg.sender == owner, "owner only");
        _;
    }

    constructor(address _blupTokenAddress, string memory _baseURI) {
        owner = msg.sender;
        blupTokenAddress = _blupTokenAddress;
        baseURI = _baseURI;
    }

    // ------------------------
    // Mint Logic
    // ------------------------
    function mint() external {
        require(totalMinted < MAX_SUPPLY, "max supply reached");
        require(mintedCount[msg.sender] < MAX_PER_WALLET, "max per wallet reached");

        uint256 blupBalance = IBaseLoopToken(blupTokenAddress).balanceOf(msg.sender);
        require(blupBalance >= REQUIRED_BLUP, "not enough BLUP to mint");

        uint256 tokenId = totalMinted + 1;
        totalMinted++;
        _owners[tokenId] = msg.sender;
        mintedCount[msg.sender]++;

        emit Mint(msg.sender, tokenId);
        emit Transfer(address(0), msg.sender, tokenId);
    }

    // ------------------------
    // Metadata
    // ------------------------
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "invalid token");
        return string(abi.encodePacked(baseURI, uint2str(tokenId), ".json"));
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    // ------------------------
    // Ownership / Withdraw
    // ------------------------
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero address");
        owner = newOwner;
    }

    // ------------------------
    // ERC721 Minimal Functions
    // ------------------------
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _owners[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        require(msg.sender == from || msg.sender == owner, "not authorized");
        require(_owners[tokenId] == from, "not token owner");
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    // ------------------------
    // Internal Helper
    // ------------------------
    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 length;
        while (j != 0) { length++; j /= 10; }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }
}
