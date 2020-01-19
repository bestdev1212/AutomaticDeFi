pragma solidity ^0.5.0;

// import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./exchange/ExchangeProxy.sol";


/**
 * @dev Automatically split funds, exchange them to ERC20s upon receival.
 */
contract ReceiveAgent {
    using SafeMath for uint;

    bytes32[] public ruleKeys;
    uint8 public sumPercentage = 0;
    address public owner;

    /**
     * Mapping for rules
     */
    mapping(bytes32=>address) public assets;
    mapping(bytes32=>address payable) public recipients;
    mapping(bytes32=>address) public exchanges;
    mapping(bytes32=>uint8) public percentages;

    /**
     * Events
     */
    event NewRule (address asset, address payable recipient, address exchangeProxy, uint8 percentage);
    event NewRules (address[] assets, address payable[] recipients, address[] exchangeProxies, uint8[] percentages);

    /**
     * @dev Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "RA: msg.sender must be the owner");
        _;
    }

    /**
     * @dev Split the fund upon receival.
     */
    function() external payable {
        for (uint i = 0; i < ruleKeys.length; i++) {
            bytes32 ruleKey = ruleKeys[i];
            address token = assets[ruleKey];
            address payable recipeint = recipients[ruleKey];
            uint256 amountETH = msg.value.mul(percentages[ruleKey]).div(100);
            if (token == address(0)) {
                recipeint.transfer(amountETH); // transaction reverted
                continue;
            }
            ExchangeProxy exchange = ExchangeProxy(exchanges[ruleKey]);
            exchange.split.value(amountETH)(token, recipeint);
        }
    }

    function init(address _owner) external {
        require(owner == address(0), "RA: Wallet already initialised");
        owner = _owner;
    }

    /**
     * @dev Withdraw eth balance from contract
     */
    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    /**
     * @dev Add a splitting rule
     */
    function addRule(
        address _asset,
        address payable _recipient,
        address _exchangeProxy,
        uint8 _percentage
    )
    external
    onlyOwner
    {
        require(sumPercentage + _percentage <= 100, "RA: Total percentage must < 100");
        if (_percentage <= 0)
            return;
        sumPercentage += _percentage;

        bytes32 hashKey = keccak256(abi.encodePacked(_asset, _recipient, _percentage));
        ruleKeys.push(hashKey);
        assets[hashKey] = _asset;
        recipients[hashKey] = _recipient;
        percentages[hashKey] = _percentage;
        exchanges[hashKey] = _exchangeProxy;

        emit NewRule(_asset, _recipient, _exchangeProxy, _percentage);
    }

    /**
     * @dev Add an array of splitting rules
     */
    function addRules(
        address[] calldata _assets,
        address payable[] calldata _recipients,
        address[] calldata _exchangeProxies,
        uint8[] calldata _percentages
    )
    external
    onlyOwner
    {
        for (uint i = 0; i < _assets.length; i++) {
            require(_percentages[i] > 0, "RA: Percentage cannot be negative");
            require(sumPercentage + _percentages[i] <= 100, "RA: Total percentage must < 100");
            sumPercentage += _percentages[i];

            bytes32 hashKey = keccak256(
                abi.encodePacked(
                    _assets[i],
                    _recipients[i],
                    _percentages[i],
                    _exchangeProxies[i]
            ));
            ruleKeys.push(hashKey);
            assets[hashKey] = _assets[i];
            recipients[hashKey] = _recipients[i];
            percentages[hashKey] = _percentages[i];
            exchanges[hashKey] = _exchangeProxies[i];
        }

        emit NewRules(_assets, _recipients, _exchangeProxies, _percentages);
    }

    /**
     * @dev Delete a spliting target from the array
     */
    function deleteRule(uint index) external onlyOwner {
        require(index < ruleKeys.length);
        bytes32 key = ruleKeys[index];
        sumPercentage -= percentages[key];
        delete percentages[key];
        delete recipients[key];
        delete assets[key];
        ruleKeys[index] = ruleKeys[ruleKeys.length-1];
        delete ruleKeys[ruleKeys.length-1];
        ruleKeys.length--;
    }
}