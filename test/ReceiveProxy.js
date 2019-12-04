const Web3 =require('web3')
const web3 = new Web3('http://localhost:8545')

// const ganache = require('ganache-cli')
const ReceiveProxy = artifacts.require("ReceiveProxy");
const UniswapFactory = artifacts.require('UniswapFactory')
const UniswapExchange = artifacts.require('UniswapExchange')
const IUniswapFactory = artifacts.require('IUniswapFactory')
const IUniswapExchange = artifacts.require('IUniswapExchange')
const TestERC20 = artifacts.require('TestERC20')

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

contract("ReceiveProxy", accounts => {

  let factory, testToken, testTokenExchange;

  before("Setup Uniswap factory and exchange" ,async()=>{
    
    await UniswapFactory.deployed();
    await TestERC20.deployed()
    
    const UniswapFactoryInstance = await IUniswapFactory.at(UniswapFactory.address)
    testToken = await TestERC20.at(TestERC20.address)
    const tokenExchangeAddr = await UniswapFactoryInstance.getExchange(TestERC20.address)
    testTokenExchange = await IUniswapExchange.at(tokenExchangeAddr)
    await testToken.approve(tokenExchangeAddr, web3.utils.toWei('10000', 'ether'))

    const deadline = Math.round((new Date()).getTime() + 3600000)
    const tokenAmount = web3.utils.toWei('1000', 'ether') // invest 1000 unit of token
    await testTokenExchange.addLiquidity(0, tokenAmount, deadline, { value: web3.utils.toWei('0.1', 'ether') })
  })

  it('should add percentage', async()=>{
    const proxy = await ReceiveProxy.deployed();
    await proxy.addSplit(testToken.address, accounts[0], 30);
    const sumPercentage = await proxy.sumPercentage();
    assert.equal(
      sumPercentage,
      30,
      "Must be previously set percentage"
    )
  })
  
  it('should delete target split', async()=>{
    const proxy = await ReceiveProxy.deployed();
    const idx = 0
    const key = await proxy.splitKeys(idx);
    await proxy.deleteSplit(idx);

    const sumPercentage = await proxy.sumPercentage();
    assert.equal(
      sumPercentage,
      0,
      "sumPercentage should be 0"
    )

    const asset = await proxy.assets(key);
    assert.equal(
      asset,
      0,
      "asset map should be empty at position [key]"
    )

    const recipient = await proxy.recipients(key);
    assert.equal(
      recipient,
      0,
      "recipient map should be empty at position [key]"
    )

    const percentage = await proxy.percentages(key);
    assert.equal(
      percentage,
      0,
      "percentage map should be empty at position [key]"
    )
  })

  it('should split fund toward different accounts', async()=>{

    const amountToSend = '0.1'
    const account1EthRatio = 30
    const account2TokenRatio = 60

    const proxy = await ReceiveProxy.deployed()
    await proxy.addSplit(ZERO_ADDRESS, accounts[1], account1EthRatio)
    await proxy.addSplit(testToken.address, accounts[2], account2TokenRatio)

    const account1EthBalance = await web3.eth.getBalance(accounts[1])
    
    // const account2TokenBalance = await testToken.balanceOf(accounts[2]);
    
    
    await proxy.send(web3.utils.toWei(amountToSend, 'ether'))
    // const account2TokenBalanceAfter = await testToken.balanceOf(accounts[2]);
    
    const account1EthBalanceAfter = await web3.eth.getBalance(accounts[1])
    // const account2EthBalance

    const account1Received = account1EthBalanceAfter - account1EthBalance;
    assert.equal(
      account1Received,
      web3.utils.toWei(amountToSend, 'ether') * account1EthRatio / 100
    )

  })

})