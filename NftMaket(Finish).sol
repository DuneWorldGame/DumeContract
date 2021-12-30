
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


contract NftMaket is Initializable,ERC721HolderUpgradeable,OwnableUpgradeable{

    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;


    
    struct OrderInfo {
        bool autoriser;
        bool state;
        uint256 updateBlockTimestamp;
        address seller;
        address buyer;
        uint256 price;
        address nftAddr;
        uint256 nftId;
    }


    
    uint256 public orderId;
    mapping(uint256 => OrderInfo) public _orderInfo;

    
    uint256[] public sellListForOrderId;

    mapping(address => mapping(address => uint256[])) public _mySaleIdList;
    mapping(address => uint256[]) public _pecifyNftSaleIdList;
    mapping(address => uint256) public _balance;
    mapping(address => bool) public specifyNftAddress;      

    uint256 public fee;
    address public feeDao;
    address public SPICE;
    

    event SellNft(address _nftAddr, uint256 _nftId , uint256 _price);
    event BuyNft(address _nftAddr, uint256 _saleId);
    event Claim(address _user, uint256 _val);
    event UnSellNft( address _nftAddr, uint256 _SaleId );

    
    
    
    function initialize(uint256 _fee,address _feeDao,address _SPICE) external initializer {
        __Ownable_init();
        fee = _fee; 
        feeDao = _feeDao;
        SPICE = _SPICE;
    }

    function allOrderIdListLength() public view returns(uint256){
        return sellListForOrderId.length;
    }

    function mySaleIdListLength(address _user ,address _nftAddr) public view returns(uint256){
        return _mySaleIdList[_user][_nftAddr].length;
    }

    function pecifyNftSaleIdListLength(address _nftAddr) public view returns(uint256){
        return _pecifyNftSaleIdList[_nftAddr].length;
    }
    
    
    function mySaleForNftList(address _user ,address _nftAddr,uint256 _page ,uint256 _count) public view returns(uint256[] memory){
        uint256 length = _mySaleIdList[_user][_nftAddr].length;
        uint256 maxPage = length.div(_count); 
        require(_page <= maxPage,"_page no good");
        uint256 startIndex = _page.mul(_count);
        uint256 endIndex = startIndex.add(_count)>length? length:startIndex.add(_count);
        uint256[] memory newList;
        uint256 newListNumber = endIndex.sub(startIndex);
        newList = new uint256[](newListNumber);
        uint256 _i = 0;
        for(uint256 i = startIndex;i<endIndex;i++){
            newList[_i] = _mySaleIdList[_user][_nftAddr][startIndex];
            _i++;
        }
        return newList;
    }

    
    function saleForNftList(uint256 _page ,uint256 _count) public view returns(uint256[] memory){
        uint256 length = sellListForOrderId.length;
        uint256 maxPage = length.div(_count); 
        require(_page <= maxPage,"_page no good");
        uint256 startIndex = _page.mul(_count);
        uint256 endIndex = startIndex.add(_count)>length? length:startIndex.add(_count);
        uint256[] memory newList;
        uint256 newListNumber = endIndex.sub(startIndex);
        newList = new uint256[](newListNumber);
        uint256 _i = 0;
        for(uint256 i = startIndex;i<endIndex;i++){
            newList[_i] = sellListForOrderId[i];
            _i++;
        }
        return newList;
    }

    
    function saleForSpecifyNftList(address _nftAddr,uint256 _page ,uint256 _count) public view returns(uint256[] memory){
        uint256 length = _pecifyNftSaleIdList[_nftAddr].length;
        uint256 maxPage = length.div(_count); 
        require(_page <= maxPage,"_page no good");
        uint256 startIndex = _page.mul(_count);
        uint256 endIndex = startIndex.add(_count)>length? length:startIndex.add(_count);
        uint256[] memory newList;
        uint256 newListNumber = endIndex.sub(startIndex);
        newList = new uint256[](newListNumber);
        uint256 _i = 0;
        for(uint256 i = startIndex;i<endIndex;i++){
            newList[_i] = i;
            _i++;
        }
        return newList;
    }
    
    
    
    function sellNft( address _nftAddr, uint256 _nftId , uint256 _price) public returns(bool){

        require(specifyNftAddress[_nftAddr],"No authorization");
        
        IERC721Upgradeable(_nftAddr).safeTransferFrom(msg.sender,address(this),_nftId);

        _orderInfo[orderId] = OrderInfo({
            autoriser:true,
            state:true,
            updateBlockTimestamp:block.timestamp,
            seller:msg.sender,
            buyer:address(0),
            price:_price,
            nftAddr:_nftAddr,
            nftId:_nftId
        });

        uint256 thisSaleId = orderId;

        sellListForOrderId.push(thisSaleId);
        _mySaleIdList[msg.sender][_nftAddr].push(thisSaleId);
        _pecifyNftSaleIdList[_nftAddr].push(thisSaleId);
        
        orderId=orderId.add(1);
        emit SellNft(_nftAddr, _nftId , _price);
        return true;
    }

    
    function buyNft(address _nftAddr, uint256 _SaleId) public returns(bool){ 
        require(_orderInfo[_SaleId].state,"state no good");
        require(_orderInfo[_SaleId].autoriser,"autoriser no good");
        require(specifyNftAddress[_nftAddr],"No authorization");

        IERC20Upgradeable(SPICE).safeTransferFrom(msg.sender,address(this),_orderInfo[_SaleId].price);

        uint256 _fee = _orderInfo[_SaleId].price.mul(fee).div(10000);
        uint256 _profit = _orderInfo[_SaleId].price.sub(_fee);
        IERC20Upgradeable(SPICE).safeTransfer(feeDao,_fee);

        address oldOwnerAddress = _orderInfo[_SaleId].seller;
        _balance[oldOwnerAddress] = _profit;

        uint256 _nftId = _orderInfo[_SaleId].nftId;
        IERC721Upgradeable(_nftAddr).approve(msg.sender, _nftId);
        IERC721Upgradeable(_nftAddr).safeTransferFrom(address(this),msg.sender,_nftId); 
        
        
        _orderInfo[_SaleId].state = false;
        _orderInfo[_SaleId].buyer = msg.sender;

        
        delete _mySaleIdList[msg.sender][_nftAddr][_SaleId];
        delete _pecifyNftSaleIdList[_nftAddr][_SaleId];
        delete sellListForOrderId[_SaleId];

        emit BuyNft(_nftAddr,_SaleId);
        return true;
    }

    
    function unSellNft( address _nftAddr, uint256 _SaleId ) public returns(bool){
        require(_orderInfo[_SaleId].seller==msg.sender,"seller no good"); 
        uint256 _nftId = _orderInfo[_SaleId].nftId;
        IERC721Upgradeable(_nftAddr).approve(msg.sender, _nftId);
        IERC721Upgradeable(_nftAddr).safeTransferFrom(address(this),msg.sender,_nftId);

        _orderInfo[_SaleId].state = false;
        delete _mySaleIdList[msg.sender][_nftAddr][_SaleId];
        delete _pecifyNftSaleIdList[_nftAddr][_SaleId];
        delete sellListForOrderId[_SaleId];
        emit UnSellNft(_nftAddr,_SaleId);
        return true;
    }

    
    function claim() public returns(bool){
        uint256 myBalance = _balance[msg.sender];
        uint256 thisBalance = IERC20Upgradeable(SPICE).balanceOf(address(this));
        require(myBalance<=thisBalance,"Insufficient balance");  
        IERC20Upgradeable(SPICE).safeTransfer(msg.sender,myBalance);
        _balance[msg.sender] = 0;
        emit Claim(msg.sender, myBalance);
        return true;
    }

    
    function setOrderInfo(uint256 _SaleId,bool _autoriser,bool _state,address _seller,address _buyer,uint256 _price,address _nftAddr,uint256 _nftId) public onlyOwner returns(bool){
        _orderInfo[_SaleId] = OrderInfo({
            autoriser:_autoriser,
            state:_state,
            updateBlockTimestamp:block.timestamp,
            seller:_seller,
            buyer:_buyer,
            price:_price,
            nftAddr: _nftAddr,
            nftId: _nftId
        });
        return true;
    }


    function setFee(uint256 _val) public onlyOwner returns(bool){
        fee = _val;
        return true;
    }

    function setFeeDao(address _addr) public onlyOwner returns(bool){
        feeDao = _addr;
        return true;
    }

    function withdraw(address _erc20,uint256 _val) public onlyOwner returns(bool){
        IERC20Upgradeable(_erc20).safeTransfer(msg.sender,_val);
        return true;
    }

    function setSpecifyNftAddress(address _addr,bool _type) public onlyOwner returns(bool){
        specifyNftAddress[_addr] = _type;
        return true;
    }



}
