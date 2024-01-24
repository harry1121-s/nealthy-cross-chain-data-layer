// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import "@layerzerolabs/contracts/lzApp/NonBlockingLzApp.sol";

contract LzModule is NonblockingLzApp {
    address public router;
    mapping(uint16 => bool) public validChainId;
    mapping(address => bool) public validTargetAddress;

    modifier onlyRouter() {
        require(msg.sender == router, "ROUTER: INVALID CALLER");
        _;
    }

    constructor(address lzEndpoint_) NonblockingLzApp(lzEndpoint_) Ownable(msg.sender) { }

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
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = 350_000;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        _lzSend(dstChainId_, payload_, payable(address(this)), address(0x0), adapterParams, msg.value);
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

    function withdraw(uint256 amount_) external onlyOwner {
        require(amount_ < address(this).balance + 1, "MODULE: InSuff Balance");
        (bool success,) = payable(msg.sender).call{ value: amount_ }("");
        require(success, "MODULE: Withdrawal Failed");
    }
}
