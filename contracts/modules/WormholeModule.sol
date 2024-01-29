// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import "@wormhole-solidity-sdk/src/interfaces/IWormholeRelayer.sol";
import "@wormhole-solidity-sdk/src/interfaces/IWormholeReceiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";


contract WormholeModule is IWormholeReceiver, Ownable {
    uint256 constant GAS_LIMIT = 50_000;

    IWormholeRelayer public immutable wormholeRelayer;

    address public router;
    mapping(uint16 => bool) public validChainId;
    mapping(address => bool) public validTargetAddress;
    mapping(uint16 => address) public wormholeReceivers;
    mapping(address => bool) public wormholeSenders;

    modifier onlyRouter() {
        require(msg.sender == router, "ROUTER: INVALID CALLER");
        _;
    }

    constructor(address wormholeRelayer_) Ownable(msg.sender) {
        wormholeRelayer = IWormholeRelayer(wormholeRelayer_);
    }

    function setRouter(address router_) external onlyOwner {
        router = router_;
    }

    function setDestinationChainId(uint16 chainId_, bool valid_) external onlyOwner {
        validChainId[chainId_] = valid_;
    }

    function setTargetAddress(address target_, bool valid_) external onlyOwner {
        validTargetAddress[target_] = valid_;
    }

    function addWormholeReceiver(uint16 dstChainId_, address receiver_) external onlyOwner {
        wormholeReceivers[dstChainId_] = receiver_;
    }

    function setWormholeSender(address sender_, bool val_) external onlyOwner {
        wormholeSenders[sender_] = val_;
    }

    function withdraw(uint256 amount_) external onlyOwner {
        require(amount_ < address(this).balance + 1, "MODULE: InSuff Balance");
        (bool success,) = payable(msg.sender).call{ value: amount_ }("");
        require(success, "MODULE: Withdrawal Failed");
    }

    function sendCrossChain(
        uint16 dstChainId_,
        // address targetAddress_,
        // string memory greeting
        bytes calldata payload_
    ) external payable onlyRouter {
        require(validChainId[dstChainId_], "ROUTER: INVALID CHAIN ID");
        uint256 cost = quoteCrossChain(dstChainId_);
        require(msg.value == cost);
        bytes memory data = abi.encode(address(this), payload_);
        wormholeRelayer.sendPayloadToEvm{ value: cost }(
            dstChainId_,
            wormholeReceivers[dstChainId_],
            // abi.encode(greeting, msg.sender), // payload
            data,
            0, // no receiver value needed since we're just passing a message
            GAS_LIMIT
        );
    }

    function receiveWormholeMessages(
        bytes memory payload_,
        bytes[] memory, // additionalVaas
        bytes32, // address that called 'sendPayloadToEvm' (HelloWormhole contract address)
        uint16 srcChainId_,
        bytes32 // unique identifier of delivery
    ) public payable override {
        require(msg.sender == address(wormholeRelayer), "MODULE: Only relayer allowed");
        console.log("HERE");
        // Parse the payload and do the corresponding actions!
        (address senderAddress, bytes memory execData) = abi.decode(payload_, (address, bytes));
        console.log("Status: ", wormholeSenders[senderAddress]);
        require(wormholeSenders[senderAddress], "MODULE: Invalid Sender");
        console.log("Status: ", wormholeSenders[senderAddress]);
        (bytes32 target, bytes memory data) = abi.decode(execData, (bytes32, bytes));
        address targetAddress = address(uint160(uint256(target)));
        require(validTargetAddress[targetAddress], "MODULE: Invalid Target");
        (bool success, ) = targetAddress.call(data);
        require(success, "MODULE: Target Exec Failed");
    }

    function quoteCrossChain(uint16 dstChainId_) public view returns (uint256 cost_) {
        (cost_,) = wormholeRelayer.quoteEVMDeliveryPrice(dstChainId_, 0, GAS_LIMIT);
    }
}
