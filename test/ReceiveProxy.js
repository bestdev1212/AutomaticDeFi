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
    await testTokenExchange.addLiquidity(0, 10000, deadline, { value: web3.utils.toWei('0.1', 'ether') })
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

})