pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Uniswap/UniswapExchangeInterface.sol";


contract PortfolioManager is Ownable {
    using SafeMath for uint;
    UniswapFactoryInterface factory;

    address[] investments;
    address payable recipient;
    uint8 constant HUNDRED_PERCENT = 100;
    uint8 constant SWAP_THRESHOLD = 95;
    mapping(address=>uint8) percentages;

    event PortfolioUpdate(
        address indexed account,
        address[] tokens,
        uint8[] percentages
    );

    constructor(address _uniswap) public {
        factory = UniswapFactoryInterface(_uniswap);
        recipient = msg.sender;
    }

    function() external payable {
        for (uint i = 0; i < investments.length; i++) {
            address token = investments[i];
            uint256 amountETH = msg.value.mul(percentages[token]).div(HUNDRED_PERCENT);
            UniswapExchangeInterface exchange = UniswapExchangeInterface(factory.getExchange(token));
            uint256 minToken = exchange.getEthToTokenInputPrice(amountETH).mul(SWAP_THRESHOLD).div(100);
            exchange.ethToTokenTransferInput.value(amountETH)(minToken, 0, owner());
        }
        uint256 remaining_eth = address(this).balance;
        recipient.transfer(remaining_eth);
    }

    function setPortfolio(address[] memory _tokens, uint8[] memory _percentages ) public returns (bool success) {
        require(_tokens.length == _percentages.length, "Use arrays of same length for updateing");
        clearPortfolio();
        uint256 percentageSum = 0;
        for (uint8 i = 0; i < _tokens.length; i ++) {
            percentageSum = percentageSum.add(_percentages[i]);
            require(percentageSum <= HUNDRED_PERCENT, "Invalid percentages");
            investments[i] = _tokens[i];
            percentages[_tokens[i]] = _percentages[i];
        }
        emit PortfolioUpdate(msg.sender, _tokens, _percentages);
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