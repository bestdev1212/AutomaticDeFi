const ReceiveAgent = artifacts.require('ReceiveAgent');
const AgentFactory = artifacts.require('AgentFactory');

const deploy = async (deployer, network, accounts) => {
  
  const _ = await deployer.deploy(ReceiveAgent);    

  // deploy a main implementaion contract
  const implementation = await deployer.deploy(ReceiveAgent);
  await implementation.init(accounts[0]);

  // deploy agent factory
  await deployer.deploy(AgentFactory, implementation.address);
};

module.exports = deploy;
