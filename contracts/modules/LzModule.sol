// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import "@openzeppelin/contracts/utils/Address.sol";
import "@layerzerolabs/contracts/lzApp/NonBlockingLzApp.sol";
import { ILzModule } from "../interfaces/ILzModule.sol";

contract LzModule is ILzModule, NonblockingLzApp {
    using Address for address;

    /*//////////////////////////////////////////////////////////////
    STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address public router;
    uint16 public version;
    uint256 public gasForDestinationLzReceive;
    address public LZEndpoint;
    mapping(uint16 => bool) public validChainId;
    mapping(address => bool) public validTargetAddress;

    /*//////////////////////////////////////////////////////////////
    MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyRouter() {
        require(msg.sender == router, "ROUTER: INVALID CALLER");
        _;
    }

    /*//////////////////////////////////////////////////////////////
    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address lzEndpoint_) NonblockingLzApp(lzEndpoint_) Ownable(msg.sender) {
        version = 1;
        gasForDestinationLzReceive = 350_000;
        LZEndpoint = lzEndpoint_;
        emit AdapterParamsUpdated(version, gasForDestinationLzReceive);
        emit LzEndpointUpdated(address(0), lzEndpoint_);
    }

    /*//////////////////////////////////////////////////////////////
    EXTERNALS
    //////////////////////////////////////////////////////////////*/
    /**
     * @inheritdoc ILzModule
     */
    function sendCrossChain(uint16 dstChainId_, bytes calldata payload_) external payable onlyRouter {
        require(validChainId[dstChainId_], "MODULE: INVALID CHAIN ID");
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        _lzSend(dstChainId_, payload_, payable(address(this)), address(0x0), adapterParams, msg.value);
        emit LzPayloadSent(dstChainId_, payload_, adapterParams, msg.value);
    }

    /**
     * @inheritdoc ILzModule
     */
    function estimateFees(uint16 dstChainId_, address srcApplication_, bytes memory payload_)
        external
        view
        returns (uint256 fee_)
    {
        require(validChainId[dstChainId_], "MODULE: INVALID CHAIN ID");
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        (bytes memory val) = LZEndpoint.functionStaticCall(
            abi.encodeWithSignature(
                "estimateFees(uint16,address,bytes,bool,bytes)",
                dstChainId_,
                srcApplication_,
                payload_,
                false,
                adapterParams
            )
        );
        fee_ = uint256(bytes32(val));
    }

    /*//////////////////////////////////////////////////////////////
    OWNER ONLY
    //////////////////////////////////////////////////////////////*/
    /**
     * @inheritdoc ILzModule
     */
    function updateAdapterParams(uint16 version_, uint256 gasForDestinationLzReceive_) external onlyOwner {
        version = version_;
        gasForDestinationLzReceive = gasForDestinationLzReceive_;
        emit AdapterParamsUpdated(version_, gasForDestinationLzReceive_);
    }

    /**
     * @inheritdoc ILzModule
     */
    function setRouter(address router_) external onlyOwner {
        require(router_ != address(0), "MODULE: Invalid Router Address");
        address oldRouter = router;
        router = router_;
        emit RouterUpdated(oldRouter, router);
    }

    /**
     * @inheritdoc ILzModule
     */
    function setDestinationChainId(uint16 chainId_, bool valid_) external onlyOwner {
        validChainId[chainId_] = valid_;
        emit DestinationChainIdUpdated(chainId_, valid_);
    }

    /**
     * @inheritdoc ILzModule
     */
    function setTargetAddress(address target_, bool valid_) external onlyOwner {
        require(target_ != address(0), "MODULE: Invalid Target Address");
        validTargetAddress[target_] = valid_;
        emit TargetAddressUpdated(target_, valid_);
    }

    /**
     * @inheritdoc ILzModule
     */
    function withdraw(uint256 amount_) external onlyOwner {
        require(amount_ < address(this).balance + 1, "MODULE: InSuff Balance");
        (bool success,) = payable(msg.sender).call{ value: amount_ }("");
        require(success, "MODULE: Withdrawal Failed");
        emit Withdrawn(msg.sender, amount_);
    }

    /*//////////////////////////////////////////////////////////////
    LZ Internal
    //////////////////////////////////////////////////////////////*/
    function _nonblockingLzReceive(
        uint16 srcChainId_,
        bytes memory, /*_srcAddress*/
        uint64, /*_nonce*/
        bytes memory payload_
    ) internal override {
        (bytes32 target, bytes memory data) = abi.decode(payload_, (bytes32, bytes));
        address targetAddress = address(uint160(uint256(target)));
        require(validTargetAddress[targetAddress], "MODULE: Invalid Target");
        (bool success,) = targetAddress.call(data);
        require(success, "MODULE: Target Exec Failed");
    }

    receive() external payable { }
}
