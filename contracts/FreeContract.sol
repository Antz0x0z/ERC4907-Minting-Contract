// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FreeContract is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    
    struct NftItem {
        uint tokenId;
        uint256 price;
        address creator;
        bool isListed;
    }

    uint256 public listingPrice = 25000000 gwei;

    Counters.Counter private _listedItems;
    Counters.Counter private _tokenIds;

    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private tokens;
    
    mapping(address => uint256) public MintedPerAddress;
    mapping(string => bool) private _usedTokenURIs;
    mapping(uint => NftItem) private _idToNftItem;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(uint => uint)) private _ownedTokens;
    mapping(uint => uint) private _idToOwnedIndex;
    mapping(uint => uint) private _idToNftIndex;
    uint256 private Price;
    uint256[] private _allNfts;
    //Mint details
    string private URI = "";
    uint256 private total_supply = 5000;
    bool started_rental = false;
    /// @dev ERC721 Base Token URI
    string internal _baseTokenURI;

    event NftItemCreated(
        uint tokenId,
        uint price,
        address creator,
        bool isListed
    );

    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri,
        uint256 maxSupply,
        uint256 price
        ) 
        ERC721(name, symbol) {
        _baseTokenURI = baseUri;
        for (uint i = 1; i <= maxSupply; i++) {
            _listedItems.increment();
            _allNfts.push(i);
            mintToken(_baseTokenURI, price);
            _usedTokenURIs[baseUri] = false;
        }
        // Since we pre-mint to "owner", allow this contract to transfer on behalf of "owner" for sales.
             _setApprovalForAll(_msgSender(), address(this), true);
    }

    modifier CallerNotContract() {
        require(tx.origin == msg.sender, "The function caller is a contract!");
        _;
    }
    modifier MintCompliance() {
        require(msg.value >= Price, "Insufficent tokens for the transaction.");
        require(started_rental == true, "Rental period has not started!");
        // require(MintedPerAddress[msg.sender] < max_per_wallet, "Number allowed per address exceeded!");
        require(GetNumMinted() < total_supply, "Total supply has been reached");
        _;
    }

    function GetNumMinted() public view returns (uint256) {
        return tokens.current();
    }

    function setListingPrice(uint newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be at least 1 wei");
        listingPrice = newPrice;
    }

    function getNftItem(uint tokenId) public view returns (NftItem memory) {
        return _idToNftItem[tokenId];
    }

    function listedItemsCount() public view returns (uint) {
        return _listedItems.current();
    }

    function tokenURIExists(string memory tokenURI) public view returns (bool) {
        return _usedTokenURIs[tokenURI] == true;
    }

    function totalSupply() public view returns (uint) {
        return _allNfts.length;
    }

    function tokenByIndex(uint index) public view returns (uint) {
        require(index < totalSupply(), "Index out of bounds");
        return _allNfts[index];
    }

    function tokenOfOwnerByIndex(address owner, uint index)
        public
        view
        returns (uint)
    {
        require(index < ERC721.balanceOf(owner), "Index out of bounds");
        return _ownedTokens[owner][index];
    }

    function getAllNftsOnSale() public view returns (NftItem[] memory) {
        uint allItemsCounts = totalSupply();
        uint currentIndex = 0;
        NftItem[] memory items = new NftItem[](_listedItems.current());

        for (uint i = 0; i < allItemsCounts; i++) {
            uint tokenId = tokenByIndex(i);
            NftItem storage item = _idToNftItem[tokenId];

            if (item.isListed == true) {
                items[currentIndex] = item;
                currentIndex += 1;
            }
        }

        return items;
    }

    function getOwnedNfts() public view returns (NftItem[] memory) {
        uint ownedItemsCount = ERC721.balanceOf(msg.sender);
        NftItem[] memory items = new NftItem[](ownedItemsCount);

        for (uint i = 0; i < ownedItemsCount; i++) {
            uint tokenId = tokenOfOwnerByIndex(msg.sender, i);
            NftItem storage item = _idToNftItem[tokenId];
            items[i] = item;
        }

        return items;
    }

    function mintToken(string memory tokenURI, uint price)
        public
        payable
        returns (uint)
    {
        require(!tokenURIExists(tokenURI), "Token URI already exists");
        require(
            msg.value != listingPrice,
            "Price must be equal to listing price"
        );

        _tokenIds.increment();
        _listedItems.increment();
        tokens.increment();

        uint newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        _createNftItem(newTokenId, price);
        _usedTokenURIs[tokenURI] = true;

        return newTokenId;
    }

    function buyNft(uint tokenId) public payable {
        uint256 price = _idToNftItem[tokenId].price;
        address owner = ERC721.ownerOf(tokenId);

        require(msg.sender != owner, "You already own this NFT");
        require(msg.value == price, "Please submit the asking price");

        _idToNftItem[tokenId].isListed = false;
        _listedItems.decrement();

        _transfer(owner, msg.sender, tokenId);
        payable(owner).transfer(msg.value);
    }

    function placeNftOnSale(uint tokenId, uint newPrice) public payable {
        require(
            ERC721.ownerOf(tokenId) == msg.sender,
            "You are not owner of this nft"
        );
        require(
            _idToNftItem[tokenId].isListed == false,
            "Item is already on sale"
        );
        require(
            msg.value != listingPrice,
            "Price must be equal to listing price"
        );

        _idToNftItem[tokenId].isListed = true;
        _idToNftItem[tokenId].price = newPrice;
        _listedItems.increment();
    }

    function _createNftItem(uint tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1 wei");

        _idToNftItem[tokenId] = NftItem(tokenId, price, msg.sender, true);

        emit NftItemCreated(tokenId, price, msg.sender, true);
    }

    function getPrice() public view returns (uint256) {
        return Price;
    }

    function setPrice(uint256 new_price) public onlyOwner {
        Price = new_price;
    }

    // Condition for rental start.
    function toggleRental() public onlyOwner {
        started_rental = !started_rental;
    }

    //Get the current ethereum block timestamp.
    function block_timestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function WithdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer has failed.");
    }

    function burnToken(uint256 tokenId) external virtual onlyOwner{
      _burn(tokenId);
    }
    
    /// @dev Provide a Base URI for Token Metadata
    function uri(uint256 _tokenid, string memory _uri)
        private
        pure
        returns (string memory){
        return
            string(
                abi.encodePacked(
                    "ipfs://",
                    _uri,
                    "/",
                    Strings.toString(_tokenid),
                    ".json"
                )
            );
    }

    function getURI(uint256 _tokenid)
        public
        view
        returns (string memory){
            return uri(_tokenid, _baseTokenURI);
    }
}
