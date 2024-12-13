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
    if (currentChainId === 28516n) {
        networkName = "Vizing-testnet";
    } else if (currentChainId === 11155111n) {
        networkName = "Sepolia";
    } else if (currentChainId === 84532n) {
        networkName = "Base-sepolia";
    } else if (currentChainId === 421614n) {
        networkName = "Arbitrum-sepolia";
    } else if (currentChainId === 808813n) {
        networkName = "Bob-testnet";
    } else if (currentChainId === 2442n) {
        networkName = "PolygonzkEVM-Cardona";
    } else if (currentChainId === 195n) {
        networkName = "XLayer-testnet";
    } else if (currentChainId === 11155420n) {
        networkName = "Optimism-sepolia";
    } else if (currentChainId === 168587773n) {
        networkName = "Blast-testnet";
    } else if (currentChainId === 534351n) {
        networkName = "Scroll-sepolia";
    } else if (currentChainId === 300n) {
        networkName = "zkSync-sepolia";
    } else if (currentChainId === 167009n) {
        networkName = "Taiko-hekla";
    } else {
        throw ("Not network");
    }
    let networkData = deployedAddresses[networkName]
    console.log("Network Data:", networkData);

    // const VizingSwap = new ethers.Contract(
    //     networkData.VizingSwap,
    //     VizingSwapABI.abi,
    //     deployer
    // );

    // const SyncRouter = new ethers.Contract(
    //     networkData.SyncRouter,
    //     SyncRouterABI.abi,
    //     deployer
    // );

    // const ZKVizingAccountFactory = new ethers.Contract(
    //     networkData.ZKVizingAccountFactory,
    //     ZKVizingAccountFactoryABI.abi,
    //     deployer
    // );

    const VizingSwap = new ethers.Contract(
        networkData.VizingSwap,
        VizingSwapABI.abi,
        owner
    );

    const SyncRouter = new ethers.Contract(
        networkData.SyncRouter,
        SyncRouterABI.abi,
        owner
    );

    const ZKVizingAccountFactory = new ethers.Contract(
        networkData.ZKVizingAccountFactory,
        ZKVizingAccountFactoryABI.abi,
        owner
    );



    //setMirrorEntryPoint
    async function SetMirrorEntryPoint(chainId, contractAddress) {
        try {
            const setMirrorEntryPoint = await SyncRouter.setMirrorEntryPoint(chainId, contractAddress);
            await setMirrorEntryPoint.wait();
            console.log("SetMirrorEntryPoint success");
        } catch (e) {
            console.log("SetMirrorEntryPoint fail:", e);
        }
    }

    // transfer owner and manager
    {
        // const transferOwner1=await SyncRouter.transferOwnership(owner.address);
        // await transferOwner1.wait();
        // console.log("SyncRouter transferOwner success");

        // const transferManager=await VizingSwap.setManager(owner.address);
        // await transferManager.wait();
        // console.log("VizingSwap setManager success");

        // const transferOwner2=await VizingSwap.transferOwnership(owner.address);
        // await transferOwner2.wait();
        // console.log("VizingSwap transferOwner success");

        // const transfer_zkVizingAccountFactory_owner=await ZKVizingAccountFactory.transferOwnership(owner.address);
        // await transfer_zkVizingAccountFactory_owner.wait();
        // console.log("ZKVizingAccountFactory transferOwner success");
    }

    {
        await SetMirrorEntryPoint(deployedAddresses["Arbitrum-sepolia"].ChainId, deployedAddresses["Arbitrum-sepolia"].EntryPoint);
        await SetMirrorEntryPoint(deployedAddresses["Blast-testnet"].ChainId, deployedAddresses["Blast-testnet"].EntryPoint);
        await SetMirrorEntryPoint(deployedAddresses["Optimism-sepolia"].ChainId, deployedAddresses["Optimism-sepolia"].EntryPoint);
        await SetMirrorEntryPoint(deployedAddresses["Base-sepolia"].ChainId, deployedAddresses["Base-sepolia"].EntryPoint);
        // await SetMirrorEntryPoint(deployedAddresses["Sepolia"].ChainId, deployedAddresses["Sepolia"].EntryPoint);
        await SetMirrorEntryPoint(deployedAddresses["Vizing-testnet"].ChainId, deployedAddresses["Vizing-testnet"].EntryPoint);
    }

    /** initialize vizingswap  */
    for (let i = 0; i < setup["UniswapV3-Router-Testnet"].length; i++) {
        let currentSetUniV3ChainId = BigInt(setup["UniswapV3-Router-Testnet"][i].ChainId);
        if (currentChainId === currentSetUniV3ChainId) {
            const addUniV3Router = await VizingSwap.initialize(networkData.SyncRouter, setup["UniswapV3-Router-Testnet"][i].Address);
            await addUniV3Router.wait();
            console.log(`initialize vizingswap in ${setup["UniswapV3-Router-Testnet"][i].Name} success`);
        }
    }



}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});