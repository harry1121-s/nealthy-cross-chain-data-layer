pragma solidity 0.8.22;

import { INDLRouter } from "../interfaces/INDLRouter.sol";

contract Counter {
    uint256 public count = 0;
    address public ndlRouter;
    bytes32 public dstChainContract;
    address public dstChainFlightModule;

    modifier onlyModule() {
        require(msg.sender == dstChainFlightModule, "Counter: invalid caller");
        _;
    }

    constructor(address router_) {
        ndlRouter = router_;
    }

    function addDstChainContract(address dstChainContract_) external {
        dstChainContract = bytes32(uint256(uint160(dstChainContract_)));
    }

    function addFlightModule(address dstChainFlightModule_) external {
        dstChainFlightModule = dstChainFlightModule_;
    }

    function updateCounter(uint256 val_, uint16 dstChainId_, uint8 moduleSelector_) external payable {
        bytes memory payload = abi.encode(dstChainContract, abi.encodeWithSignature("increment(uint256)", val_));
        INDLRouter(ndlRouter).send{ value: msg.value }(dstChainId_, moduleSelector_, payload);
    }

    function increment(uint256 val_) external onlyModule returns (uint256 result_) {
        count += val_;
        result_ = count;
    }
}
