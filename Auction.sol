pragma solidity ^0.4.24;

contract ERC721Interface {
    //ERC721
    function balanceOf(address owner) public view returns (uint256 _balance);
    function ownerOf(uint256 tokenID) public view returns (address owner);
    function transfer(address to, uint256 tokenID) public returns (bool);
    function approve(address to, uint256 tokenID) public;
    function takeOwnership(uint256 tokenID) public;
    function totalSupply() public view returns (uint);
    function owns(address owner, uint256 tokenID) public view returns (bool);
    function allowance(address claimant, uint256 tokenID) public view returns (bool);
    function transferFrom(address from, address to, uint256 tokenID) public returns (bool);
    function createLand(address owner) external returns (uint);
}


contract ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable {
    address public owner;
    mapping(address => bool) admins;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddAdmin(address indexed admin);
    event DelAdmin(address indexed admin);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }


    function addAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0));
        admins[_adminAddress] = true;
        emit AddAdmin(_adminAddress);
    }

    function delAdmin(address _adminAddress) external onlyOwner {
        require(admins[_adminAddress]);
        admins[_adminAddress] = false;
        emit DelAdmin(_adminAddress);
    }

    function isAdmin(address _adminAddress) public view returns (bool) {
        return admins[_adminAddress];
    }
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}


contract AuctionContract is Ownable {

    ERC20 public arconaToken;

    struct Auction {
        address owner;
        address token;
        uint tokenId;
        uint startPrice;
        //uint startTime;
        uint stopTime;
        address winner;
        uint executeTime;
        uint finalPrice;
    }

    mapping(address => bool) public acceptedTokens;
    mapping(uint256 => Auction) public auctions;
    //token => token_id = auction id
    mapping (address => mapping (uint => uint)) public auctionIndex;
    mapping(address => uint256[]) private ownedAuctions;
    uint private lastAuctionId;
    uint defaultExecuteTime = 3 days;

    event ReceiveCreateAuction(address from, uint tokenId, address token);
    event AddAcceptedToken(address indexed token);
    event DelAcceptedToken(address indexed token);
    event NewAuction(address indexed owner, uint tokenId, uint auctionId);


    constructor(address _token) public {
        arconaToken = ERC20(_token);
    }


    function () public payable {
        revert();
    }


    function addAcceptedToken(address _token) onlyAdmin external {
        require(_token != address(0));
        acceptedTokens[_token] = true;
        emit AddAcceptedToken(_token);
    }


    function delAcceptedToken(address _token) onlyAdmin external {
        require(acceptedTokens[_token]);
        acceptedTokens[_token] = false;
        emit DelAcceptedToken(_token);
    }


    function setDefaultExecuteTime(uint _days) onlyAdmin external {
        defaultExecuteTime = _days * 1 days;
    }


    function isAcceptedToken(address _token) public view returns (bool) {
        return acceptedTokens[_token];
    }


    function receiveCreateAuction(address _from, uint _tokenId, address _token, uint _startPrice, uint _duration) public {
        require(isAcceptedToken(_token));
        _createAuction(_from, _token, _tokenId, _startPrice, _duration);
        emit ReceiveCreateAuction(_from, _tokenId, _token);
    }


    function _createAuction(address _from, address _token, uint _tokenId, uint _startPrice, uint _duration) internal returns (uint) {
        require(ERC721Interface(_token).transferFrom(_from, this, _tokenId));

        auctions[++lastAuctionId] = Auction({
            owner : _from,
            token : _token,
            tokenId : _tokenId,
            startPrice : _startPrice,
            //startTime : now,
            stopTime : now + (_duration * 1 days),
            winner : address(0),
            executeTime : now + (_duration * 1 days) + defaultExecuteTime,
            finalPrice : 0
            });

        auctionIndex[_token][_tokenId] = lastAuctionId;
        ownedAuctions[_from].push(lastAuctionId);

        emit NewAuction(_from, _tokenId, lastAuctionId);
        return lastAuctionId;
    }


    function setWinner(address _winner, uint _auctionId, uint _finalPrice, uint _executeTime) onlyAdmin external {
        require(now > auctions[_auctionId].stopTime);
        require(auctions[_auctionId].winner == address(0));
        require(_finalPrice >= auctions[_auctionId].startPrice);
        auctions[_auctionId].winner = _winner;
        auctions[_auctionId].finalPrice = _finalPrice;
        if (_executeTime > 0) {
            auctions[_auctionId].executeTime = _executeTime;
        }
    }


    function getToken(uint _auctionId) external {
        require(now <= auctions[_auctionId].executeTime);
        require(msg.sender == auctions[_auctionId].winner);
        require(arconaToken.transferFrom(msg.sender, this, auctions[_auctionId].finalPrice));
        //TODO FEE
        require(ERC721Interface(auctions[_auctionId].token).transfer(auctions[_auctionId].winner, auctions[_auctionId].tokenId));
    }

    //TODO условия отменя
    function cancelAuction(uint _auctionId) external {
        require(msg.sender == auctions[_auctionId].owner);
        require(now > auctions[_auctionId].stopTime);

        require(ERC721Interface(auctions[_auctionId].token).transfer(auctions[_auctionId].owner, auctions[_auctionId].tokenId));
    }


    function ownerAuctionCount(address _owner) external view returns (uint256) {
        return ownedAuctions[_owner].length;
    }


    function auctionsOf(address _owner) external view returns (uint256[]) {
        return ownedAuctions[_owner];
    }
}
