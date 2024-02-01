pragma solidity 0.8.22;

import { console, Script } from "../modules/forge-std/src/Script.sol";
import { Test } from "forge-std/Test.sol";
import { NDLRouter } from "../contracts/NDLRouter.sol";
import { LzModule } from "../contracts/modules/LzModule.sol";
import { WormholeModule } from "../contracts/modules/WormholeModule.sol";
import { Counter } from "../contracts/UAs/Counter.sol";

contract IncrementCounterScript is Script {

    address public counter_dst = 0x42DDDAB8759EE8Cc4E089E74802cBEF169F0D059;
    uint16 lzChainId_dst = 10102; //bsc-testnet
    uint16 whChainId_dst = 4; //bsc-testnet
    function run() public {
       _updateCounterWormhole();
    }

    function _updateCounterLz() internal {
        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(pKey);
        Counter counter_src = Counter(0xEcFd9c649bbf2C7B19bcE4157e57AF579254A1c2);
        LzModule lzModule_src = LzModule(payable(0xcAed8046d2e2b9E395f9b6f2d0206C77E380eBD4));
        bytes memory payload = abi.encode(counter_dst, abi.encodeWithSignature("increment(uint256)", 3));
        uint256 fee = lzModule_src.estimateFees(lzChainId_dst, address(counter_src), payload);
        counter_src.updateCounter{value: fee}(3, lzChainId_dst, 1);
        vm.stopBroadcast();
    }

    function _updateCounterWormhole() internal {
        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(pKey);
        Counter counter_src = Counter(0xEcFd9c649bbf2C7B19bcE4157e57AF579254A1c2);
        WormholeModule whModule_src = WormholeModule(0x44fbb4c31410c80d454c0b870681276681C05Aeb);
        uint256 fee = whModule_src.quoteCrossChain(whChainId_dst);
        counter_src.updateCounter{value: fee}(4, whChainId_dst, 2);
        vm.stopBroadcast();
    }
}