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
    const [deployer, testUser, owner] = await hre.ethers.getSigners();
    console.log("owner:", owner.address);
    console.log("testUser:",testUser.address);
    const provider = ethers.provider;
    const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";

    const ownerETHBalance1 = await GetETHBalance(owner.address);
    console.log("ownerETHBalance before:", ownerETHBalance1);
    // SendEther
    {   
        const sendAmount=ethers.parseEther("0.025");
        await SendEther(owner, deployer.address, sendAmount);
    }
    const ownerETHBalance2 = await GetETHBalance(owner.address);
    console.log("ownerETHBalance after:", ownerETHBalance2);

    const testUserETHBalance = await GetETHBalance(testUser.address);
    console.log("testUserETHBalance:", testUserETHBalance);

    if(testUserETHBalance<=ethers.parseEther("0.01")){
        throw("Test user insufficient eth");
    }

    const network = await provider.getNetwork();
    const currentChainId = network.chainId; 
    console.log("currentChainId:", currentChainId); 

    //Not deploy
    let EntryPoint;
    let ZKVizingAccountFactory;
    let SyncRouter;
    let WETH;
    let SenderCreator;
    let VerifyManager;
    let ZKVizingAAEncode;

    let EntryPointAddress=ADDRESS_ZERO;
    let ZKVizingAccountFactoryAddress=ADDRESS_ZERO;
    let WETHAddress="0x878004Db0E5c17BCf94eBAa0b3Fe00a4a53b7482";
    let SyncRouterAddress=ADDRESS_ZERO;
    let SenderCreatorAddress=ADDRESS_ZERO;
    let VerifyManagerAddress=ADDRESS_ZERO;
    let ZKVizingAAEncodeAddress="0xF9Ca62E37F561F2d26F41f4fE27c4FcBF2d6be7B";

    // let EntryPointAddress="0x7b418afBbCf67F62511D01d7d76FaCBDEC38d1Ca";
    // let ZKVizingAccountFactoryAddress="0xFC6c648230C5372596ed05d33170e59755734861";
    // let WETHAddress="0x3C01F3f35cAf11bdb7BBc9b2E050b132b1aF98F3";
    // let SyncRouterAddress="0xe5FEd6669695757AB25E0FfEEe4CE0545EfC5F71";
    // let SenderCreatorAddress="0xB8A0649CB93209a2c22D2D8d14a02B6019349117";
    // let VerifyManagerAddress=ADDRESS_ZERO;
    // let ZKVizingAAEncodeAddress="0xfcE16F53E4483Cc62Ee3440C44E71C43Db4DB2C8";

    //Already deploy
    // let EntryPointAddress="0x5FbDB2315678afecb367f032d93F642f64180aa3";
    // let ZKVizingAccountFactoryAddress="0x7348254D7E4a460742778D5B45C30F0049739a3A";
    // let WETHAddress="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
    // let SyncRouterAddress="0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";

    // let EntryPoint=new ethers.Contract(EntryPointAddress, EntryPointABI.abi, owner);
    // let ZKVizingAccountFactory=new ethers.Contract(ZKVizingAccountFactoryAddress, ZKVizingAccountFactoryABI.abi, owner);
    // let SyncRouter=new ethers.Contract(SyncRouterAddress, SyncRouterABI.abi, owner);
    // let WETH=new ethers.Contract(WETHAddress, WETHABI.abi, owner);

    async function GetETHBalance(account){
        try{
            const accountETHBalance = await provider.getBalance(account);
            console.log("accountETHBalance:", accountETHBalance);
            return accountETHBalance;
        }catch(e){
            console.log("Get eth balance error:",e);
        }
    }

    async function SendEther(senderWallet, recipientAddress, ethAmount) {
        try {
            // Send the transaction
            const transactionResponse = await senderWallet.sendTransaction({
                to: recipientAddress,
                value: ethAmount,
              });
            // Wait for the transaction to be mined
            const receipt = await transactionResponse.wait();
            if(receipt.status===1){
                console.log("Transaction mined:", receipt.hash);
            }else{
                console.log("Receipt fail");
            }
        } catch (error) {
            console.error("Error sending transaction:", error);
        }
    }
    


