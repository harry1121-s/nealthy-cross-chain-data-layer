# Nealthy Data Layer
Nealthy Data Layer intends to provide a seamless cross-chain messaging for 3rd party UA, abstracting away
the complexities and hurdles that comes with different messaging protocols such as LayerZero, Wormhole, axelar, etc.
The UA interact with a single router endpoint deployed on supported chains, and can switch between various messaging protocols(based on requirement) using a simple selector.

## Interaction Flow
UA on source chain -> Router -> messaging module |--- cross-chain messaging ---| receiving module -> UA on destination chain

## User Interaction Endpoint
The router endpoint has 2 exposed function for user interaction:
1. function send(uint16 dstChainId_, uint8 moduleSelector_, bytes calldata payload_) : Performs a cross-chain transaction
2. function estimateFees(uint16 dstChainId_, uint8 moduleSelector_, address srcApplication_, bytes memory payload_) : Estimates the fee required for a cross-chain transaction

## Limitations of the current system
1. Lack of monitoring service for gas refund, failed transaction
2. Lack of transaction monitoring in case of Wormhole
3. Fixed gas for destination chains
4. TBA

## Next Steps
1. Testnet deployment and further testing
2. Monitoring service

## Adresses
--NDL SOURCE CHAIN ADDRESSES--
  LzModule --------------------------  0xcAed8046d2e2b9E395f9b6f2d0206C77E380eBD4
  WhModule --------------------------  0x44fbb4c31410c80d454c0b870681276681C05Aeb
  Router ----------------------------  0xefc3635CCc710A04B49b6E2A85Ff3714f029A314
  UA -------------------------------- 0xEcFd9c649bbf2C7B19bcE4157e57AF579254A1c2

--NDL DESTINATION CHAIN ADDRESSES--
  LzModule --------------------------  0xb65051d22D34090C65462CA3d989632024c3d961
  WhModule --------------------------  0x02a7DE48140D9D5843d71262d6790614b9cb6646
  Router ----------------------------  0xd7abDC66EDcEb92e6E7CCE093E8A5cD76E17D8Ec
  UA -------------------------------- 0x42DDDAB8759EE8Cc4E089E74802cBEF169F0D059