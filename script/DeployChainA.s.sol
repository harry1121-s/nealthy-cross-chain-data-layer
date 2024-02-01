pragma solidity 0.8.22;

import { console, Script } from "../modules/forge-std/src/Script.sol";
import { Test } from "forge-std/Test.sol";
import { NDLRouter } from "../contracts/NDLRouter.sol";
import { LzModule } from "../contracts/modules/LzModule.sol";
import { WormholeModule } from "../contracts/modules/WormholeModule.sol";
import { Counter } from "../contracts/UAs/Counter.sol";

contract DeployChainAScript is Script, Test {

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
        _deployContracts();
        // _verifyDeployment();
        _getAddresses();
        // _configureContracts();
    }

    function _deployContracts() internal {
        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(pKey);
        // lzModule_src = new LzModule(lzEndpoint_src);
        // whModule_src = new WormholeModule(whRelayer_src);
        router_src = NDLRouter(0xefc3635CCc710A04B49b6E2A85Ff3714f029A314);
        counter_src = new Counter(address(router_src));
        vm.stopBroadcast();
    }

    function _verifyDeployment() internal {

    }

    function _getAddresses() internal view {
        console.log("--NDL SOURCE CHAIN ADDRESSES--");
        // console.log("LzModule -------------------------- ", address(lzModule_src));
        // console.log("WhModule -------------------------- ", address(whModule_src));
        // console.log("Router ---------------------------- ", address(router_src));
        console.log("UA --------------------------------", address(counter_src));
    }

    function _configureContracts() internal {

    }
}