pragma solidity ^0.5.0;

interface ExchangeProxy {
    function split(address _targetToken, address _recipient) external payable;
}