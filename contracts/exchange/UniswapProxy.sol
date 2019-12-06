pragma solidity ^0.5.0;


import "./ExchangeProxy.sol";
import "../uniswap/IUniswapExchange.sol";
import "../uniswap/IUniswapFactory.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


/**
 * @dev Automatically split funds, exchange them to ERC20s upon receival.
 */
contract UniswapProxy is ExchangeProxy {
    using SafeMath for uint;

    uint8 constant DEFAULT_THRESHOLD = 98;
    mapping(address=>uint8) thresholds;
    IUniswapFactory factory;

    constructor(address _factory) public {
        factory = IUniswapFactory(_factory);
    }

    function split(address _targetToken, address _recipient) external payable {
        IUniswapExchange exchange = IUniswapExchange(factory.getExchange(_targetToken));
        // solium-disable-next-line security/no-tx-origin
        uint8 threshold = thresholds[tx.origin];
        if (threshold == 0) {
            threshold = DEFAULT_THRESHOLD;
        }
        uint256 minToken = exchange.getEthToTokenInputPrice(msg.value).mul(threshold).div(100);
        uint256 deadline = (now + 1 hours).mul(1000);
        exchange.ethToTokenTransferInput.value(msg.value)(minToken, deadline, _recipient);
    }

    function setThreshold(uint8 _threshold) external {
        require(_threshold > 0 && _threshold < 100, "");
        thresholds[msg.sender] = _threshold;
    }

}