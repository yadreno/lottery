// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.1/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@5.0.1/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@5.0.1/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@5.0.1/access/Ownable.sol";

contract MyToken is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;
    bool public winnersAvail = false;
    uint[] public winnerIds = new uint[](10);

    uint public constant PRICE = 0.005 ether;
    string public baseTokenURI;
    event MintNft(address senderAddress, uint256 nftToken);
    
    constructor(address initialOwner, string memory baseURI)
        ERC721("Blast Lottery February", "BLF")
        Ownable(initialOwner)
    {
        setBaseURI(baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function mint() public payable {
        require(msg.value >= PRICE, "Not enough ether to purchase NFTs.");
        uint256 _tokenId = _nextTokenId++;
        _safeMint(msg.sender, _tokenId);
        emit MintNft(msg.sender, _tokenId);
    }


    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }




    function getRandomTokenIds(uint seed) private  {
        require(seed > 0, "Seed value must be greater than 0");
        
        uint allTokenIds = totalSupply()-1;
        
        
        for (uint i = 0; i < winnerIds.length; i++) {
            uint randIndex = uint(keccak256(abi.encodePacked(seed, block.timestamp, i))) % allTokenIds;
            winnerIds[i] = randIndex;
        }
        

    }





    function distributeRewards()  public  onlyOwner {
        require(!winnersAvail, "Token IDs already generated");
        uint totalSupplyValue = totalSupply();
        require(totalSupplyValue > 0, "No tokens available");

        uint seed = totalSupplyValue; 
        require(seed > 0, "Seed value must be greater than 0");
        getRandomTokenIds(seed);

        address[] memory winnerAddresses = new address[](winnerIds.length);
        
        for (uint i = 0; i < winnerIds.length; i++) {
            winnerAddresses[i] = ownerOf(winnerIds[i]);
        }

        uint totalBalance = address(this).balance; 
        
       
        uint rewardAmount = totalBalance / winnerIds.length;
        
        for (uint i = 0; i < winnerAddresses.length; i++) {
            bool success = payable(winnerAddresses[i]).send(rewardAmount);
            require(success, "Reward distribution failed");
        }

        winnersAvail = true; 
        
    }



	function getWinnerList() public view returns (uint[] memory) {
		return winnerIds;
	}



}