// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { LzModule } from "../contracts/modules/LzModule.sol";
import { NDLRouter } from "../contracts/NDLRouter.sol";
import { NDLEndpoint } from "../contracts/NDLEndpoint.sol";
import { INDLEndpoint } from "../contracts/interfaces/INDLEndpoint.sol";
import { Counter } from "../contracts/UAs/Counter.sol";

import { LZEndpointMock } from "@layerzerolabs/contracts/lzApp/mocks/LZEndpointMock.sol";
import { ICommonOFT } from "@layerzerolabs/contracts/token/oft/v2/interfaces/ICommonOFT.sol";

contract DataLayerTest is Test {
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

    NDLEndpoint public endpoint_src;
    NDLEndpoint public endpoint_dst;

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

        //deploy endpoint
        endpoint_src = new NDLEndpoint(address(router_src));
        endpoint_dst = new NDLEndpoint(address(router_dst));

        //deploy UA
        counter_src = new Counter(address(endpoint_src));
        counter_dst = new Counter(address(endpoint_dst));
        counter2_dst = new Counter(address(endpoint_dst));

        //configure lz modules
        lzModule_src.setRouter(address(router_src));
        lzModule_src.setDestinationChainId(chainId_dst, true);
        lzModule_dst.setTargetAddress(address(counter_dst), true);
        lzModule_dst.setTargetAddress(address(counter2_dst), true);
        // lzModule_dst.setRouter(address(router_dst));
        // lzModule_dst.setDestinationChainId(chainId_src, true);
        // lzModule_src.setTargetAddress(address(counter_src), true);

        //configure router
        router_src.updateEndpoint(address(endpoint_src));
        router_src.addModule(address(lzModule_src), 1);
        // router_dst.updateEndpoint(address(endpoint_dst));
        // router_dst.addModule(address(lzModule_dst), 1);

        //configure endpoint
        endpoint_src.addAuthorizedCaller(address(counter_src), true);
        // endpoint_dst.addAuthorizedCaller(address(counter_dst), true);

        //configure counter
        counter_src.addDstChainContract(address(counter_dst));
        counter_dst.addFlightModule(address(lzModule_dst));

        vm.stopPrank();
    }

    function test_verify_deployments() external {
        assertEq(lzModule_src.router(), address(router_src));
        assertEq(lzModule_src.validChainId(chainId_dst), true);
        assertEq(lzModule_dst.validTargetAddress(address(counter_dst)), true);

        assertEq(router_src.NDLEndpoint(), address(endpoint_src));
        assertEq(router_src.validModule(1), true);
        assertEq(router_src.flightModules(1), address(lzModule_src));

        assertEq(endpoint_src.ndlRouter(), address(router_src));
        assertEq(endpoint_src.authorizedCallers(address(counter_src)), true);

        assertEq(counter_src.dstChainContract(), address(counter_dst));
        assertEq(counter_dst.dstChainFlightModule(), address(lzModule_dst));
    }

    function test_cross_chain_counter() external {
        bytes memory payload = abi.encode(address(counter_dst), abi.encodeWithSignature("increment(uint256)", 3));
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = 350_000;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);

        uint256 sendFee = endpoint_src.estimateFees(chainId_dst, 1, address(counter_src), payload);
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
        vm.expectRevert("NDL: Router Exec Failed");
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
        vm.expectRevert("NDL: Router Exec Failed");
        counter_src.updateCounter{ value: sendFee }(3, chainId_dst, 2);
        vm.stopPrank();
    }

    function test_cross_chain_counter_fail_wrongTargetAddress() external {
        //modifying counter_src storage
        vm.store(address(counter_src), bytes32(uint256(2)), bytes32(uint256(uint160(vm.addr(56_432_433_535)))));
        assertEq(counter_src.dstChainContract(), vm.addr(56_432_433_535));

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
        assertEq(counter_src.dstChainContract(), address(counter2_dst));

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
        assertEq(router_src.validModule(1), false);
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
