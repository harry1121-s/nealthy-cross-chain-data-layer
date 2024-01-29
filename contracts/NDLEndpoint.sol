// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract NDLEndpoint is Ownable {
    address public ndlRouter;
    mapping(address => bool) public authorizedCallers;

    modifier authorizedAccess() {
        require(authorizedCallers[msg.sender], "NDL: UnAuth Access");
        _;
    }

    constructor(address ndlRouter_) Ownable(msg.sender) {
        ndlRouter = ndlRouter_;
    }

    function addAuthorizedCaller(address caller_, bool access_) external onlyOwner {
        authorizedCallers[caller_] = access_;
    }

    function send(uint16 dstChainId_, uint8 moduleSelector_, bytes calldata payload_)
        external
        payable
        authorizedAccess
    {
        (bool success,) = ndlRouter.call{ value: msg.value }(
            abi.encodeWithSignature("sendToModule(uint16,uint8,bytes)", dstChainId_, moduleSelector_, payload_)
        );
        require(success, "NDL: Router Exec Failed");
    }

    function estimateFees(uint16 dstChainId_, uint8 moduleSelector_, address srcApplication_, bytes memory payload_)
        external
        returns (uint256 fee_)
    {
        (bool success, bytes memory data) = ndlRouter.call(
            abi.encodeWithSignature(
                "estimateFees(uint16,uint8,address,bytes)", dstChainId_, moduleSelector_, srcApplication_, payload_
            )
        );
        require(success);
        (fee_) = abi.decode(data, (uint256));
    }
}
