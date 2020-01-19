pragma solidity ^0.5.0;

import "./CloneFactory.sol";
import "./ReceiveAgent.sol";


contract AgentFactory is CloneFactory {

    address public agentImplementation;

    event AgentCreated(address newAgentAddress);

    constructor(address _implementation) public {
        agentImplementation = _implementation;
    }

    function createAgent() public returns (address payable clone) {
        clone = createClone(agentImplementation);
        ReceiveAgent(clone).init(msg.sender);
        emit AgentCreated(clone);
    }
}