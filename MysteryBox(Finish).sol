
pragma solidity ^0.8.0;








import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

contract  MysteryBox is Initializable,ERC721EnumerableUpgradeable ,OwnableUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;

    mapping(address => bool) public distributor;
    
    
    mapping(uint256 => string) private _tokenURIs;

    uint256 public tokenIdIndex;

    string public _baseURI_;
  
    
    function initialize(string memory _name,string memory _symbol) external initializer {
       __ERC721_init(_name,_symbol);
       __Ownable_init();
    }
    

    function setBaseURI(string memory _str)  public onlyOwner returns(bool)  {
        _baseURI_ = _str;
        return true;
    }

  
    function setDistributor(address _address ,bool _state) public onlyOwner returns(bool) {
        distributor[_address] = _state;
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

}
