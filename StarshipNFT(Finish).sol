
pragma solidity ^0.8.0;


import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";


interface IRandom{
    function random(address address_, uint256 nonce_ ,uint256 randomMax_) external view returns (uint256);
}


interface IMysteryBox{
    function burn(uint256 _id) external returns(bool);
}

interface IDunemenNft{

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

    function nftInfo(uint256 _id) external view returns(NftInfo memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external ;
}

interface IHarvesterNft {

    struct NftInfo {
        uint256 updateBlockNumber;
        uint256 level;
        uint256 passengers; 
        uint256 decorate1;
        uint256 decorate2;
        uint256 decorate3;
        uint256 backup1;
        uint256 backup2;
    }

    function nftInfo(uint256 _id) external view returns(NftInfo memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external ;
}

interface ICarryallNft {

    struct NftInfo {
        uint256 updateBlockNumber;
        uint256 level;
        uint256 escape; 
        uint256 decorate1;
        uint256 decorate2;
        uint256 decorate3;
        uint256 backup1;
        uint256 backup2;
    }

    function nftInfo(uint256 _id) external view returns(NftInfo memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external ;
}

contract StarshipNFT is Initializable,ERC721HolderUpgradeable,ERC721EnumerableUpgradeable ,OwnableUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;

    address public dunemenNft;
    address public harvesterNft;
    address public carryallNft;

    uint256 public harvesterMaxMembers;

    mapping(address => bool) public distributor;
    
    mapping(uint256 => string) private _tokenURIs;

    uint256 public tokenIdIndex;

    string public _baseURI_;

    address public randomAddress;

    uint256 public fuelPirce;
    address public SPICE;
    address public feeDao;
    uint256[3] public starshipContractPirce;
    uint256[3] public starshipContractDays;


    struct NftInfo {
        uint256 dunemenAmt;
        uint256 harvesterAmt;
        uint256 carryallAmt;

        uint256 mp;
        uint256 escapeRate; 
        uint256 signingExpDays; 
        uint256 coolDownTimestamp;

        uint256 [] dunemenNftId;
        uint256 [] harvesterNftId;
        uint256 carryallNftId;
        uint256 fuel;
        
        uint256 backup1;
        uint256 backup2;
    }

    mapping(uint256 => NftInfo) internal _nftInfo;

    function nftInfo(uint256 _id) public view returns(NftInfo memory) {
        
        return _nftInfo[_id];
    }

  

    function setNftInfo(uint256 i,uint256 _signingExpDays, uint256 _coolDownTimestamp,uint256 _fuel) public returns(bool) {
        require(distributor[msg.sender],"distributor no good");
        _nftInfo[i].signingExpDays = _signingExpDays;
        _nftInfo[i].coolDownTimestamp = _coolDownTimestamp;
        _nftInfo[i].fuel = _fuel;
        return true;
    }



    /**
    初始化*/
    
    function initialize(
        string memory _name,
        string memory _symbol,
        address _randomAddress,
        address _dunemenNft,
        address _harvesterNft,
        address _carryallNft,
        address _SPICE,
        uint256 _fuelPirce,
        address _feeDao
        ) external initializer {
       __ERC721_init(_name,_symbol);
       __Ownable_init();
       randomAddress = _randomAddress;
       dunemenNft = _dunemenNft;
       harvesterNft = _harvesterNft;
       carryallNft = _carryallNft;
       harvesterMaxMembers = 10;
       SPICE = _SPICE;
       fuelPirce = _fuelPirce;
       feeDao = _feeDao;
        starshipContractPirce[0] = 25000000000000000000;
        starshipContractPirce[1] = 45000000000000000000;
        starshipContractPirce[2] = 80000000000000000000;
        starshipContractDays[0] = 7;
        starshipContractDays[1] = 14;
        starshipContractDays[2] = 80;
    }

    function setStarshipContractDays(uint256 _type,uint256 _val)  public onlyOwner returns(bool)  {
        starshipContractDays[_type] = _val;
        return true;
    }

