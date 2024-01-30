// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import "@wormhole-solidity-sdk/src/interfaces/IWormholeRelayer.sol";
import "@wormhole-solidity-sdk/src/interfaces/IWormholeReceiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { IWormholeModule } from "../interfaces/IWormholeModule.sol";

contract WormholeModule is IWormholeModule, IWormholeReceiver, Ownable {
    
    /*//////////////////////////////////////////////////////////////
    IMMUTABLES & CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 constant GAS_LIMIT = 50_000;
    IWormholeRelayer public immutable wormholeRelayer;

    /*//////////////////////////////////////////////////////////////
    STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address public router;
    mapping(uint16 => bool) public validChainId;
    mapping(address => bool) public validTargetAddress;
    mapping(uint16 => address) public wormholeReceivers;
    mapping(address => bool) public wormholeSenders;

    /*//////////////////////////////////////////////////////////////
    MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyRouter() {
        require(msg.sender == router, "ROUTER: INVALID CALLER");
        _;
    }

    constructor(address wormholeRelayer_) Ownable(msg.sender) {
        require(wormholeRelayer_ != address(0), "MODULE: Invalid Relayer Address");
        wormholeRelayer = IWormholeRelayer(wormholeRelayer_);
        emit WhRelayerUpdated(wormholeRelayer_);
    }

    /*//////////////////////////////////////////////////////////////
    EXTERNALS
    //////////////////////////////////////////////////////////////*/
    /**
     * @inheritdoc IWormholeModule
     */
    function sendCrossChain(
        uint16 dstChainId_,
        bytes calldata payload_
    ) external payable onlyRouter {
        require(validChainId[dstChainId_], "ROUTER: INVALID CHAIN ID");
        uint256 cost = quoteCrossChain(dstChainId_);
        require(msg.value == cost);
        bytes memory data = abi.encode(address(this), payload_);
        wormholeRelayer.sendPayloadToEvm{ value: cost }(
            dstChainId_,
            wormholeReceivers[dstChainId_],
            data,
            0, // no receiver value needed since we're just passing a message
            GAS_LIMIT
        );
        emit WhPayloadSent(dstChainId_, payload_, wormholeReceivers[dstChainId_], msg.value);
    }

    /*//////////////////////////////////////////////////////////////
    PUBLIC
    //////////////////////////////////////////////////////////////*/
    /**
     * @inheritdoc IWormholeModule
     */
    function quoteCrossChain(uint16 dstChainId_) public view returns (uint256 fee_) {
        (fee_,) = wormholeRelayer.quoteEVMDeliveryPrice(dstChainId_, 0, GAS_LIMIT);
    }

    /**
     * @inheritdoc IWormholeReceiver
     */
    function receiveWormholeMessages(
        bytes memory payload_,
        bytes[] memory, // additionalVaas
        bytes32, // address that called 'sendPayloadToEvm' (HelloWormhole contract address)
        uint16 srcChainId_,
        bytes32 // unique identifier of delivery
    ) public payable override {
        require(msg.sender == address(wormholeRelayer), "MODULE: Only relayer allowed");
        // Parse the payload and do the corresponding actions!
        (address senderAddress, bytes memory execData) = abi.decode(payload_, (address, bytes));
        require(wormholeSenders[senderAddress], "MODULE: Invalid Sender");
        (bytes32 target, bytes memory data) = abi.decode(execData, (bytes32, bytes));
        address targetAddress = address(uint160(uint256(target)));
        require(validTargetAddress[targetAddress], "MODULE: Invalid Target");
        (bool success,) = targetAddress.call(data);
        require(success, "MODULE: Target Exec Failed");
    }

    /*//////////////////////////////////////////////////////////////
    OWNER ONLY
    //////////////////////////////////////////////////////////////*/
    /**
     * @inheritdoc IWormholeModule
     */
    function setRouter(address router_) external onlyOwner {
        require(router_ != address(0), "MODULE: Invalid Router Address");
        address oldRouter = router;
        router = router_;
        emit RouterUpdated(oldRouter, router_);
    }

    /**
     * @inheritdoc IWormholeModule
     */
    function setDestinationChainId(uint16 chainId_, bool valid_) external onlyOwner {
        validChainId[chainId_] = valid_;
        emit DestinationChainIdUpdated(chainId_, valid_);
    }

    /**
     * @inheritdoc IWormholeModule
     */
    function setTargetAddress(address target_, bool valid_) external onlyOwner {
        require(target_ != address(0), "MODULE: Invalid Target Address");
        validTargetAddress[target_] = valid_;
        emit TargetAddressUpdated(target_, valid_);
    }

    /**
     * @inheritdoc IWormholeModule
     */
    function addWormholeReceiver(uint16 dstChainId_, address receiver_) external onlyOwner {
        require(receiver_ != address(0), "MODULE: Invalid Receiver Address");
        wormholeReceivers[dstChainId_] = receiver_;
        emit WhReceiverUpdated(dstChainId_, receiver_);
    }

    /**
     * @inheritdoc IWormholeModule
     */
    function setWormholeSender(address sender_, bool val_) external onlyOwner {
        require(sender_ != address(0), "MODULE: Invalid Sender Address");
        wormholeSenders[sender_] = val_;
    }

    /**
     * @inheritdoc IWormholeModule
     */
    function withdraw(uint256 amount_) external onlyOwner {
        require(amount_ < address(this).balance + 1, "MODULE: InSuff Balance");
        (bool success,) = payable(msg.sender).call{ value: amount_ }("");
        require(success, "MODULE: Withdrawal Failed");
        emit Withdrawn(msg.sender, amount_);
    }
}
