// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { LzModule } from "../contracts/modules/LzModule.sol";
import { WormholeModule } from "../contracts/modules/WormholeModule.sol";
import { NDLRouter } from "../contracts/NDLRouter.sol";
import { Counter } from "../contracts/UAs/Counter.sol";

import { LZEndpointMock } from "@layerzerolabs/contracts/lzApp/mocks/LZEndpointMock.sol";
import { ICommonOFT } from "@layerzerolabs/contracts/token/oft/v2/interfaces/ICommonOFT.sol";

import { WormholeBasicTest } from "./WormholeBasicTest.sol";

contract LzModuleTest is Test {
    uint256 mainnetFork;

    address public owner = vm.addr(12_345);
    address public user1 = vm.addr(123);
    address public user2 = vm.addr(456);

    uint16 a = 1;
    uint256 b = 200_000;
    bytes defaultAdapterParams = abi.encodePacked(a, b);

    uint16 chainId_src = 1;
    uint16 chainId_dst = 2;
    uint8 public offset = 0;

    LZEndpointMock public LZEndpoint_src;
    LZEndpointMock public LZEndpoint_dst;

    LzModule public lzModule_src;
    LzModule public lzModule_dst;

    NDLRouter public router_src;
    NDLRouter public router_dst;

    Counter public counter_src;
    Counter public counter_dst;
    Counter public counter2_dst;

    function setUp() public {
        vm.startPrank(owner);

        // Deploy mock LZEndpoints
        LZEndpoint_src = new LZEndpointMock(chainId_src);
        LZEndpoint_dst = new LZEndpointMock(chainId_dst);

        //deploy lz flight modules
        lzModule_src = new LzModule(address(LZEndpoint_src));
        lzModule_dst = new LzModule(address(LZEndpoint_dst));

        //for internal book-keeping in mocks
        LZEndpoint_src.setDestLzEndpoint(address(lzModule_dst), address(LZEndpoint_dst));
        LZEndpoint_dst.setDestLzEndpoint(address(lzModule_src), address(LZEndpoint_src));

        //LZ configurations
        bytes memory path_dst = abi.encodePacked(address(lzModule_dst), address(lzModule_src));
        bytes memory path_src = abi.encodePacked(address(lzModule_src), address(lzModule_dst));
        lzModule_src.setTrustedRemote(chainId_dst, path_dst);
        lzModule_dst.setTrustedRemote(chainId_src, path_src);

        //deploy router
        router_src = new NDLRouter();
        router_dst = new NDLRouter();

        //deploy UA
        counter_src = new Counter(address(router_src));
        counter_dst = new Counter(address(router_dst));
        counter2_dst = new Counter(address(router_dst));

        //configure lz modules
        lzModule_src.setRouter(address(router_src));
        lzModule_src.setDestinationChainId(chainId_dst, true);
        lzModule_dst.setTargetAddress(address(counter_dst), true);
        lzModule_dst.setTargetAddress(address(counter2_dst), true);
        // lzModule_dst.setRouter(address(router_dst));
        // lzModule_dst.setDestinationChainId(chainId_src, true);
        // lzModule_src.setTargetAddress(address(counter_src), true);

        //configure router
        router_src.addModule(address(lzModule_src), 1);
        // router_dst.addModule(address(lzModule_dst), 1);

        //configure endpoint
        router_src.updateAuthorizedCaller(address(counter_src), true);

        //configure counter
        counter_src.addDstChainContract(address(counter_dst));
        counter_dst.addFlightModule(address(lzModule_dst));

        vm.stopPrank();
    }

    function test_verify_deployments() external {
        assertEq(lzModule_src.router(), address(router_src));
        assertEq(lzModule_src.validChainId(chainId_dst), true);
        assertEq(lzModule_dst.validTargetAddress(address(counter_dst)), true);

        assertEq(router_src.flightModules(1), address(lzModule_src));

        assertEq(router_src.authorizedCallers(address(counter_src)), true);

        assertEq(address(uint160(uint256(counter_src.dstChainContract()))), address(counter_dst));
        assertEq(counter_dst.dstChainFlightModule(), address(lzModule_dst));
    }

    function test_fail_cases() external {
        vm.startPrank(owner);
        vm.expectRevert("MODULE: Invalid Router Address");
        lzModule_src.setRouter(address(0));

        vm.expectRevert("MODULE: Invalid Target Address");
        lzModule_src.setTargetAddress(address(0), true);

        vm.stopPrank();
    }

    function test_update_adapterParams() external {
        vm.prank(owner);
        lzModule_src.updateAdapterParams(2, 400_000);

        assertEq(lzModule_src.version(), 2);
        assertEq(lzModule_src.gasForDestinationLzReceive(), 400_000);
    }

    function test_cross_chain_counter() external {
        bytes memory payload = abi.encode(address(counter_dst), abi.encodeWithSignature("increment(uint256)", 3));
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = 350_000;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);

        uint256 sendFee = router_src.estimateFees(chainId_dst, 1, address(counter_src), payload);
        deal(user1, sendFee);
        vm.prank(user1);
        counter_src.updateCounter{ value: sendFee }(3, chainId_dst, 1);
        assertEq(counter_src.count(), 0);
        assertEq(counter_dst.count(), 3);
    }

    function test_cross_chain_counter_fail_wrongDstChainId() external {
        bytes memory payload = abi.encode(address(counter_dst), abi.encodeWithSignature("increment(uint256)", 3));
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = 350_000;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        (uint256 sendFee,) =
            LZEndpoint_src.estimateFees(chainId_dst, address(counter_src), payload, false, adapterParams);
        deal(user1, sendFee);
        vm.startPrank(user1);
        vm.expectRevert("ROUTER: Module Exec Failed");
        counter_src.updateCounter{ value: sendFee }(3, 10, 1);
        vm.stopPrank();
    }

    function test_cross_chain_counter_fail_wrongModule() external {
        bytes memory payload = abi.encode(address(counter_dst), abi.encodeWithSignature("increment(uint256)", 3));
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = 350_000;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        (uint256 sendFee,) =
            LZEndpoint_src.estimateFees(chainId_dst, address(counter_src), payload, false, adapterParams);
        deal(user1, sendFee);
        vm.startPrank(user1);
        vm.expectRevert("ROUTER: Invalid Module");
        counter_src.updateCounter{ value: sendFee }(3, chainId_dst, 2);
        vm.stopPrank();
    }

    function test_cross_chain_counter_fail_wrongTargetAddress() external {
        //modifying counter_src storage
        vm.store(address(counter_src), bytes32(uint256(2)), bytes32(uint256(uint160(vm.addr(56_432_433_535)))));
        assertEq(address(uint160(uint256(counter_src.dstChainContract()))), vm.addr(56_432_433_535));

        bytes memory payload = abi.encode(address(counter_dst), abi.encodeWithSignature("increment(uint256)", 3));
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = 350_000;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        (uint256 sendFee,) =
            LZEndpoint_src.estimateFees(chainId_dst, address(counter_src), payload, false, adapterParams);
        deal(user1, sendFee);
        vm.prank(user1);
        counter_src.updateCounter{ value: sendFee }(3, chainId_dst, 1);

        assertEq(counter_src.count(), 0);
        assertEq(counter_dst.count(), 0); //because of invalid target address
    }

    function test_cross_chain_counter_failTargetExec() external {
        //modifying counter_src storage
        vm.store(address(counter_src), bytes32(uint256(2)), bytes32(uint256(uint160(address(counter2_dst)))));
        assertEq(address(uint160(uint256(counter_src.dstChainContract()))), address(counter2_dst));

        bytes memory payload = abi.encode(address(counter2_dst), abi.encodeWithSignature("increment(uint256)", 3));
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = 350_000;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        (uint256 sendFee,) =
            LZEndpoint_src.estimateFees(chainId_dst, address(counter_src), payload, false, adapterParams);
        deal(user1, sendFee);
        vm.prank(user1);
        counter_src.updateCounter{ value: sendFee }(3, chainId_dst, 1);

        assertEq(counter_src.count(), 0);
        assertEq(counter_dst.count(), 0); //because of invalid target address
        assertEq(counter2_dst.count(), 0); //because of invalid target address
    }

    function test_remove_module_router() external {
        vm.prank(owner);
        router_src.removeModule(1);
        assertEq(router_src.flightModules(1), address(0x0));
    }

    function test_withdaw_lzModule() external {
        deal(address(lzModule_src), 1e18);
        assertEq(address(lzModule_src).balance, 1e18);

        vm.startPrank(owner);

        vm.expectRevert("MODULE: InSuff Balance");
        lzModule_src.withdraw(2e18);

        lzModule_src.withdraw(1e18);
        assertEq(owner.balance, 1e18);
        assertEq(address(lzModule_src).balance, 0);
    }
}