    function setStarshipContractPirce(uint256 _type,uint256 _val)  public onlyOwner returns(bool)  {
        starshipContractPirce[_type] = _val;
        return true;
    }

    function setFuelPirce(uint256 _val)  public onlyOwner returns(bool)  {
        fuelPirce = _val;
        return true;
    }

    function setHarvesterMaxMembers(uint256 _val)  public onlyOwner returns(bool)  {
        harvesterMaxMembers = _val;
        return true;
    }
    
    function setDunemenNftAddr(address _addr)  public onlyOwner returns(bool)  {
        dunemenNft = _addr;
        return true;
    }

    function setHarvesterNftAddr(address _addr)  public onlyOwner returns(bool)  {
        harvesterNft = _addr;
        return true;
    }

    function setCarryallNftAddr(address _addr)  public onlyOwner returns(bool)  {
        carryallNft = _addr;
        return true;
    }

    function setRandomAddress(address _addr)  public onlyOwner returns(bool)  {
        randomAddress = _addr;
        return true;
    }

    function setBaseURI(string memory _str)  public onlyOwner returns(bool)  {
        _baseURI_ = _str;
        return true;
    }

 
    function setDistributor(address _address ,bool _state) public onlyOwner returns(bool) {
        distributor[_address] = _state;
        return true;
    }

    function setFeeDao(address _addr) public onlyOwner returns(bool){
        feeDao = _addr;
        return true;
    }
    


