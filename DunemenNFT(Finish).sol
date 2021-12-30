
pragma solidity ^0.8.0;








import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";


interface IRandom{
    function random(address address_, uint256 nonce_ ,uint256 randomMax_) external view returns (uint256);
}


interface IMysteryBox{
    function burn(uint256 _id) external returns(bool);
}

contract DunemenNFT is Initializable,ERC721EnumerableUpgradeable,ERC721HolderUpgradeable,OwnableUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;

    mapping(address => bool) public distributor;
    
   
    mapping(uint256 => string) private _tokenURIs;

    uint256 public tokenIdIndex;

    string public _baseURI_;

    address randomAddress;

    mapping(uint256 => uint256[]) public possibilitys;

    mapping(uint256 => address) public mysteryBoxs;

    struct NftInfo {
        uint256 updateBlockNumber;
        uint256 level;
        uint256 mp; 
        uint256 decorate1;
        uint256 decorate2;
        uint256 decorate3;
        uint256 backup1;
        uint256 backup2;
    }

    struct MPInterval {
        uint256 base;
        uint256 stepSize;
    }

    mapping(uint256 => NftInfo) internal _nftInfo;
    mapping(uint256 => MPInterval) internal _mpInterval;

    function nftInfo(uint256 _id) external view returns(NftInfo memory) {
        require( _nftInfo[_id].updateBlockNumber != block.number,"Please go to the next block to check");
        return _nftInfo[_id];
    }

    function mpInterval(uint256 _type) public view returns(MPInterval memory) {
        return _mpInterval[_type];
    }

    function setNftInfo(
        uint256 i,
        uint256 updateBlockNumber,
        uint256 level, 
        uint256 mp,
        uint256 decorate1,
        uint256 decorate2,
        uint256 decorate3,
        uint256 backup1,
        uint256 backup2
        ) public onlyOwner returns(bool) {
        _nftInfo[i] = NftInfo({
            updateBlockNumber:updateBlockNumber,
            level:level,
            mp:mp,
            decorate1:decorate1,
            decorate2:decorate2,
            decorate3:decorate3,
            backup1:backup1,
            backup2:backup2
        });
        return true;
    }

    function setMPInterval(
        uint256 i,
        uint256 base,
        uint256 stepSize
        ) public onlyOwner returns(bool) {
        _mpInterval[i] = MPInterval({
            base:base,
            stepSize:stepSize
        });
        return true;
    }

    function setMysteryBoxs(uint256 _index,address _addr ) public onlyOwner returns(bool) {
        mysteryBoxs[_index] = _addr;
        return true;
    }

    function setPossibilitys(uint256 _index,uint16[5] memory _possibilitys ) public onlyOwner returns(bool){
        possibilitys[_index] = _possibilitys;
        return true;
    }
    

  
   
    function initialize(string memory _name,string memory _symbol,address _randomAddress) external initializer {
       __ERC721_init(_name,_symbol);
       __Ownable_init();
       setPossibilitys(0,[5500,3300,750,350,100]);
       setPossibilitys(1,[0,7000,2200,500,300]);
       setPossibilitys(2,[0,0,8500,1000,500]);

       setMPInterval(0,10,30);
       setMPInterval(1,40,40);
       setMPInterval(2,80,40);
       setMPInterval(3,120,40);
       setMPInterval(4,160,40);

       randomAddress = _randomAddress;
    }
    

    function setBaseURI(string memory _str)  public onlyOwner returns(bool)  {
        _baseURI_ = _str;
        return true;
    }

   
    function setDistributor(address _address ,bool _state) public onlyOwner returns(bool) {
        distributor[_address] = _state;
        return true;
    }
    


    function mint(address _to,uint256 _type) external returns(bool) {
        require(distributor[msg.sender],"distributor no good");
        mint_(_to,_type);
        return true;
    }

   
    function burn(uint256 _id) external returns(bool) {
        require(msg.sender == ownerOf(_id),"No approved");
        super._burn(_id);
        if (bytes(_tokenURIs[_id]).length != 0) {
            delete _tokenURIs[_id];
        }
        return true;
    }
    

 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return _baseURI_;
    }

   
    function randomToLevel(uint256 _type) internal view returns(uint256) {
        uint256 _random = IRandom(randomAddress).random(msg.sender,block.number,10000);
        uint256 _m = 0;
        for(uint256 i = 0;i<possibilitys[_type].length;i++){
            _m = _m.add(possibilitys[_type][i]);
            if(_random < _m){
                return i;
            }
        }
        return 0;
    }

    function randomToMP(uint256 _level) internal view returns(uint256) {
        uint256 base = _mpInterval[_level].base;
        uint256 stepSize = _mpInterval[_level].stepSize;
        uint256 _random = IRandom(randomAddress).random(msg.sender,block.number,stepSize);
        return base.add(_random);
    }

    function mint_(address _to,uint256 _type) internal returns(bool){
        uint256 thisId = tokenIdIndex;
        super._safeMint(_to, thisId);
        tokenIdIndex = tokenIdIndex.add(1);

        uint256 _randomToLevel = randomToLevel(_type);
        uint256 _randomToMP = randomToMP(_randomToLevel);

        _nftInfo[thisId] = NftInfo({
            updateBlockNumber:block.number,
            level:_randomToLevel,
            mp:_randomToMP,
            decorate1:IRandom(randomAddress).random(msg.sender,1,10000),
            decorate2:IRandom(randomAddress).random(msg.sender,2,10000),
            decorate3:IRandom(randomAddress).random(msg.sender,3,10000),
            backup1:IRandom(randomAddress).random(msg.sender,4,10000),
            backup2:IRandom(randomAddress).random(msg.sender,5,10000)
        });

        return true;
    }

   
    function unboxing(
        uint256 _type,
        uint256 _id,
        address _user
    ) public returns (bool) {
        IERC721Upgradeable(mysteryBoxs[_type]).safeTransferFrom(
            _user,
            address(this),
            _id
        );
        IMysteryBox(mysteryBoxs[_type]).burn(_id);
        mint_(_user, _type);
        return true;
    }

    function setRandomAddress(address _addr)  public onlyOwner returns(bool)  {
        randomAddress = _addr;
        return true;
    }
    

}
