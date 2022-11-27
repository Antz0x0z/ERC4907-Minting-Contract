//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC4907.sol";


contract NFT_Rental is ERC4907, Ownable, ReentrancyGuard {
    //Needed imports
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private tokens;
    //Mint details
    string private URI = "";
    uint256 private total_supply = 10000;
    uint256 public price = 1 ether;
    // uint256 private max_per_wallet = 3;
    bool started_rental = false;

    mapping(address => uint256) public MintedPerAddress;
   
    constructor(string memory _name, string memory _symbol) 
    ERC4907(_name,_symbol){}

    // Check if the function caller is not another contract.
    modifier CallerNotContract{
        require(tx.origin == msg.sender, "The function caller is a contract!");
        _;
    }
    modifier MintCompliance(){
        require(msg.value >= price, "Insufficent ETH for the transaction.");
        require(started_rental == true, "Rental period has not started!");
        // require(MintedPerAddress[msg.sender] < max_per_wallet, "Number allowed per address exceeded!");
        require(GetNumMinted() < total_supply, "Total supply has been reached");
        _;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked("ipfs://", URI, _tokenId.toString()));
    }

    function setURI(string memory new_URI) public onlyOwner {
		URI = new_URI;
	}

    function contractURI() public view returns (string memory) {
		return URI;
	}

    function GetNumMinted() public view returns(uint256){
        return tokens.current();
    }

    function CreateToken() public payable MintCompliance CallerNotContract returns (uint256){
        tokens.increment();
        MintedPerAddress[msg.sender] += 1;
        uint256 tokenId = GetNumMinted();
        _safeMint(msg.sender, tokenId);
        return tokenId;
    }

    function getPrice() public view returns(uint256){
        return price;
    }

    function setPrice(uint256 new_price) public onlyOwner{
        price = new_price;
    }

    // Condition for rental start.
    function toggleRental() public onlyOwner { 
        started_rental = !started_rental;
    }

    //Get the current ethereum block timestamp.
    function block_timestamp() public view returns(uint256){
        return block.timestamp;
    }

    function WithdrawFunds() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer has failed.");
  }
}