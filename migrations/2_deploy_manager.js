const ReceiveProxy = artifacts.require("ReceiveProxy");

// const deploy = async (network ,)

const deploy = async (deployer, network) => {
  // console.log(deployer)
  let uniswapFactory;
  if (network === 'rinkeby') {
    const config = require('../util/config/rinkeby.json')
    uniswapFactory = config.uniswap.factory  
  }
  await deployer.deploy(ReceiveProxy, uniswapFactory);
};

module.exports = deploy;