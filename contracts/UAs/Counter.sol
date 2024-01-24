pragma solidity 0.8.22;

import { INDLEndpoint } from "../interfaces/INDLEndpoint.sol";

contract Counter {
    uint256 public count = 0;
    address public ndlEndpoint;
    address public dstChainContract;
    address public dstChainFlightModule;

    modifier onlyModule() {
        require(msg.sender == dstChainFlightModule, "Counter: invalid caller");
        _;
    }

    constructor(address endpoint_) {
        ndlEndpoint = endpoint_;
    }

    function addDstChainContract(address dstChainContract_) external {
        dstChainContract = dstChainContract_;
    }

    function addFlightModule(address dstChainFlightModule_) external {
        dstChainFlightModule = dstChainFlightModule_;
    }

    function updateCounter(uint256 val_, uint16 dstChainId_, uint8 moduleSelector_) external payable {
        bytes memory payload = abi.encode(dstChainContract, abi.encodeWithSignature("increment(uint256)", val_));
        INDLEndpoint(ndlEndpoint).send{ value: msg.value }(dstChainId_, moduleSelector_, payload);
    }

    function increment(uint256 val_) external onlyModule {
        count += val_;
    }
}