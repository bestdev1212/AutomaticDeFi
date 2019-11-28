pragma solidity >=0.5.0 <0.6.0;


interface IUniswapFactory {
    function getExchange(address token) external view returns (address exchange);
}