    function mint(address _to) external returns(bool) {
        require(distributor[msg.sender],"distributor no good");
        uint256 _id = tokenIdIndex;
        super._safeMint(_to, _id);
        tokenIdIndex = tokenIdIndex.add(1);
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



    function getStarshipLevel(uint256 _nftId) public view returns (uint256){

        uint256 _dunemenAmt = _nftInfo[_nftId].dunemenAmt;
        uint256 _harvesterAmt = _nftInfo[_nftId].harvesterAmt;
        uint256 _mp = _nftInfo[_nftId].mp;

        if(_dunemenAmt>=10 && _harvesterAmt>=5 && _mp>=1300){
            return 4;
        }

        if(_dunemenAmt>=8 && _harvesterAmt>=4 && _mp>=1000){
            return 3;
        }

        if(_dunemenAmt>=6 && _harvesterAmt>=3 && _mp>=700){
            return 2;
        }

        if(_dunemenAmt>=4 && _harvesterAmt>=2 && _mp>=400){
            return 1;
        }

        return 0;
    }
    

    function getSigningExpDays(uint256 _nftId) public view returns (uint256){
        return _nftInfo[_nftId].signingExpDays;
    }


    function createStarship(uint256[] memory _dunemenNftId,uint256[] memory _harvesterNftId,uint256 _carryallNftId) public  returns (bool){
        uint256 allMp = 0;
        for(uint256 i = 0;i<_dunemenNftId.length;i++){
            allMp = allMp.add(IDunemenNft(dunemenNft).nftInfo(_dunemenNftId[i]).mp);
            require(IDunemenNft(dunemenNft).ownerOf(_dunemenNftId[i]) == msg.sender,"Owner error");
            IERC721Upgradeable(dunemenNft).safeTransferFrom(msg.sender,address(this),_dunemenNftId[i]);
        }
        uint256 allMembers =0;
        for(uint256 j =0;j<_harvesterNftId.length;j++){
            allMembers = allMembers.add(IHarvesterNft(harvesterNft).nftInfo(_harvesterNftId[j]).passengers);
            require(IHarvesterNft(harvesterNft).ownerOf(_harvesterNftId[j]) == msg.sender,"Owner error");
            IERC721Upgradeable(harvesterNft).safeTransferFrom(msg.sender,address(this),_harvesterNftId[j]);
        }
        require(ICarryallNft(carryallNft).ownerOf(_carryallNftId) == msg.sender,"Owner error");
        IERC721Upgradeable(carryallNft).safeTransferFrom(msg.sender,address(this),_carryallNftId);
        require(allMembers >= _dunemenNftId.length,"Members error");
        require(allMp >= 100,"MP is less than 100");
        require(harvesterMaxMembers >= _harvesterNftId.length ,"Overload");

        uint256 _escapeRate = ICarryallNft(carryallNft).nftInfo(_carryallNftId).escape;
        
        uint256 thisId = tokenIdIndex;
        super._safeMint(msg.sender, thisId);
        tokenIdIndex = tokenIdIndex.add(1);
        _nftInfo[thisId] = NftInfo({
            dunemenAmt:_dunemenNftId.length,
            harvesterAmt:_harvesterNftId.length,
            carryallAmt:1,
            mp:allMp,
            escapeRate:_escapeRate, 
            signingExpDays:0, 
            coolDownTimestamp:0,
            dunemenNftId:_dunemenNftId,
            harvesterNftId:_harvesterNftId,
            carryallNftId:_carryallNftId,
            fuel:0,
            backup1:IRandom(randomAddress).random(msg.sender,1,10000),
            backup2:IRandom(randomAddress).random(msg.sender,2,10000)
        });
        return true;
    }


    function disbandStarship(uint256 _nftId) public  returns (bool){
        address _owner = ownerOf(_nftId);
        require(_nftInfo[_nftId].signingExpDays == 0,"The number of signing days needs to be 0");
        require(_nftInfo[_nftId].coolDownTimestamp < block.timestamp,"Freeze time is not over");
        require(_owner == msg.sender,"Owner error");
        
        
        for(uint256 i =0; i<_nftInfo[_nftId].dunemenNftId.length;i++){
            uint256 _dunemenNftId = _nftInfo[_nftId].dunemenNftId[i];
            IDunemenNft(dunemenNft).approve(_owner,_dunemenNftId);
            IERC721Upgradeable(dunemenNft).safeTransferFrom(address(this),_owner,_dunemenNftId);
        }
        for(uint256 j =0; j<_nftInfo[_nftId].harvesterNftId.length;j++){
            uint256 _harvesterNftId = _nftInfo[_nftId].harvesterNftId[j];
            IHarvesterNft(harvesterNft).approve(_owner,_harvesterNftId);
            IERC721Upgradeable(harvesterNft).safeTransferFrom(address(this),_owner,_harvesterNftId);
        }
        uint256 _carryallNftId = _nftInfo[_nftId].carryallNftId;
        ICarryallNft(carryallNft).approve(_owner,_carryallNftId);
        IERC721Upgradeable(carryallNft).safeTransferFrom(address(this),_owner,_carryallNftId);
        
        _burn(_nftId);
        return true;
    }

    function addFuel(uint256 _nftId,uint256 _amt) public  returns (bool){
        uint256 _val = _amt.mul(fuelPirce);
        IERC20Upgradeable(SPICE).safeTransferFrom(msg.sender,address(this),_val);
        IERC20Upgradeable(SPICE).safeTransfer(feeDao,_val);
        _addFuel(_nftId,_amt);
        return true;
    }

    function _addFuel(uint256 _nftId,uint256 _val) internal  returns (bool){
        _nftInfo[_nftId].fuel = _nftInfo[_nftId].fuel.add(_val);
        return true;
    }
    function _cutFuel(uint256 _nftId,uint256 _val) external  returns (bool){
        require(distributor[msg.sender],"distributor no good");
        require(_nftInfo[_nftId].fuel >= _val, "Not enough fuel");
        _nftInfo[_nftId].fuel = _nftInfo[_nftId].fuel.sub(_val);
        return true;
    }

    function creationContract(uint256 _nftId,uint256 _type) public  returns (bool){
        IERC20Upgradeable(SPICE).safeTransferFrom(msg.sender,address(this),starshipContractPirce[_type]);
        IERC20Upgradeable(SPICE).safeTransfer(feeDao,starshipContractPirce[_type]);
        _nftInfo[_nftId].signingExpDays = _nftInfo[_nftId].signingExpDays.add(starshipContractDays[_type]);
        return true;
    }

}




