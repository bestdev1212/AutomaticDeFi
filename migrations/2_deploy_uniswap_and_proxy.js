const ReceiveProxy = artifacts.require("ReceiveProxy");

const UniswapFactory = artifacts.require('UniswapFactory')
const UniswapExchange = artifacts.require('UniswapExchange')
const TestERC20 = artifacts.require('TestERC20')

const deploy = async (deployer, network, accounts) => {

  const _ = await deployer.deploy(TestERC20, [accounts[0]], 100000, 10);    
  
  const testToken = await deployer.deploy(TestERC20, [accounts[0]], 100000, 10);    

  switch(network) {
    case 'development': {       
      const uniswapFactory = await deployer.deploy(UniswapFactory);
      const uniswapExchangeTemplate = await deployer.deploy(UniswapExchange);
      await uniswapFactory.initializeFactory(uniswapExchangeTemplate.address);
      await uniswapFactory.createExchange(testToken.address)
      await deployer.deploy(ReceiveProxy, uniswapFactory.address);
      break;
    } 
    case 'rinkeby': {
      const config = require('../util/config/rinkeby.json')
      const uniswapFactoryAddress = config.uniswap.factory  
      await deployer.deploy(ReceiveProxy, uniswapFactoryAddress);
      break;
    }
  }
    
};

module.exports = deploy;