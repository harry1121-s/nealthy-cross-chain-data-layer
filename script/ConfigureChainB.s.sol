pragma solidity 0.8.22;

import { console, Script } from "../modules/forge-std/src/Script.sol";
import { Test } from "forge-std/Test.sol";
import { NDLRouter } from "../contracts/NDLRouter.sol";
import { LzModule } from "../contracts/modules/LzModule.sol";
import { WormholeModule } from "../contracts/modules/WormholeModule.sol";
import { Counter } from "../contracts/UAs/Counter.sol";

contract ConfigureChainBScript is Script, Test {

    uint16 lzChainId_src = 10106; //fuji-testnet
    uint16 lzChainId_dst = 10102; //bsc-testnet
    uint16 whChainId_src = 6; //fuji-testnet
    uint16 whChainId_dst = 4; //bsc-testnet
    address public lzEndpoint_src = address(0x93f54D755A063cE7bB9e6Ac47Eccc8e33411d706); //fuji-testnet
    address public lzEndpoint_dst = address(0x6Fcb97553D41516Cb228ac03FdC8B9a0a9df04A1); //bsc-testnet
    address public whRelayer_src = address(0xA3cF45939bD6260bcFe3D66bc73d60f19e49a8BB); //fuji-testnet
    address public whRelayer_dst = address(0x80aC94316391752A193C1c47E27D382b507c93F3); //bsc-testnet
    


    NDLRouter public router_dst;
    LzModule public lzModule_dst;
    WormholeModule public whModule_dst;
    Counter public counter_dst;

    function run() public{
        _configureContracts();
        _verify();
    }

    function _configureContracts() internal {
        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(pKey);
        lzModule_dst = LzModule(payable(0xb65051d22D34090C65462CA3d989632024c3d961));
        router_dst = NDLRouter(0xd7abDC66EDcEb92e6E7CCE093E8A5cD76E17D8Ec);
        whModule_dst = WormholeModule(0x02a7DE48140D9D5843d71262d6790614b9cb6646);
        counter_dst = Counter(0x42DDDAB8759EE8Cc4E089E74802cBEF169F0D059);

        //configure LZ module
        bytes memory path_src = abi.encodePacked(0xcAed8046d2e2b9E395f9b6f2d0206C77E380eBD4, address(lzModule_dst));
        lzModule_dst.setTrustedRemote(lzChainId_src, path_src);
        lzModule_dst.setTargetAddress(address(counter_dst), true);
        
        
        //configure Wormhole module
        whModule_dst.setTargetAddress(address(counter_dst), true);
        whModule_dst.setWormholeSender(0x44fbb4c31410c80d454c0b870681276681C05Aeb, true);

        //configure UA
        counter_dst.addFlightModule(address(lzModule_dst));
        counter_dst.addFlightModule(address(whModule_dst));

        vm.stopBroadcast();
        console.log("Config Complete");
    }

    function _verify() internal {
        assertEq(lzModule_dst.validTargetAddress(address(counter_dst)), true, "test lzTarget");
        assertEq(whModule_dst.validTargetAddress(address(counter_dst)), true, "test whTarget");
        assertEq(counter_dst.dstChainFlightModule(address(lzModule_dst)), true, "test counter lzModule");
        assertEq(counter_dst.dstChainFlightModule(address(whModule_dst)), true, "test counter whModule");
        console.log("Verif complete");
        
    }
}