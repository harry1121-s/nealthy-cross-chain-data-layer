// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract NDLRouter is Ownable {
    mapping(uint8 => address) public flightModules;
    mapping(address => bool) public authorizedCallers;

    modifier authorizedAccess() {
        require(authorizedCallers[msg.sender], "NDL: UnAuth Access");
        _;
    }

    constructor() Ownable(msg.sender) { }

    function addAuthorizedCaller(address caller_, bool access_) external onlyOwner {
        authorizedCallers[caller_] = access_;
    }

    function addModule(address module_, uint8 moduleSelector_) external onlyOwner {
        flightModules[moduleSelector_] = module_;
    }

    function removeModule(uint8 moduleSelector_) external onlyOwner {
        delete flightModules[moduleSelector_];
    }

    function send(uint16 dstChainId_, uint8 moduleSelector_, bytes calldata payload_)
        external
        payable
        authorizedAccess
    {
        require(flightModules[moduleSelector_] != address(0), "ROUTER: Invalid Module");
        bytes memory data = abi.encodeWithSignature("sendCrossChain(uint16,bytes)", dstChainId_, payload_);
        (bool success,) = flightModules[moduleSelector_].call{ value: msg.value }(data);
        require(success, "ROUTER: Module Exec Failed");
    }

    function estimateFees(uint16 dstChainId_, uint8 moduleSelector_, address srcApplication_, bytes memory payload_)
        external
        returns (uint256 fee_)
    {
        (bool success, bytes memory data) = flightModules[moduleSelector_].call(
            abi.encodeWithSignature("estimateFees(uint16,address,bytes)", dstChainId_, srcApplication_, payload_)
        );
        require(success);
        (fee_) = abi.decode(data, (uint256));
    }
}
