// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract NDLRouter is Ownable {
    address public NDLEndpoint;
    mapping(uint8 => bool) public validModule;
    mapping(uint8 => address) public flightModules;

    modifier onlyEndpoint() {
        require(msg.sender == NDLEndpoint, "ROUTER: Invalid Endpoint");
        _;
    }

    constructor() Ownable(msg.sender) { }

    function updateEndpoint(address NDLEndpoint_) external onlyOwner {
        NDLEndpoint = NDLEndpoint_;
    }

    function addModule(address module_, uint8 moduleSelector_) external onlyOwner {
        flightModules[moduleSelector_] = module_;
        validModule[moduleSelector_] = true;
    }

    function removeModule(uint8 moduleSelector_) external onlyOwner {
        validModule[moduleSelector_] = false;
        delete flightModules[moduleSelector_];
    }

    function sendToModule(uint16 dstChainId_, uint8 moduleSelector_, bytes memory payload_)
        external
        payable
        onlyEndpoint
    {
        require(validModule[moduleSelector_], "ROUTER: Invalid Module");
        bytes memory data = abi.encodeWithSignature("sendCrossChain(uint16,bytes)", dstChainId_, payload_);
        (bool success,) = flightModules[moduleSelector_].call{ value: msg.value }(data);
        require(success, "ROUTER: Module Exec Failed");
    }
}
