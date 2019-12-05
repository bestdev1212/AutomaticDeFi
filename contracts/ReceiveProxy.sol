pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./exchange/ExchangeProxy.sol";
// import "./uniswap/IUniswapExchange.sol";
// import "./uniswap/IUniswapFactory.sol";


/**
 * @dev Automatically split funds, exchange them to ERC20s upon receival.
 */
contract ReceiveProxy is Ownable {
    using SafeMath for uint;

    bytes32[] public splitKeys;
    uint8 public sumPercentage;

    mapping(bytes32=>address) public assets;
    mapping(bytes32=>address payable) public recipients;
    mapping(bytes32=>uint8) public percentages;
    mapping(bytes32=>address) public exchanges;

    /**
     * Events
     */
    event NewSplit (address asset, address payable recipient, uint8 percentage, address exchangeProxy);
    event NewSplits (address[] assets, address payable[] recipients, uint8[] percentages, address[] exchangeProxies);

    /**
     * @dev Initializes the contract.
     */
    constructor() public {
        sumPercentage = 0;
    }

    /**
     * @dev Split the fund upon receival.
     */
    function() external payable {
        for (uint i = 0; i < splitKeys.length; i++) {
            bytes32 splitKey = splitKeys[i];
            address token = assets[splitKey];
            address payable recipeint = recipients[splitKey];
            uint256 amountETH = msg.value.mul(percentages[splitKey]).div(100);
            if (token == address(0)) {
                recipeint.transfer(amountETH); // transaction reverted
                continue;
            }
            ExchangeProxy exchange = ExchangeProxy(exchanges[splitKey]);
            exchange.split.value(amountETH)(token, recipeint);
        }
    }

    /**
     * @dev Withdraw eth balance from contract
     */
    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    /**
     * @dev Add a splitting target
     */
    function addSplit(
        address _asset,
        address payable _recipient,
        address _exchangeProxy,
        uint8 _percentage
    )
    external
    onlyOwner
    {
        require(sumPercentage + _percentage <= 100, "Total percentage must < 100");
        if (_percentage <= 0)
            return;
        sumPercentage += _percentage;

        bytes32 hashKey = keccak256(abi.encodePacked(_asset, _recipient, _percentage));
        splitKeys.push(hashKey);
        assets[hashKey] = _asset;
        recipients[hashKey] = _recipient;
        percentages[hashKey] = _percentage;
        exchanges[hashKey] = _exchangeProxy;

        emit NewSplit(_asset, _recipient, _percentage, _exchangeProxy);
    }

    /**
     * @dev Add an array of splitting targets
     */
    function addSplits(
        address[] calldata _assets,
        address payable[] calldata _recipients,
        address[] calldata _exchangeProxies,
        uint8[] calldata _percentages
    )
    external
    onlyOwner
    {
        for (uint i = 0; i < _assets.length; i++) {
            require(_percentages[i] > 0, "Percentage cannot be negative");
            require(sumPercentage + _percentages[i] <= 100, "Total percentage must < 100");
            sumPercentage += _percentages[i];

            bytes32 hashKey = keccak256(
                abi.encodePacked(
                    _assets[i],
                    _recipients[i],
                    _percentages[i],
                    _exchangeProxies[i]
            ));
            splitKeys.push(hashKey);
            assets[hashKey] = _assets[i];
            recipients[hashKey] = _recipients[i];
            percentages[hashKey] = _percentages[i];
            exchanges[hashKey] = _exchangeProxies[i];
        }

        emit NewSplits(_assets, _recipients, _percentages, _exchangeProxies);
    }

    /**
     * @dev Delete a spliting target from the array
     */
    function deleteSplit(uint index) external onlyOwner {
        require(index < splitKeys.length);
        bytes32 key = splitKeys[index];
        sumPercentage -= percentages[key];
        delete percentages[key];
        delete recipients[key];
        delete assets[key];
        splitKeys[index] = splitKeys[splitKeys.length-1];
        delete splitKeys[splitKeys.length-1];
        splitKeys.length--;
    }
}