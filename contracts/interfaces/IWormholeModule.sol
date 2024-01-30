pragma solidity 0.8.22;

interface IWormholeModule {
    
    /**
     * @notice emitted when Wormhole Relayer is updated
     * @param whRelayer_ : address of the Wormhole Relayer 
     *
     */
    event WhRelayerUpdated(address indexed whRelayer_);

    /**
     * @notice emitted when NDL Router Address is updated
     * @param oldRouter_ : address of the existing NDL router
     * @param newRouter_ : address of the new NDL router
     *
     */
    event RouterUpdated(address indexed oldRouter_, address indexed newRouter_);

    /**
     * @notice emitted when status of a destination chain ID is updated
     * @param chainId_ : unique identifier for the destination chain
     * @param valid_ : status of the chainId
     *
     */
    event DestinationChainIdUpdated(uint16 chainId_, bool valid_);

    /**
     * @notice emitted when status of a destination chain target contract is updated
     * @param target_ : address of the destination chain target contract
     * @param valid_ : status of the chainId
     *
     */
    event TargetAddressUpdated(address indexed target_, bool valid_);

    /**
     * @notice emitted when a receiver contract information is updated on the source chain 
     * @param dstChainId_ : the destination chain identifier
     * @param receiver_ : address of the contract on destination chain implementing the IWormholeReceiver
     *
     */
    event WhReceiverUpdated(uint16 dstChainId_, address indexed receiver_);

    /**
     * @notice emitted when a sender contract information is updated on the destination chain
     * @param sender_ : address of the source chain sender module
     * @param val_ : boolean flag to allow/revoke access
     *
     */
    event WhSenderUpdated(address indexed sender_, bool val_);

    /**
     * @notice emitted when a generic cross-chain message is sent
     * @param dstChainId_ : the destination chain identifier
     * @param payload_ : a custom bytes payload to send to the destination contract
     * @param wormholeReceiver_ : address of the contract receiving the payload on the destination chain
     * @param fee_ : the fee required for cross-chain execution paid in native passed as msg.value
     *
     */
    event WhPayloadSent(uint16 dstChainId_, bytes payload_, address indexed wormholeReceiver_, uint256 fee_);

    /**
     * @notice emitted when native token(ETH) is withdrawn from the module
     * @param destination_ : destination address receiving the tokens
     * @param amount_ : amount to withdraw
     *
     */
    event Withdrawn(address indexed destination_, uint256 amount_);

    /**
     * @notice function to update NDL Router Address
     * @param router_ : address of the NDL router
     * @dev only the contract Owner can call this function
     *
     */
    function setRouter(address router_) external;

    /**
     * @notice function to add/revoke destination chain ID
     * @param chainId_ : unique identifier for the destination chain
     * @param valid_ : status of the chainId
     * @dev only the contract Owner can call this function
     *
     */
    function setDestinationChainId(uint16 chainId_, bool valid_) external;

    /**
     * @notice function to add/revoke destination chain target contract
     * @param target_ : address of the destination chain target contract
     * @param valid_ : status of the chainId
     * @dev only the contract Owner can call this function
     *
     */
    function setTargetAddress(address target_, bool valid_) external;

    /**
     * @notice function to send a generic cross-chain message using Non-blocking LZ App
     * @param dstChainId_ : the destination chain identifier
     * @param payload_ : a custom bytes payload to send to the destination contract
     * @dev the fee required for cross-chain execution is paid in native passed as msg.value
     *
     */
    function sendCrossChain(uint16 dstChainId_, bytes calldata payload_) external payable;

    /**
     * @notice function to withdraw native token(ETH) from the module
     * @param amount_ : amount to withdraw
     * @dev only the contract Owner can call this function and the amount is transferred to the owner
     *
     */
    function withdraw(uint256 amount_) external;

    /**
     * @notice function to update receiver contract information on the source chain 
     * @param dstChainId_ : the destination chain identifier
     * @param receiver_ : address of the contract on destination chain implementing the IWormholeReceiver
     * @dev only the contract Owner can call this function and the amount is transferred to the owner
     *
     */
    function addWormholeReceiver(uint16 dstChainId_, address receiver_) external;

    /**
     * @notice efunction to update sender contract information on the destination chain
     * @param sender_ : address of the source chain sender module
     * @param val_ : boolean flag to allow/revoke access
     * @dev only the contract Owner can call this function and the amount is transferred to the owner
     *
     */
    function setWormholeSender(address sender_, bool val_) external;

    /**
     * @notice calculates the fee required for sending a cross-chain message
     * @param dstChainId_ : the destination chain identifier
     * @return fee_ : the fee required for cross-chain execution
     *
     */
    function quoteCrossChain(uint16 dstChainId_) external view returns (uint256 fee_);

}
