// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import "@openzeppelin/contracts/utils/Address.sol";
import "@layerzerolabs/contracts/lzApp/NonBlockingLzApp.sol";

contract LzModule is NonblockingLzApp {
    using Address for address;

    address public router;
    uint16 public version;
    uint256 public gasForDestinationLzReceive;
    address public LZEndpoint;
    mapping(uint16 => bool) public validChainId;
    mapping(address => bool) public validTargetAddress;

    modifier onlyRouter() {
        require(msg.sender == router, "ROUTER: INVALID CALLER");
        _;
    }

    constructor(address lzEndpoint_) NonblockingLzApp(lzEndpoint_) Ownable(msg.sender) {
        version = 1;
        gasForDestinationLzReceive = 350_000;
        LZEndpoint = lzEndpoint_;
    }

    function updateAdapterParams(uint16 version_, uint256 gasForDestinationLzReceive_) external onlyOwner {
        version = version_;
        gasForDestinationLzReceive = gasForDestinationLzReceive_;
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

    function sendCrossChain(uint16 dstChainId_, bytes memory payload_) external payable onlyRouter {
        require(validChainId[dstChainId_], "ROUTER: INVALID CHAIN ID");
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        _lzSend(dstChainId_, payload_, payable(address(this)), address(0x0), adapterParams, msg.value);
    }

    function withdraw(uint256 amount_) external onlyOwner {
        require(amount_ < address(this).balance + 1, "MODULE: InSuff Balance");
        (bool success,) = payable(msg.sender).call{ value: amount_ }("");
        require(success, "MODULE: Withdrawal Failed");
    }

    function estimateFees(uint16 dstChainId_, address srcApplication_, bytes memory payload_)
        external
        view
        returns (uint256 fee_)
    {
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

    function _nonblockingLzReceive(
        uint16 srcChainId_,
        bytes memory, /*_srcAddress*/
        uint64, /*_nonce*/
        bytes memory payload_
    ) internal override {
        // decode the number of pings sent thus far
        (address targetAddress, bytes memory data) = abi.decode(payload_, (address, bytes));
        require(validTargetAddress[targetAddress], "MODULE: Invalid Target");
        (bool success,) = targetAddress.call(data);
        require(success, "MODULE: Target Exec Failed");
    }

    receive() external payable { }
}
