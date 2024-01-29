pragma solidity 0.8.22;

import "@wormhole-solidity-sdk/src/testing/WormholeRelayerTest.sol";


abstract contract WormholeBasicTest is WormholeRelayerTest {
    /**
     * @dev virtual function to initialize source chain before each test
     */
    function setUpSource() public virtual;

    /**
     * @dev virtual function to initialize target chain before each test
     */
    function setUpTarget() public virtual;

    /**
     * @dev virtual function to initialize other active forks before each test
     * Note: not called for source/target forks
     */
    function setUpOther(ActiveFork memory fork) public virtual { }

    /*
     * aliases for activeForks
     */

    ChainInfo public sourceChainInfo;
    ChainInfo public targetChainInfo;

    uint16 public sourceChain;
    uint16 public targetChain;

    uint256 public sourceFork;
    uint256 public targetFork;

    IWormholeRelayer public relayerSource;
    ITokenBridge public tokenBridgeSource;
    IWormhole public wormholeSource;

    IWormholeRelayer public relayerTarget;
    ITokenBridge public tokenBridgeTarget;
    IWormhole public wormholeTarget;

    WormholeSimulator public guardianSource;
    WormholeSimulator public guardianTarget;

    CircleMessageTransmitterSimulator public circleAttesterSource;
    CircleMessageTransmitterSimulator public circleAttesterTarget;

    /*
     * end activeForks aliases
     */

    constructor() WormholeRelayerTest() {
        setTestnetForkChains(6, 14);
    }

    function setUp() public virtual override {
        sourceFork = 0;
        targetFork = 1;
        _setUp();
        // aliases can't be set until after setUp
        guardianSource = activeForks[activeForksList[0]].guardian;
        guardianTarget = activeForks[activeForksList[1]].guardian;
        circleAttesterSource = activeForks[activeForksList[0]].circleAttester;
        circleAttesterTarget = activeForks[activeForksList[1]].circleAttester;
        sourceFork = activeForks[activeForksList[0]].fork;
        targetFork = activeForks[activeForksList[1]].fork;
    }

    function setUpFork(ActiveFork memory fork) public override {
        if (fork.chainId == sourceChain) {
            setUpSource();
        } else if (fork.chainId == targetChain) {
            setUpTarget();
        } else {
            setUpOther(fork);
        }
    }

    function setActiveForks(ChainInfo[] memory chainInfos) public override {
        _setActiveForks(chainInfos);

        sourceChainInfo = chainInfos[0];
        sourceChain = sourceChainInfo.chainId;
        relayerSource = sourceChainInfo.relayer;
        tokenBridgeSource = sourceChainInfo.tokenBridge;
        wormholeSource = sourceChainInfo.wormhole;

        targetChainInfo = chainInfos[1];
        targetChain = targetChainInfo.chainId;
        relayerTarget = targetChainInfo.relayer;
        tokenBridgeTarget = targetChainInfo.tokenBridge;
        wormholeTarget = targetChainInfo.wormhole;
    }

    function setTestnetForkChains(uint16 _sourceChain, uint16 _targetChain) public {
        ChainInfo[] memory forks = new ChainInfo[](2);
        forks[0] = chainInfosTestnet[_sourceChain];
        forks[1] = chainInfosTestnet[_targetChain];
        setActiveForks(forks);
    }

    function setMainnetForkChains(uint16 _sourceChain, uint16 _targetChain) public {
        ChainInfo[] memory forks = new ChainInfo[](2);
        forks[0] = chainInfosMainnet[_sourceChain];
        forks[1] = chainInfosMainnet[_targetChain];
        setActiveForks(forks);
    }

    function setForkChains(bool testnet, uint16 _sourceChain, uint16 _targetChain) public {
        if (testnet) {
            setTestnetForkChains(_sourceChain, _targetChain);
            return;
        }
        setMainnetForkChains(_sourceChain, _targetChain);
    }
}
