
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";











interface IRandom{
    function random(address address_, uint256 nonce_ ,uint256 randomMax_) external view returns (uint256);
}

interface IStarshipNft {

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

    function nftInfo(uint256 _id) external view returns(NftInfo memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external ;
    function _cutFuel(uint256 _nftId,uint256 _val) external  returns (bool);
    function getStarshipLevel(uint256 _nftId) external view returns (uint256);
    function setNftInfo(uint256 i,uint256 _signingExpDays, uint256 _coolDownTimestamp,uint256 _fuel) external returns(bool);
}

contract Main is Initializable,ERC721HolderUpgradeable,OwnableUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;

    struct DuneInfo {
        uint256 requiredMp;
        uint256 fuelCost;
        uint256 requiredRank; 
        uint256 sandworm;
        uint256 successRate;
        uint256 reward;
        bool state;
    }

    mapping(uint256 => DuneInfo) public duneInfo;
    mapping(address => uint256) public _balance;

    uint256 public fee;
    address public feeDao;
    address public starshipNft;
    uint256 public coolTimeInterval;
    address public SPICE;
    address randomAddress;

    event Mining( bool state,address from,uint256 level,uint256 reward);

    /**
    初始化*/
    
    function initialize(address _starshipNft,address _SPICE,address _randomAddress,address _feeDao,uint256 _fee) external initializer {
        __Ownable_init();
        starshipNft = _starshipNft;
        SPICE = _SPICE;
        randomAddress = _randomAddress;
        fee = _fee;
        setDuneInfo(0,100,5,0,3000,7825,41*1e18,true);
        setDuneInfo(1,200,10,0,3400,7535,82*1e18,true);
        setDuneInfo(2,300,15,0,3800,7245,123*1e18,true);

        setDuneInfo(3,400,20,1,4200,6955,168*1e18,true);
        setDuneInfo(4,500,25,1,4600,6665,210*1e18,true);
        setDuneInfo(5,600,30,1,5000,6375,252*1e18,true);

        setDuneInfo(6,700,35,2,5400,6085,309*1e18,true);
        setDuneInfo(7,800,40,2,5800,5795,353*1e18,true);
        setDuneInfo(8,900,45,2,6200,5505,397*1e18,true);

        setDuneInfo(9,1000,50,3,6600,5215,485*1e18,true);
        setDuneInfo(10,1100,55,3,7000,4925,534*1e18,true);
        setDuneInfo(11,1200,60,3,7400,4635,582*1e18,true);

        setDuneInfo(12,1300,65,4,7800,4345,726*1e18,true);
        setDuneInfo(13,1400,70,4,8200,4055,781*1e18,true);
        setDuneInfo(14,1500,75,4,8600,3765,837*1e18,true);
        feeDao = _feeDao;
        coolTimeInterval = 24*3600;
    }

    function setRandomAddress(address _addr)  public onlyOwner returns(bool)  {
        randomAddress = _addr;
        return true;
    }

    function setCoolTimeInterval(uint256 _val) public onlyOwner returns(bool){
        coolTimeInterval = _val;
        return true;
    }

    function setFeeDao(address _addr) public onlyOwner returns(bool){
        feeDao = _addr;
        return true;
    }

    function setStarshipNftAddr(address _addr)  public onlyOwner returns(bool)  {
        starshipNft = _addr;
        return true;
    }

    function setFee(uint256 _val) public onlyOwner returns(bool){
        fee = _val;
        return true;
    }
    
    function setDuneInfo(
        uint256 i, 
        uint256 _requiredMp,
        uint256 _fuelCost,
        uint256 _requiredRank,
        uint256 _sandworm,
        uint256 _successRate,
        uint256 _reward,
        bool _state
        ) public onlyOwner returns(bool) {
        duneInfo[i] = DuneInfo({
            requiredMp:_requiredMp,
            fuelCost:_fuelCost,
            requiredRank:_requiredRank,
            sandworm:_sandworm,
            successRate:_successRate,
            reward:_reward,
            state:_state
        });
        return true;
    }


    
    function mining(uint256 _starshipNftId,uint256 _DuneIndex) external returns(bool){
        uint256 nowSigningExpDays = IStarshipNft(starshipNft).nftInfo(_starshipNftId).signingExpDays;
        uint256 nowFuel = IStarshipNft(starshipNft).nftInfo(_starshipNftId).fuel;
        uint256 nowMp = IStarshipNft(starshipNft).nftInfo(_starshipNftId).mp;
        uint256 _coolDownTimestamp = IStarshipNft(starshipNft).nftInfo(_starshipNftId).coolDownTimestamp;

        require(duneInfo[_DuneIndex].state,"Status is closed");
        require(IStarshipNft(starshipNft).ownerOf(_starshipNftId) == msg.sender,"You are not the owner");
        require(nowSigningExpDays > 0,"insufficient signingExpDays");
        
        if(_coolDownTimestamp != 0){
            require(_coolDownTimestamp<block.timestamp,"Please wait for the freezing time");
        }
        require(nowFuel >= duneInfo[_DuneIndex].fuelCost,"insufficient fuel");
        require(nowMp >= duneInfo[_DuneIndex].requiredMp,"insufficient mp");
        require(IStarshipNft(starshipNft).getStarshipLevel(_starshipNftId) >= duneInfo[_DuneIndex].requiredRank,"insufficient rank");
        
        
        
        IStarshipNft(starshipNft).setNftInfo(
            _starshipNftId,
            nowSigningExpDays.sub(1),
            block.timestamp.add(coolTimeInterval),
            nowFuel.sub(duneInfo[_DuneIndex].fuelCost));
        uint256 _denominator = 10000;
        uint256 nowRandomCont = IRandom(randomAddress).random(msg.sender,block.number,10000);
        uint256 successRateCont = _denominator.sub(duneInfo[_DuneIndex].sandworm.mul(_denominator.sub(IStarshipNft(starshipNft).nftInfo(_starshipNftId).escapeRate)));
        uint256 failureRateCont = _denominator.sub(successRateCont); 
        if(nowRandomCont > failureRateCont){
            
            uint256 reward = duneInfo[_DuneIndex].reward;
            uint256 _reward = reward.mul(_denominator.sub(fee)).div(_denominator);
            uint256 _fee = reward.sub(_reward);
            _balance[msg.sender] = _balance[msg.sender].add(_reward);
            IERC20Upgradeable(SPICE).safeTransfer(feeDao,_fee);
            emit Mining( true,msg.sender,_DuneIndex,_reward);
        }else{
            
            emit Mining( false,msg.sender,_DuneIndex,0);
        }
        
        
        return true;
    }

    
    function withdraw(address _erc20,uint256 _val) public onlyOwner returns(bool){
        IERC20Upgradeable(_erc20).safeTransfer(msg.sender,_val);
        return true;
    }

    
    function claim() public returns(bool){
        uint256 claimAmt = _balance[msg.sender];
        IERC20Upgradeable(SPICE).safeTransfer(msg.sender,claimAmt);
        _balance[msg.sender] = 0;
        return true;
    }
    

}
