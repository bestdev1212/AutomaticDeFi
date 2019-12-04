pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./uniswap/IUniswapExchange.sol";
import "./uniswap/IUniswapFactory.sol";


/**
 * @dev Automatically split funds, exchange them to ERC20s upon receival.
 */
contract ReceiveProxy is Ownable {
    using SafeMath for uint;

    bytes32[] public splitKeys;
    uint8 public sumPercentage;
    uint8 constant SWAP_THRESHOLD = 95;

    mapping(bytes32=>address) public assets;
    mapping(bytes32=>address payable) public recipients;
    mapping(bytes32=>uint8) public percentages;

    IUniswapFactory factory;

    /**
     * Events
     */
    event NewSplit (address asset, address payable recipient, uint8 percentage);
    event NewSplits (address[] assets, address payable[] recipients, uint8[] percentages);

    /**
     * @dev Initializes the contract setting the Uniswap factory.
     */
    constructor(address _factory) public {
        sumPercentage = 0;
        factory = IUniswapFactory(_factory);
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
            IUniswapExchange exchange = IUniswapExchange(factory.getExchange(token));
            uint256 minToken = exchange.getEthToTokenInputPrice(amountETH).mul(SWAP_THRESHOLD).div(100);
            uint256 deadline = (now + 1 hours).mul(1000);
            exchange.ethToTokenTransferInput.value(amountETH)(minToken, deadline, recipeint);
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
    function addSplit(address _asset, address payable _recipient, uint8 _percentage) external onlyOwner {
        require(sumPercentage + _percentage <= 100, "Total percentage must < 100");
        if (_percentage <= 0)
            return;
        sumPercentage += _percentage;

        bytes32 hashKey = keccak256(abi.encodePacked(_asset, _recipient, _percentage));
        splitKeys.push(hashKey);
        assets[hashKey] = _asset;
        recipients[hashKey] = _recipient;
        percentages[hashKey] = _percentage;

        emit NewSplit(_asset, _recipient, _percentage);
    }

    /**
     * @dev Add an array of splitting targets
     */
    function addSplits(
        address[] calldata _assets,
        address payable[] calldata _recipients,
        uint8[] calldata _percentages)
    external
    onlyOwner
    {
        for (uint i = 0; i < _assets.length; i++) {
            require(_percentages[i] > 0, "Percentage cannot be negative");
            require(sumPercentage + _percentages[i] <= 100, "Total percentage must < 100");
            sumPercentage += _percentages[i];

            bytes32 hashKey = keccak256(abi.encodePacked(_assets[i], _recipients[i], _percentages[i]));
            splitKeys.push(hashKey);
            assets[hashKey] = _assets[i];
            recipients[hashKey] = _recipients[i];
            percentages[hashKey] = _percentages[i];
        }

        emit NewSplits(_assets, _recipients, _percentages);
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