pragma solidity 0.8.22;

import { console, Script } from "../modules/forge-std/src/Script.sol";
import { Test } from "forge-std/Test.sol";
import { NDLRouter } from "../contracts/NDLRouter.sol";
import { LzModule } from "../contracts/modules/LzModule.sol";
import { WormholeModule } from "../contracts/modules/WormholeModule.sol";
import { Counter } from "../contracts/UAs/Counter.sol";

contract ConfigureChainAScript is Script, Test {

    uint16 lzChainId_src = 10106; //fuji-testnet
    uint16 lzChainId_dst = 10102; //bsc-testnet
    uint16 whChainId_src = 6; //fuji-testnet
    uint16 whChainId_dst = 4; //bsc-testnet
    address public lzEndpoint_src = address(0x93f54D755A063cE7bB9e6Ac47Eccc8e33411d706); //fuji-testnet
    address public lzEndpoint_dst = address(0x6Fcb97553D41516Cb228ac03FdC8B9a0a9df04A1); //bsc-testnet
    address public whRelayer_src = address(0xA3cF45939bD6260bcFe3D66bc73d60f19e49a8BB); //fuji-testnet
    address public whRelayer_dst = address(0x80aC94316391752A193C1c47E27D382b507c93F3); //bsc-testnet
    


    NDLRouter public router_src;
    LzModule public lzModule_src;
    WormholeModule public whModule_src;
    Counter public counter_src;

    function run() public{
        _configureContracts();
        _verify();
    }

    function _configureContracts() internal {
        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(pKey);
        lzModule_src = LzModule(payable(0xcAed8046d2e2b9E395f9b6f2d0206C77E380eBD4));
        router_src = NDLRouter(0xefc3635CCc710A04B49b6E2A85Ff3714f029A314);
        whModule_src = WormholeModule(0x44fbb4c31410c80d454c0b870681276681C05Aeb);
        counter_src = Counter(0xEcFd9c649bbf2C7B19bcE4157e57AF579254A1c2);
        //configure LZ module
        bytes memory path_dst = abi.encodePacked(address(0xb65051d22D34090C65462CA3d989632024c3d961), address(lzModule_src));
        lzModule_src.setTrustedRemote(lzChainId_dst, path_dst);
        lzModule_src.setRouter(0xefc3635CCc710A04B49b6E2A85Ff3714f029A314);
        lzModule_src.setDestinationChainId(lzChainId_dst, true);
        
        //configure Wormhole module
        whModule_src.setRouter(address(router_src));
        whModule_src.setDestinationChainId(whChainId_dst, true);
        whModule_src.addWormholeReceiver(whChainId_dst, 0x02a7DE48140D9D5843d71262d6790614b9cb6646);

        //configure router
        router_src.addModule(address(lzModule_src), 1);
        router_src.addModule(address(whModule_src), 2);
        router_src.updateAuthorizedCaller(0xEcFd9c649bbf2C7B19bcE4157e57AF579254A1c2, true);

        //configure UA
        counter_src.addDstChainContract(0x42DDDAB8759EE8Cc4E089E74802cBEF169F0D059);
        vm.stopBroadcast();
    }

    function _verify() internal {
        assertEq(lzModule_src.router(), address(router_src));
        assertEq(lzModule_src.validChainId(lzChainId_dst), true, "check dst chain Id");
        assertEq(router_src.flightModules(1), address(lzModule_src));
        assertEq(router_src.flightModules(2), address(whModule_src));
        assertEq(router_src.authorizedCallers(address(counter_src)), true, "check router auth caller");
        assertEq(address(uint160(uint256(counter_src.dstChainContract()))), address(0x42DDDAB8759EE8Cc4E089E74802cBEF169F0D059));
    }
}