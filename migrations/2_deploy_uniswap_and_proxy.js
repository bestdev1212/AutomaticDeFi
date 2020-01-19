const ReceiveAgent = artifacts.require("ReceiveAgent")
const AgentFactory = artifacts.require('AgentFactory')
const UniswapFactory = artifacts.require('UniswapFactory')
const UniswapExchange = artifacts.require('UniswapExchange')
const UniswapProxy = artifacts.require('UniswapProxy')

const TestERC20 = artifacts.require('TestERC20')

const deploy = async (deployer, network, accounts) => {

  const _ = await deployer.deploy(TestERC20, [accounts[0]], 100000, 18);    
  
  const testToken = await deployer.deploy(TestERC20, [accounts[0]], 100000, 18);    

  switch(network) {
    case 'development': {       
      const uniswapFactory = await deployer.deploy(UniswapFactory);
      const uniswapExchangeTemplate = await deployer.deploy(UniswapExchange);
      await uniswapFactory.initializeFactory(uniswapExchangeTemplate.address);
      await uniswapFactory.createExchange(testToken.address)

      // uniswap proxy that handle spliting for all wallets
      await deployer.deploy(UniswapProxy, uniswapFactory.address);

      // deploy a main agent code 
      const agent = await deployer.deploy(ReceiveAgent);
      await agent.init(accounts[0])
      
      await deployer.deploy(AgentFactory, agent.address);
      // console.log(`factory deployed with agent address: ${agent.address}`)
      
      break;
    } 
    case 'rinkeby': {
      const config = require('../util/config/rinkeby.json')
      const uniswapFactoryAddress = config.uniswap.factory
      
      await deployer.deploy(UniswapProxy, uniswapFactoryAddress);
      await deployer.deploy(ReceiveAgent);
      break;
    }
  }
    
};

module.exports = deploy;