contract WormHoleModuleTest is WormholeBasicTest {
    address public owner = vm.addr(12_345);
    address public user1 = vm.addr(123);
    address public user2 = vm.addr(456);

    WormholeModule public wrmModule_src;
    WormholeModule public wrmModule_dst;

    NDLRouter public router_src;
    NDLRouter public router_dst;

    Counter public counter_src;
    Counter public counter_dst;

    function setUpSource() public override {
        vm.startPrank(owner);
        wrmModule_src = new WormholeModule(address(relayerSource));
        router_src = new NDLRouter();
        counter_src = new Counter(address(router_src));

        wrmModule_src.setRouter(address(router_src));
        wrmModule_src.setDestinationChainId(targetChain, true);
        router_src.addModule(address(wrmModule_src), 2);
        router_src.updateAuthorizedCaller(address(counter_src), true);
        vm.stopPrank();
    }

    function setUpTarget() public override {
        vm.startPrank(owner);
        wrmModule_dst = new WormholeModule(address(relayerTarget));
        router_dst = new NDLRouter();
        counter_dst = new Counter(address(router_dst));

        wrmModule_dst.setTargetAddress(address(counter_dst), true);
        wrmModule_dst.setWormholeSender(address(wrmModule_src), true);
        counter_dst.addFlightModule(address(wrmModule_dst));
        vm.selectFork(sourceFork);
        wrmModule_src.addWormholeReceiver(targetChain, address(wrmModule_dst));
        counter_src.addDstChainContract(address(counter_dst));
        vm.selectFork(targetFork);
        vm.stopPrank();
    }

    function test_router_fail_cases() external {
        vm.startPrank(owner);
        vm.expectRevert("ROUTER: Selector already in use");
        router_src.addModule(vm.addr(123456789), 1);

        vm.expectRevert("ROUTER: Module does not exist");
        router_src.removeModule(3);

        vm.stopPrank();
    }

    function test_fail_cases() external {
        vm.startPrank(owner);

        vm.expectRevert("MODULE: Invalid Router Address");
        wrmModule_src.setRouter(address(0));

        vm.expectRevert("MODULE: Invalid Target Address");
        wrmModule_src.setTargetAddress(address(0), true);

        vm.expectRevert("MODULE: Invalid Receiver Address");
        wrmModule_src.addWormholeReceiver(1, address(0));

        vm.expectRevert("MODULE: Invalid Sender Address");
        wrmModule_src.setWormholeSender(address(0), true);

        vm.stopPrank();
    }

    function test_cross_chain_counter() external {
        uint256 sendFee = wrmModule_src.quoteCrossChain(targetChain);
        vm.recordLogs();
        deal(user1, sendFee);
        vm.prank(user1);
        counter_src.updateCounter{ value: sendFee }(3, targetChain, 2);
        performDelivery();
        assertEq(counter_src.count(), 0);
        vm.selectFork(targetFork);
        assertEq(counter_dst.count(), 3);
    }

    function test_cross_chain_counter_fail_inSuff_fee() external {
        uint256 sendFee = wrmModule_src.quoteCrossChain(targetChain);
        vm.recordLogs();
        deal(user1, sendFee);
        vm.startPrank(user1);
        vm.expectRevert();
        counter_src.updateCounter{ value: sendFee / 2 }(3, targetChain, 2);
        vm.stopPrank();

        assertEq(counter_src.count(), 0);
        vm.selectFork(targetFork);
        assertEq(counter_dst.count(), 0);
    }

    function test_cross_chain_counter_fail_wrongDstChainId() external {
        uint256 sendFee = wrmModule_src.quoteCrossChain(targetChain);
        vm.recordLogs();
        deal(user1, sendFee);
        vm.startPrank(user1);
        vm.expectRevert("ROUTER: Module Exec Failed");
        counter_src.updateCounter{ value: sendFee }(3, 45, 2);
        vm.stopPrank();
        assertEq(counter_src.count(), 0);
        vm.selectFork(targetFork);
        assertEq(counter_dst.count(), 0);
    }

    function test_cross_chain_counter_fail_wrongModule() external {
        uint256 sendFee = wrmModule_src.quoteCrossChain(targetChain);
        vm.recordLogs();
        deal(user1, sendFee);
        vm.startPrank(user1);
        vm.expectRevert("ROUTER: Invalid Module");
        counter_src.updateCounter{ value: sendFee }(3, targetChain, 1);
        vm.stopPrank();
        assertEq(counter_src.count(), 0);
        vm.selectFork(targetFork);
        assertEq(counter_dst.count(), 0);
    }

    function test_cross_chain_counter_fail_wrongTargetAddress() external {
        //modifying counter_src storage
        vm.store(address(counter_src), bytes32(uint256(2)), bytes32(uint256(uint160(vm.addr(56_432_433_535)))));
        assertEq(address(uint160(uint256(counter_src.dstChainContract()))), vm.addr(56_432_433_535));

        uint256 sendFee = wrmModule_src.quoteCrossChain(targetChain);
        vm.recordLogs();
        deal(user1, sendFee);
        vm.prank(user1);
        counter_src.updateCounter{ value: sendFee }(3, targetChain, 2);
        performDelivery();
        assertEq(counter_src.count(), 0);
        vm.selectFork(targetFork);
        assertEq(counter_dst.count(), 0); //because invalid target address
    }

    function test_cross_chain_counter_fail_invalid_sender() external {
        vm.startPrank(owner);
        vm.selectFork(targetFork);
        wrmModule_dst.setWormholeSender(address(wrmModule_src), false);
        console.log("test: ", wrmModule_dst.wormholeSenders(address(wrmModule_src)), false);
        vm.stopPrank();

        vm.selectFork(sourceFork);
        uint256 sendFee = wrmModule_src.quoteCrossChain(targetChain);
        vm.recordLogs();
        deal(user1, sendFee);
        vm.startPrank(user1);
        counter_src.updateCounter{ value: sendFee }(3, targetChain, 2);
        vm.stopPrank();
        performDelivery();
        assertEq(counter_src.count(), 0);
        vm.selectFork(targetFork);
        assertEq(counter_dst.count(), 0);
    }

    function test_remove_module_router() external {
        assertEq(router_src.flightModules(2), address(wrmModule_src));
        vm.prank(owner);
        router_src.removeModule(2);
        assertEq(router_src.flightModules(2), address(0x0));
    }

    function test_withdaw_wrmModule() external {
        deal(address(wrmModule_src), 1e18);
        assertEq(address(wrmModule_src).balance, 1e18);

        vm.startPrank(owner);

        vm.expectRevert("MODULE: InSuff Balance");
        wrmModule_src.withdraw(2e18);

        wrmModule_src.withdraw(1e18);
        assertEq(owner.balance, 1e18);
        assertEq(address(wrmModule_src).balance, 0);
        vm.stopPrank();
    }
}
