const ReceiveProxy = artifacts.require("ReceiveProxy");

const UniswapFactory = artifacts.require('UniswapFactory')
const UniswapExchange = artifacts.require('UniswapExchange')

const deploy = async (deployer, network) => {
  // console.log(deployer)
  const _ = await deployer.deploy(UniswapFactory);

  switch(network) {
    case 'development': {      
      const uniswapFactory = await deployer.deploy(UniswapFactory);
      const uniswapExchange = await deployer.deploy(UniswapExchange);
      await uniswapFactory.initializeFactory(uniswapExchange.address);
      await deployer.deploy(ReceiveProxy, uniswapFactory.address)
      break;
    } 
    case 'rinkeby': {
      const config = require('../util/config/rinkeby.json')
      const uniswapFactoryAddress = config.uniswap.factory  
      await deployer.deploy(ReceiveProxy, uniswapFactoryAddress);
    }
  }
    
};

module.exports = deploy;