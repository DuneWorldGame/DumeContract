
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

contract BuyCommonMysteryBox is
    Initializable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;

    address public SPICE;
    address public dao;


    mapping(uint256 => address) public mysteriousBoxs; 
    mapping(uint256 => uint256) public prices; 

    bool public startState;

    function initialize(
        uint256[] memory _prices,
        
        address[] memory _mysteriousBoxs,
        address _SPICE,
        address _dao
    ) external initializer {
        __Ownable_init();
        for (uint256 i = 0; i < _prices.length; i++) {
            prices[i] = _prices[i];
            
            mysteriousBoxs[i] = _mysteriousBoxs[i];
        }
        SPICE = _SPICE;
        dao = _dao;
        setStartState(true);
    }

    function setPrices(uint256 _index, uint256 _val)
        public
        onlyOwner
        returns (bool)
    {
        prices[_index] = _val;
        return true;
    }


    function buyMysteriousBox(
        uint256 _index,
        uint256 count,
        address _user
    ) public returns (bool) {
        require(startState,"It has been closed");
        IERC20Upgradeable(SPICE).safeTransferFrom(
            _user,
            address(this),
            prices[_index].mul(count)
        ); 
        IERC20Upgradeable(SPICE).safeTransfer(dao, prices[_index].mul(count)); 
        for (uint256 i = 0; i < count; i++) {
            IMysteriousBox(mysteriousBoxs[_index]).mint(_user); 
        }
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
