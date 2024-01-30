pragma solidity 0.8.22;

interface ILzModule {
    /**
     * @notice emitted when LZ adapter parameters are updated
     * @param version_ : the LZ endpoint version
     * @param gasForDestinationLzReceive_ : gas limit for destination chain
     *
     */
    event AdapterParamsUpdated(uint16 version_, uint256 gasForDestinationLzReceive_);

    /**
     * @notice emitted when NDL Router Address is updated
     * @param oldRouter_ : address of the existing NDL router
     * @param newRouter_ : address of the new NDL router
     *
     */
    event RouterUpdated(address indexed oldRouter_, address indexed newRouter_);

    /**
     * @notice emitted when LZ Endpoint Address is updated
     * @param oldEndpoint_ : address of the existing NDL router
     * @param newEndpoint_ : address of the new NDL router
     *
     */
    event LzEndpointUpdated(address indexed oldEndpoint_, address indexed newEndpoint_);

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
     * @notice emitted when a generic cross-chain message is sent
     * @param dstChainId_ : the destination chain identifier
     * @param payload_ : a custom bytes payload to send to the destination contract
     * @param adapterParams_ : custom bytes representing parameters for the LZ adapter
     * @param fee_ : the fee required for cross-chain execution paid in native passed as msg.value
     *
     */
    event LzPayloadSent(uint16 dstChainId_, bytes payload_, bytes adapterParams_, uint256 fee_);

    /**
     * @notice emitted when native token(ETH) is withdrawn from the module
     * @param destination_ : destination address receiving the tokens
     * @param amount_ : amount to withdraw
     *
     */
    event Withdrawn(address indexed destination_, uint256 amount_);

    /**
     * @notice function to update LZ adapter parameters
     * @param version_ : the LZ endpoint version
     * @param gasForDestinationLzReceive_ : gas limit for destination chain
     * @dev only the contract Owner can call this function
     *
     */
    function updateAdapterParams(uint16 version_, uint256 gasForDestinationLzReceive_) external;

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
     * @notice calculates the fee required for sending a cross-chain message
     * @param dstChainId_ : the destination chain identifier
     * @param srcApplication_ : address of the source chain UA
     * @param payload_ : a custom bytes payload to send to the destination contract
     * @return fee_ : the fee required for cross-chain execution
     *
     */
    function estimateFees(uint16 dstChainId_, address srcApplication_, bytes memory payload_)
        external
        view
        returns (uint256 fee_);
}
