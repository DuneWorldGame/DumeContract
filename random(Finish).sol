// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Random is Initializable,OwnableUpgradeable{

    function initialize() external initializer {
       __Ownable_init();
    }
    
    function random(address address_, uint256 nonce_ ,uint256 randomMax_) external view returns (uint256){
        uint256 randomNumber = uint256(uint256(keccak256(abi.encodePacked(block.timestamp + 994732731 + randomMax_ + nonce_, address_, nonce_))) % randomMax_);
        return randomNumber;
    }    

}
