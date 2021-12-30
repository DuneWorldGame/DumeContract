
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IMysteriousBox {
    function mint(address _to) external returns (bool);
}

contract MysteryBoxOnSale is
    Initializable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;

    address public usdt;

    address public dao;
    uint256 public personalMaximum;
    uint256 public startTimestamp;
    uint256 public endTimestamp;

    mapping(uint256 => mapping(address => uint256)) public userAmount; 
    mapping(uint256 => address) public mysteriousBoxs; 
    mapping(uint256 => uint256) public prices; 
    mapping(uint256 => uint256) public maxAmts; 
    mapping(address => uint256) public sales; 
    mapping(uint256 => uint256) public sold; 

    bool public startState;

    function initialize(
        uint256[] memory _prices,
        uint256[] memory _maxAmts,
        address[] memory _mysteriousBoxs,
        address _usdt,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _dao
    ) external initializer {
        __Ownable_init();
        for (uint256 i = 0; i < _prices.length; i++) {
            prices[i] = _prices[i];
            maxAmts[i] = _maxAmts[i];
            mysteriousBoxs[i] = _mysteriousBoxs[i];
        }
        usdt = _usdt;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        dao = _dao;
        personalMaximum = 10;
        setStartState(true);
    }

    function setStartTimestamp(uint256 _val) public onlyOwner returns (bool) {
        startTimestamp = _val;
        return true;
    }

    function setEndTimestamp(uint256 _val) public onlyOwner returns (bool) {
        endTimestamp = _val;
        return true;
    }

    function setPrices(uint256 _index, uint256 _val)
        public
        onlyOwner
        returns (bool)
    {
        prices[_index] = _val;
        return true;
    }

    function setSales(address _user, uint256 _val)
        public
        onlyOwner
        returns (bool)
    {
        sales[_user] = _val;
        return true;
    }

    function setMaxAmts(uint256 _index, uint256 _val)
        public
        onlyOwner
        returns (bool)
    {
        maxAmts[_index] = _val;
        return true;
    }

    function setSold(uint256 _index, uint256 _val)
        public
        onlyOwner
        returns (bool)
    {
        sold[_index] = _val;
        return true;
    }

    
    
    
    
    
    
    
    
    
    
    function buyMysteriousBox(
        uint256 _index,
        uint256 count,
        address _referrer,
        address _user
    ) public returns (bool) {
        require(startState, "It has been closed");
        require(
            sold[_index].add(count) <= maxAmts[_index],
            "Exceeds the maximum"
        );
        require(
            userAmount[_index][_user].add(count) <= personalMaximum,
            "Exceeding personal maximum"
        );
        require(startTimestamp < block.timestamp, "Not started yet");
        require(block.timestamp < endTimestamp, "The purchase has ended");
        IERC20Upgradeable(usdt).safeTransferFrom(
            _user,
            address(this),
            prices[_index].mul(count)
        ); 
        IERC20Upgradeable(usdt).safeTransfer(dao, prices[_index].mul(count)); 
        for (uint256 i = 0; i < count; i++) {
            IMysteriousBox(mysteriousBoxs[_index]).mint(_user); 
            sales[_referrer] = sales[_referrer].add(prices[_index]); 
            sold[_index] = sold[_index].add(1);
            userAmount[_index][_user] = userAmount[_index][_user].add(1);
        }
        return true;
    }

    function setPersonalMaximum(uint256 _personalMaximum)
        public
        onlyOwner
        returns (bool)
    {
        personalMaximum = _personalMaximum;
        return true;
    }

    function setDAO(address _dao) public onlyOwner returns (bool) {
        dao = _dao;
        return true;
    }

    function setStartState(bool _state) public onlyOwner returns (bool) {
        startState = _state;
        return true;
    }
}
