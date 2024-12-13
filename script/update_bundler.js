const hre = require("hardhat");

const EntryPointABI = require("../artifacts/contracts/core/EntryPoint.sol/EntryPoint.json");
const ZKVizingAccountFactoryABI=require("../artifacts/contracts/ZKVizingAccountFactory.sol/ZKVizingAccountFactory.json");
const setup = require("../setup/setup.json");
const { Network } = require("inspector");

const deployedAddresses = require("../deployedAddresses.json");
async function main() {
    const [deployer, testUser, owner] = await hre.ethers.getSigners();
    console.log("deployer:",deployer.address);
    console.log("owner:", owner.address);
    console.log("testUser:", testUser.address);
    const provider = ethers.provider;
    const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";

    const deployerETHBalance = await provider.getBalance(deployer.address);
    console.log("deployerETHBalance:", deployerETHBalance);

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

    const ZKVizingAccountFactory = new ethers.Contract(
        networkData.ZKVizingAccountFactory,
        ZKVizingAccountFactoryABI.abi,
        owner
    );

    {   
        const newBundler="0x38bb2C8050374fcD3864d67838e0314Fa5469714";
        const updateBundler=await ZKVizingAccountFactory.updateBundler(newBundler);
        await updateBundler.wait();
        console.log("Update Bundler success");
    }

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});