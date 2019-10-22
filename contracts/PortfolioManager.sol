pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Uniswap/UniswapExchangeInterface.sol";
import "./Uniswap/UniswapFactoryInterface.sol";


contract PortfolioManager is Ownable {
    using SafeMath for uint;
    UniswapFactoryInterface factory;

    address[] investments;
    address payable recipient;
    uint8 constant HUNDRED_PERCENT = 100;
    uint8 constant SWAP_THRESHOLD = 95;
    uint256 deadline = 1603374468000;
    mapping(address=>uint8) percentages;

    constructor(address _factory) public {
        factory = UniswapFactoryInterface(_factory);
        recipient = msg.sender;
    }

    function() external payable {
        for (uint i = 0; i < investments.length; i++) {
            address token = investments[i];
            uint256 amountETH = msg.value.mul(percentages[token]).div(HUNDRED_PERCENT);
            UniswapExchangeInterface exchange = UniswapExchangeInterface(factory.getExchange(token));
            uint256 minToken = exchange.getEthToTokenInputPrice(amountETH).mul(SWAP_THRESHOLD).div(100);
            exchange.ethToTokenTransferInput.value(amountETH)(minToken, deadline, owner());
        }
        uint256 remaining = address(this).balance;
        recipient.transfer(remaining);
    }

    function setPortfolio(address _token, uint8 _percentage ) public returns (bool success) {
        require(factory.getExchange(_token) != address(0), "Token has no exchange yet.");
        investments.push(_token);
        percentages[_token] = _percentage;
        return true;
    }

    function clearPortfolio() public returns (bool success) {
        for (uint8 i = 0; i < investments.length; i++) {
            percentages[investments[i]] = uint8(0);
        }
        delete investments;
        return true;
    }
}