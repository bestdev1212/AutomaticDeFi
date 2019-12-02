pragma solidity >=0.5.0 <0.6.0;


interface IUniswapFactory {
    function initializeFactory(address template) external;
    function createExchange(address token) external returns (address exchange);
    function getExchange(address token) external view returns (address exchange);
}