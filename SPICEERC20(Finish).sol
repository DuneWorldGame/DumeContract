// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SPICEERC20 is Initializable ,OwnableUpgradeable,ERC20Upgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;
    
    function initialize(string memory _name,string memory _symbol, address _to, uint256 _totalSupply) external initializer {
        __Ownable_init();
        __ERC20_init(_name,_symbol);
        _mint(_to, _totalSupply);
    }

    function mint(address account_, uint256 amount_) external onlyOwner returns(bool){
        _mint(account_, amount_);
        return true;
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }
    
    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ =
        allowance(account_, msg.sender).sub(
            amount_,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
    
}