/*********************************************Deploy********************************************************** */
    async function DeployEntryPoint() {
        const [owner, otherAccount] = await ethers.getSigners();
        const entryPoint = await ethers.getContractFactory("EntryPoint");
        EntryPoint = await entryPoint.deploy();
        EntryPointAddress = EntryPoint.target;
        console.log("EntryPoint:", EntryPointAddress);
        return { EntryPoint };
    }

    async function DeploySyncRouter(vizingPad, weth) {
        const syncRouter = await ethers.getContractFactory("SyncRouter");
        SyncRouter = await syncRouter.deploy(vizingPad, weth);
        SyncRouterAddress = SyncRouter.target;
        console.log("SyncRouter:", SyncRouterAddress);
        return { SyncRouter };
    }

    async function DeployWETH() {
        const weth = await ethers.getContractFactory("WETH9");
        WETH = await weth.deploy();
        WETHAddress = WETH.target;
        console.log("WETH:", WETHAddress);
        return { WETH };
    }

    async function DeployZKVizingAccountFactory(thisEntryPoint) {
        const zkVizingAccountFactory = await ethers.getContractFactory("ZKVizingAccountFactory");
        ZKVizingAccountFactory = await zkVizingAccountFactory.deploy(thisEntryPoint);
        ZKVizingAccountFactoryAddress = ZKVizingAccountFactory.target;
        console.log("ZKVizingAccountFactory:", ZKVizingAccountFactoryAddress);
        return { ZKVizingAccountFactory };
    }

    async function DeploySenderCreator() {
        const senderCreator = await ethers.getContractFactory("SenderCreator");
        SenderCreator = await senderCreator.deploy();
        SenderCreatorAddress = SenderCreator.target;
        console.log("SenderCreator:", SenderCreatorAddress);
        return { SenderCreator };
    }

    //????
    async function DeployVerifyManager() {
        const verifyManager = await ethers.getContractFactory("VerifyManager");
        VerifyManager = await verifyManager.deploy();
        VerifyManagerAddress = VerifyManager.target;
        console.log("VerifyManager:", VerifyManagerAddress);
        return { VerifyManager };
    }

    async function DeployZKVizingAAEncode() {
        const zkVizingAAEncode = await ethers.getContractFactory("ZKVizingAAEncode");
        ZKVizingAAEncode = await zkVizingAAEncode.deploy();
        ZKVizingAAEncodeAddress = ZKVizingAAEncode.target;
        console.log("ZKVizingAAEncode:", ZKVizingAAEncodeAddress);
        return { ZKVizingAAEncode };
    }

    async function CreateAccount(userAddress, saltNum) {
        try {
            const createAccount = await ZKVizingAccountFactory.createAccount(userAddress,saltNum);
            await createAccount.wait();
            console.log("Create Account success");
            const thisZKVizingAccount=await ZKVizingAccountFactory.getAccountAddress(userAddress,saltNum);
            console.log("thisZKVizingAccount:",thisZKVizingAccount);
            return thisZKVizingAccount;
        } catch (e) {
            console.log("Create Account fial:", e);
        }
    }

    async function SaveAddressesToFile(networkName, chainId, userAddress, userZKAccount) {
        let addresses = {};
        try {
            const data = fs.readFileSync("deployedAddresses.json");
            addresses = JSON.parse(data);
        } catch (e) {
            console.log("No existing file found, creating a new one.");
        }

        addresses[networkName] = {
            ChainId: chainId,
            EntryPoint: EntryPointAddress,
            ZKVizingAccountFactory: ZKVizingAccountFactoryAddress,
            WETH: WETHAddress,
            SyncRouter: SyncRouterAddress,
            SenderCreator: SenderCreatorAddress,
            VerifyManager: VerifyManagerAddress,
            ZKVizingAAEncode: ZKVizingAAEncodeAddress,
            CreatedZKVizingAccount:{
                UserAddress: userAddress,
                UserZKAccount: userZKAccount
            },

        };

        fs.writeFileSync("deployedAddresses.json", JSON.stringify(addresses, null, 2)); 
        console.log("Contract address saved to deployedAddresses.json");
    }

    

    // deploy
    {   
        for(let i=0; i<setup["VizingPad-TestNet"].length; i++){
            let currentSetChainId=BigInt(setup["VizingPad-TestNet"][i].ChainId);
            console.log("currentSetChainId:", currentSetChainId);
            if(currentSetChainId === currentChainId){
                await DeployEntryPoint();
                await DeployZKVizingAccountFactory(EntryPointAddress);
                // await DeployWETH();
                await DeploySyncRouter(setup["VizingPad-TestNet"][i].Address, WETH);
                await DeploySenderCreator();
                // await DeployVerifyManager();
                // await DeployZKVizingAAEncode();

                //create zkaa account
                let createdZKAccount=ADDRESS_ZERO;
                const salt=1;
                createdZKAccount=await CreateAccount(testUser.address, salt);
                
                //fs write json
                await SaveAddressesToFile(
                    setup["VizingPad-TestNet"][i].Name, 
                    setup["VizingPad-TestNet"][i].ChainId, 
                    testUser, 
                    createdZKAccount
                );
            }else{
                console.log("Not network");
            }
        }
        
    }    

}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});