const hre = require("hardhat");
const fs = require("fs");

const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const WETHABI = require("../artifacts/contracts/WETH.sol/WETH9.json");
const EntryPointABI = require("../artifacts/contracts/core/EntryPoint.sol/EntryPoint.json");
const ZKVizingAccountFactoryABI = require("../artifacts/contracts/ZKVizingAccountFactory.sol/ZKVizingAccountFactory.json");
const SyncRouterABI = require("../artifacts/contracts/core/SyncRouter.sol/SyncRouter.json");

const setup = require("../setup/setup.json");
const { Network } = require("inspector");

async function main() {
    const [owner, testUser] = await hre.ethers.getSigners();
    console.log("owner:", owner.address);
    console.log("testUser:",testUser.address);
    const provider = ethers.provider;
    const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";

    const VizingSwapAddress="";

    const ownerETHBalance = await provider.getBalance(owner.address);
    console.log("ownerETHBalance:", ownerETHBalance);

    const testUserETHBalance = await provider.getBalance(testUser.address);
    console.log("testUserETHBalance:", testUserETHBalance);

    if(testUserETHBalance<=ethers.parseEther("0.01")){
        throw("Test user insufficient eth");
    }

    const network = await provider.getNetwork();
    const currentChainId = network.chainId; 
    console.log("currentChainId:", currentChainId); 

    const testCall=await hre.ethers.getContractFactory("VizingSwap");
    const TestCall=await testCall.deploy();
    const TestCallAddress=TestCall.target;
    console.log("TestCall Address:", TestCallAddress);

    const approveMax=ethers.parseEther("10000000000");
    const allowanceMin=ethers.parseEther("100");
    async function Approve(token){
        try{
          const ERC20Contract=new ethers.Contract(token, ERC20ABI.abi, owner);
          const allowance=await ERC20Contract.allowance(owner.address, VizingSwapAddress);
          if(allowance <= allowanceMin){
            const approve=await ERC20Contract.approve(VizingSwapAddress, approveMax);
            await approve.wait();
            console.log("Approve success");
          }else{
            console.log("Not approve");
          }
        }catch(e){
          console.log("Approve fail:",e);
        }
    }

    await Approve(USDCAddress);
    await Approve(USDTAddress);
    await Approve(WETHAddress);
    await Approve(FlyDogeAddress);


}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});