const hre = require("hardhat");

const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const WETHABI = require("../artifacts/contracts/WETH.sol/WETH9.json");
const EntryPointABI = require("../artifacts/contracts/core/EntryPoint.sol/EntryPoint.json");
const ZKVizingAccountFactoryABI = require("../artifacts/contracts/ZKVizingAccountFactory.sol/ZKVizingAccountFactory.json");
const SyncRouterABI = require("../artifacts/contracts/core/SyncRouter.sol/SyncRouter.json");
const VizingSwapABI = require("../artifacts/contracts/hook/VizingSwap.sol/VizingSwap.json");
const setup = require("../setup/setup.json");
const { Network } = require("inspector");

const deployedAddresses = require("../deployedAddresses.json");
async function main() {
    const [deployer, testUser, owner] = await hre.ethers.getSigners();
    console.log("owner:", owner.address);
    console.log("testUser:", testUser.address);
    const provider = ethers.provider;
    const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";

    const ownerETHBalance = await provider.getBalance(owner.address);
    console.log("ownerETHBalance:", ownerETHBalance);

    const network = await provider.getNetwork();
    const currentChainId = network.chainId;
    console.log("Current Chain ID:", currentChainId);

    let networkName;
    if(currentChainId===28516n){
        networkName="Vizing-testnet";
    }else if(currentChainId===11155111n){
        networkName="Sepolia";
    }else if(currentChainId===84532n){
        networkName="Base-sepolia";
    }else if(currentChainId===421614n){
        networkName="Arbitrum-sepolia";
    }else if(currentChainId===808813n){
        networkName="Bob-testnet";
    }else if(currentChainId===2442n){
        networkName="PolygonzkEVM-Cardona";
    }else if(currentChainId===195n){
        networkName="XLayer-testnet";
    }else if(currentChainId===11155420n){
        networkName="Optimism-sepolia";
    }else if(currentChainId===168587773n){
        networkName="Blast-testnet";
    }else if(currentChainId===534351n){
        networkName="Scroll-sepolia";
    }else if(currentChainId===300n){
        networkName="zkSync-sepolia";
    }else if(currentChainId===167009n){
        networkName="Taiko-hekla";
    }else{
        throw("Not network");
    }
    let networkData=deployedAddresses[networkName]
    console.log("Network Data:", networkData);

    const VizingSwap = new ethers.Contract(
        networkData.VizingSwap,
        VizingSwapABI.abi,
        owner
    );

    /** add routers */
    for(let i=0;i<setup["UniswapV3-Router-Testnet"].length;i++){
        let currentSetUniV3ChainId=BigInt(setup["UniswapV3-Router-Testnet"][i].ChainId);
        if(currentChainId===currentSetUniV3ChainId){
            const addUniV3Router=await VizingSwap.addRouter(setup["UniswapV3-Router-Testnet"][i].Address);
            await addUniV3Router.wait();
            console.log(`addUniV3Router in ${setup["UniswapV3-Router-Testnet"][i].Name} success`);
        }
    }
        
    

}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});