pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./uniswap/IUniswapExchange.sol";
import "./uniswap/IUniswapFactory.sol";


contract ReceiveProxy is Ownable {
    using SafeMath for uint;
    IUniswapFactory factory;

    address[] public investments;
    address payable recipient;
    uint8 constant HUNDRED_PERCENT = 100;
    uint8 constant SWAP_THRESHOLD = 95;
    mapping(address=>uint8) percentages;

    constructor(address _factory) public {
        factory = IUniswapFactory(_factory);
        recipient = msg.sender;
    }

    function() external payable {
        for (uint i = 0; i < investments.length; i++) {
            address token = investments[i];
            uint256 amountETH = msg.value.mul(percentages[token]).div(HUNDRED_PERCENT);
            IUniswapExchange exchange = IUniswapExchange(factory.getExchange(token));
            uint256 minToken = exchange.getEthToTokenInputPrice(amountETH).mul(SWAP_THRESHOLD).div(100);
            uint256 deadline = (now + 1 hours).mul(1000);
            exchange.ethToTokenTransferInput.value(amountETH)(minToken, deadline, owner());
        }
        uint256 remaining = address(this).balance;
        recipient.transfer(remaining);
    }

    function setPortfolio(address[] calldata _tokens, uint8[] calldata _percentages ) external {
        for (uint i = 0; i < _tokens.length; i++) {
            address _token = _tokens[i];
            uint8 _percentage = _percentages[i];
            require(factory.getExchange(_token) != address(0), "Token has no exchange yet.");
            investments.push(_token);
            percentages[_token] = _percentage;
        }
    }

    function clearPortfolio() public {
        for (uint8 i = 0; i < investments.length; i++) {
            percentages[investments[i]] = uint8(0);
        }
        delete investments;
    }
}