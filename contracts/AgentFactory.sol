pragma solidity ^0.5.0;

import "./CloneFactory.sol";
// import "./ReceiveAgent.sol";


contract AgentFactory is CloneFactory {

    address public agentAddress;

    event AgentCreated(address newAgentAddress);

    constructor(address _agentAddress) public {
        agentAddress = _agentAddress;
    }

    function createAgent() public {
        address clone = createClone(agentAddress);
        // ReceiveAgent(clone);
        emit AgentCreated(clone);
    }
}