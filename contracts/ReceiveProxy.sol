pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./uniswap/IUniswapExchange.sol";
import "./uniswap/IUniswapFactory.sol";


contract ReceiveProxy is Ownable {
    using SafeMath for uint;
    IUniswapFactory factory;

    bytes32[] public splitKeys;

    mapping(bytes32=>address) public assets;
    mapping(bytes32=>address) public recipients;
    mapping(bytes32=>uint8) public percentages;

    uint8 constant SWAP_THRESHOLD = 95;

    constructor(address _factory) public {
        factory = IUniswapFactory(_factory);
    }

    function() external payable {
        for (uint i = 0; i < splitKeys.length; i++) {
            bytes32 splitKey = splitKeys[i];
            address token = assets[splitKey];
            uint256 amountETH = msg.value.mul(percentages[splitKey]).div(100);
            IUniswapExchange exchange = IUniswapExchange(factory.getExchange(token));
            uint256 minToken = exchange.getEthToTokenInputPrice(amountETH).mul(SWAP_THRESHOLD).div(100);
            uint256 deadline = (now + 1 hours).mul(1000);
            exchange.ethToTokenTransferInput.value(amountETH)(minToken, deadline, owner());
        }
    }

    function addSplits(address[] calldata _assets, address[] calldata _receipients, uint8[] calldata _percentages) external {
        for (uint i = 0; i < _assets.length; i++) {
            bytes32 hashKey = keccak256(abi.encodePacked(_assets[i], _receipients[i], _percentages[i]));
            splitKeys.push(hashKey);
            assets[hashKey] = _assets[i];
            recipients[hashKey] = _receipients[i];
            percentages[hashKey] = _percentages[i];
        }

    }

    function _deleteSplit(uint index) internal {
        require(index < splitKeys.length);
        splitKeys[index] = splitKeys[splitKeys.length-1];
        delete splitKeys[splitKeys.length-1];
        splitKeys.length--;
    }
}