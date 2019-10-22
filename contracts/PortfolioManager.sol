pragma solidity >=0.4.21 <0.6.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Uniswap/UniswapExchangeInterface.sol";


contract PortfolioManager is Ownable {
    UniswapExchangeInterface uniswap;

    address[] investments;
    mapping(address=>uint8) percentages;

    event PortfolioUpdate(
        address indexed account,
        address[] tokens,
        uint8[] percentages
    );

    constructor(address _uniswap) public {
        uniswap = UniswapExchangeInterface(_uniswap);
    }

    function setPortfolio(address[] _tokens, uint8[] _percentages ) public returns (bool success) {
        require(_tokens.length == _percentages.length, "Use arrays of same length for updateing");
        clearPortfolio();
        for (uint8 i = 0; i < _tokens.length; i ++) {
            investments[i] = _tokens[i];
            percentages[_tokens[i]] = _percentages[i];
        }
        emit PortfolioUpdate(msg.sender, _tokens, _percentages);
    }

    function clearPortfolio() public returns (bool success) {
        for (uint8 i = 0; i < investments.length; i++) {
            percentages[investments[i]] = uint8(0);
        }
        delete investments;
        return true;
    }

}