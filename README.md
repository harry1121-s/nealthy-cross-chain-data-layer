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
