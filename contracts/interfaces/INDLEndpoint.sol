// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

interface INDLEndpoint {
    function generatePayload(address targetAddress_, uint256 val_) external returns (bytes memory);
    function send(uint16 dstChainId_, uint8 moduleSelector_, bytes memory payload_) external payable;
}
