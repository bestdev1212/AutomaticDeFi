const Web3 =require('web3')

const web3 = new Web3()

const ReceiveProxy = artifacts.require("ReceiveProxy");
const UniswapFactory = artifacts.require('UniswapFactory')
const UniswapExchange = artifacts.require('UniswapExchange')
const IUniswapFactory = artifacts.require('IUniswapFactory')
const IUniswapExchange = artifacts.require('IUniswapExchange')
const TestERC20 = artifacts.require('TestERC20')

contract("ReceiveProxy", accounts => {

  let factory, testToken, testTokenExchange;

  before("Setup Uniswap factory and exchange" ,async()=>{
    
    await UniswapFactory.deployed();
    await TestERC20.deployed()
    
    const UniswapFactoryInstance = await IUniswapFactory.at(UniswapFactory.address)
    testToken = await TestERC20.at(TestERC20.address)
    const tokenExchangeAddr = await UniswapFactoryInstance.getExchange(TestERC20.address)
    testTokenExchange = await IUniswapExchange.at(tokenExchangeAddr)
    await testToken.approve(tokenExchangeAddr, web3.utils.toWei('15', 'ether'))

    const deadline = Math.round((new Date()).getTime() + 3600000)
    await testTokenExchange.addLiquidity(0, 10000, deadline, { value: web3.utils.toWei('10', 'ether') })
  })

  it('should run', async()=>{
    const proxy = await ReceiveProxy.deployed();
    
  })
  

})