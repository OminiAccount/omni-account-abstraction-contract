const hre = require("hardhat");

const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const WETHABI = require("../artifacts/contracts/WETH.sol/WETH9.json");
const EntryPointABI = require("../artifacts/contracts/core/EntryPoint.sol/EntryPoint.json");
const ZKVizingAccountFactoryABI = require("../artifacts/contracts/ZKVizingAccountFactory.sol/ZKVizingAccountFactory.json");
const SyncRouterABI = require("../artifacts/contracts/core/SyncRouter.sol/SyncRouter.json");
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

    const testUserETHBalance = await provider.getBalance(testUser.address);
    console.log("testUserETHBalance:", testUserETHBalance);

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

    const SyncRouter = new ethers.Contract(
        networkData.SyncRouter,
        SyncRouterABI.abi,
        owner
    );

    //setMirrorEntryPoint
    async function SetMirrorEntryPoint(chainId, contractAddress){
        try{
            const setMirrorEntryPoint=await SyncRouter.setMirrorEntryPoint(chainId, contractAddress);
            await setMirrorEntryPoint.wait();
            console.log("SetMirrorEntryPoint success");
        }catch(e){
            console.log("SetMirrorEntryPoint fail:",e);
        }
    }

    {
        await SetMirrorEntryPoint(deployedAddresses["Arbitrum-sepolia"].ChainId, deployedAddresses["Arbitrum-sepolia"].EntryPoint);
        await SetMirrorEntryPoint(deployedAddresses["Blast-testnet"].ChainId, deployedAddresses["Blast-testnet"].EntryPoint);
        await SetMirrorEntryPoint(deployedAddresses["Optimism-sepolia"].ChainId, deployedAddresses["Optimism-sepolia"].EntryPoint);
        await SetMirrorEntryPoint(deployedAddresses["Base-sepolia"].ChainId, deployedAddresses["Base-sepolia"].EntryPoint);
        // await SetMirrorEntryPoint(deployedAddresses["Sepolia"].ChainId, deployedAddresses["Sepolia"].EntryPoint);
        await SetMirrorEntryPoint(deployedAddresses["Vizing-testnet"].ChainId, deployedAddresses["Vizing-testnet"].EntryPoint);
    }

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});