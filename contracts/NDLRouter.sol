// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { INDLRouter } from "./interfaces/INDLRouter.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract NDLRouter is INDLRouter, Ownable {
    using Address for address;

    /*//////////////////////////////////////////////////////////////
    STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint8 private locked = 1;
    mapping(uint8 => address) public flightModules;
    mapping(address => bool) public authorizedCallers;

    /*//////////////////////////////////////////////////////////////
    MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier authorizedAccess() {
        require(authorizedCallers[msg.sender], "NDL: UnAuth Access");
        _;
    }

    modifier nonReentrant() {
        require(locked == 1, "NDL: Locked");
        locked = 2;
        _;
        locked = 1;
    }

    constructor() Ownable(msg.sender) { }

    /*//////////////////////////////////////////////////////////////
    EXTERNALS
    //////////////////////////////////////////////////////////////*/
    /**
     * @inheritdoc INDLRouter
     */
    function send(uint16 dstChainId_, uint8 moduleSelector_, bytes calldata payload_)
        external
        payable
        authorizedAccess nonReentrant
    {
        require(flightModules[moduleSelector_] != address(0), "ROUTER: Invalid Module");
        bytes memory data = abi.encodeWithSignature("sendCrossChain(uint16,bytes)", dstChainId_, payload_);
        (bool success,) = flightModules[moduleSelector_].call{ value: msg.value }(data);
        require(success, "ROUTER: Module Exec Failed");
        emit PayloadSent(dstChainId_, moduleSelector_, payload_, msg.value);
    }

    /**
     * @inheritdoc INDLRouter
     */
    function estimateFees(uint16 dstChainId_, uint8 moduleSelector_, address srcApplication_, bytes memory payload_)
        external
        view
        returns (uint256 fee_)
    {
        (bytes memory data) = flightModules[moduleSelector_].functionStaticCall(
            abi.encodeWithSignature("estimateFees(uint16,address,bytes)", dstChainId_, srcApplication_, payload_)
        );
        (fee_) = abi.decode(data, (uint256));
    }

    /*//////////////////////////////////////////////////////////////
    OWNER ONLY
    //////////////////////////////////////////////////////////////*/
    /**
     * @inheritdoc INDLRouter
     */
    function updateAuthorizedCaller(address caller_, bool access_) external onlyOwner {
        authorizedCallers[caller_] = access_;
        emit AuthorizedCallerUpdated(caller_, access_);
    }

    /**
     * @inheritdoc INDLRouter
     */
    function addModule(address module_, uint8 moduleSelector_) external onlyOwner {
        require(flightModules[moduleSelector_] == address(0), "ROUTER: Selector already in use");
        flightModules[moduleSelector_] = module_;
        emit ModuleAdded(module_, moduleSelector_);
    }

    /**
     * @inheritdoc INDLRouter
     */
    function removeModule(uint8 moduleSelector_) external onlyOwner {
        require(flightModules[moduleSelector_] != address(0), "ROUTER: Module does not exist");
        address removedModule = flightModules[moduleSelector_];
        delete flightModules[moduleSelector_];
        emit ModuleRemoved(removedModule, moduleSelector_);
    }
}
