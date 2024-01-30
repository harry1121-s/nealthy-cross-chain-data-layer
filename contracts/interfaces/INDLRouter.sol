// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

interface INDLRouter {
    /**
     * @notice emitted when a new UA is whitelisted in the NDL Router
     * @param caller_ : the address of the User Application
     * @param access_ : boolean flag for access status
     *
     */
    event AuthorizedCallerUpdated(address indexed caller_, bool access_);

    /**
     * @notice emitted when a new cross-chain module is added in the NDL Router
     * @param module_ : the address of the flight module
     * @param moduleSelector_ : unique indentifier for cross-chain module to be added
     *
     */
    event ModuleAdded(address indexed module_, uint8 moduleSelector_);

    /**
     * @notice emitted when an existing cross-chain module is removed from the NDL Router
     * @param moduleSelector_ : indentifier for cross-chain module to be removed
     *
     */
    event ModuleRemoved(address indexed module_, uint8 moduleSelector_);

    /**
     * @notice emitted when a generic cross-chain message is sent to the specified destination chain and address
     * @param dstChainId_ : the destination chain identifier
     * @param moduleSelector_ : unique indentifier for cross-chain module to be used
     * @param payload_ : a custom bytes payload to send to the destination contract
     * @param fee_ : the fee paid for cross-chain execution
     *
     */
    event PayloadSent(uint16 dstChainId_, uint8 moduleSelector_, bytes payload_, uint256 fee_);

    /**
     * @notice function to allow/revoke a UA interaction with NDL Router
     * @param caller_ : the address of the User Application
     * @param access_ : boolean flag for access status
     * @dev only the contract Owner can call this function
     *
     */
    function updateAuthorizedCaller(address caller_, bool access_) external;

    /**
     * @notice function to add a cross-chain module in the NDL Router
     * @param module_ : the address of the flight module
     * @param moduleSelector_ : unique indentifier for cross-chain module to be added
     * @dev only the contract Owner can call this function
     *
     */
    function addModule(address module_, uint8 moduleSelector_) external;

    /**
     * @notice function to remove a cross-chain module from the NDL Router
     * @param moduleSelector_ : indentifier for cross-chain module to be removed
     * @dev only the contract Owner can call this function
     *
     */
    function removeModule(uint8 moduleSelector_) external;

    /**
     * @notice sends a generic cross-chain message to the specified destination chain and address
     * @param dstChainId_ : the destination chain identifier
     * @param moduleSelector_ : unique indentifier for cross-chain module to be used
     * @param payload_ : a custom bytes payload to send to the destination contract
     * @dev the fee required for cross-chain execution is paid in native passed as msg.value
     *
     */
    function send(uint16 dstChainId_, uint8 moduleSelector_, bytes calldata payload_) external payable;

    /**
     * @notice calculates the fee required for sending a cross-chain message
     * @param dstChainId_ : the destination chain identifier
     * @param moduleSelector_ : unique indentifier for cross-chain module to be used
     * @param srcApplication_ : address of the source chain UA
     * @param payload_ : a custom bytes payload to send to the destination contract
     * @return fee_ : the fee required for cross-chain execution
     *
     */
    function estimateFees(uint16 dstChainId_, uint8 moduleSelector_, address srcApplication_, bytes memory payload_)
        external
        view
        returns (uint256 fee_);
}
