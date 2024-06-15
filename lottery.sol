// SPDX-License-Identifier: MIT
interface IBlastPoints {
  function configurePointsOperator(address operator) external;
  function configurePointsOperatorOnBehalf(address contractAddress, address operator) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts@5.0.1/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@5.0.1/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@5.0.1/access/Ownable.sol";

contract BLF2 is ERC721, ERC721Enumerable, Ownable {
    uint256 private _nextTokenId;
    uint[] private winnerIds ;
    address[] private winnerAdresses ;

    uint public constant PRICE = 0.001 ether;
    uint public constant LUCKY = 30;
    event MintNft(address senderAddress, uint256 nftToken);

    mapping (uint => uint) nftIDs;

    // be sure to use the appropriate testnet/mainnet BlastPoints address
    // BlastPoints Testnet address: 0x2fc95838c71e76ec69ff817983BFf17c710F34E0
    // BlastPoints Mainnet address: 0x2536FE9ab3F511540F2f9e2eC2A805005C3Dd800    
    constructor(address initialOwner)
        ERC721("Daily Lottery", "LBDL")
        Ownable(initialOwner)
    {
        IBlastPoints(0x2536FE9ab3F511540F2f9e2eC2A805005C3Dd800).configurePointsOperator(initialOwner);
    }



    function mint(uint256 _amount) public payable {
        require((_amount >= 1) && (_amount <= 100), "Amount must be between 1 and 10.");
        require(msg.value >= PRICE * _amount, "Not enough ether to purchase NFTs.");
        for (uint256 i = 0; i < _amount; i++) {
            uint256 _tokenId = _nextTokenId++;
            _safeMint(msg.sender, _tokenId);
            emit MintNft(msg.sender, _tokenId);
            nftIDs[_tokenId] = 1;// 1 - new; 0 - loss; 2 - win
        }
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (nftIDs[tokenId] == 0) {
            return "ipfs://QmdudEDSAFW4f56U7QCLz5sd2w4qD8boQGCpz3jzExCGuP";
        }
        if (nftIDs[tokenId] == 1) {
            return "ipfs://Qmc61QLzRQZ4HdaD4s11PMBHFbKnT6pH2UpNdW2VQBqrdL";
        }
        if (nftIDs[tokenId] == 2) {
            return "ipfs://QmUdjmT5rP7KUb4cBqaXZ94EJW97YpZbcGeatRAxuCzE5W";
        } else{
            return "";
        }              
    }



    // Функция для получения списка победителей
    function getLastWinnerTickets() public view returns (uint[] memory) {
        return winnerIds;
    }


    // Функция для получения списка победителей
    function getLastWinnerList() public view returns (address[] memory) {
        return winnerAdresses;
    }


    // Функция для получения статуса билета
    function getTicketStatus(uint256 tokenId) public view returns (uint256) {
        return nftIDs[tokenId];
    }


    function numberTicketsDrawing()  public view returns (uint256) {

        uint totalSupplyValue = totalSupply();
        uint256 count = 0;
        for (uint256 i = totalSupplyValue-1; i > 0; i--) {
            if (nftIDs[i] == 1) {
                count++;
            } else {
                break ;
            }
        }
        return count;
    }

    function distributeRewards()  public onlyOwner {
        winnerIds = new uint[](0);
        winnerAdresses = new address[](0);
        uint totalSupplyValue = totalSupply();
        uint256 count = numberTicketsDrawing();


        require(count > 20, "There are not enough tickets, the drawing will be postponed to the next day");

        uint[] memory numbers = getRandomNumbers(totalSupplyValue-count, totalSupplyValue-1, 10);

        for (uint256 i = totalSupplyValue-1; i > 0; i--) {
            if (nftIDs[i] == 1) {
                if (_isElementInArray(numbers, i)) { // если совпадает с массивом выигрышных билетов
                    nftIDs[i] = 2;
                    winnerIds.push(i);
                } else {
                    nftIDs[i] = 0;
                }
            } else {
                break ;
            }
        }
        
        uint totalBalance = address(this).balance; // Получаем общий баланс контракта
        uint rewardAmount = (totalBalance - 100000) / winnerIds.length;
        address winnerAddresse;
        for (uint i = 0; i < winnerIds.length; i++) {
            winnerAddresse = ownerOf(winnerIds[i]);
            winnerAdresses.push(winnerAddresse);

            bool success = payable(winnerAddresse).send(rewardAmount);
            require(success, "Reward distribution failed");            
        }        


    }

    function getRandomNumbers(uint start, uint end, uint count) internal view returns (uint[] memory) {
        uint[] memory numbers = new uint[](count);
        for (uint i = 0; i < count; i++) {
            numbers[i] = _getRandomNumber(start, end,  i);
        }
        return numbers;
    }

    function _getRandomNumber(uint start, uint end, uint i) internal view returns (uint) {
        return start + (uint(keccak256(abi.encodePacked(block.timestamp, i, msg.sender))) % (end - start + 1));
    }

    function _isElementInArray(uint[] memory array, uint element) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == element) {
                return true;
            }
        }
        return false;
    }



}
