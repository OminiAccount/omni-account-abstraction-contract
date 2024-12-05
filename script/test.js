

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
    let WETHAddress=ADDRESS_ZERO;
    let SyncRouterAddress=ADDRESS_ZERO;
    let SenderCreatorAddress=ADDRESS_ZERO;
    let VerifyManagerAddress=ADDRESS_ZERO;
    let ZKVizingAAEncodeAddress=ADDRESS_ZERO;

    //Already deploy
    // let EntryPointAddress="0x5FbDB2315678afecb367f032d93F642f64180aa3";
    // let ZKVizingAccountFactoryAddress="0x7348254D7E4a460742778D5B45C30F0049739a3A";
    // let WETHAddress="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
    // let SyncRouterAddress="0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";

    // let EntryPoint=new ethers.Contract(EntryPointAddress, EntryPointABI.abi, owner);
    // let ZKVizingAccountFactory=new ethers.Contract(ZKVizingAccountFactoryAddress, ZKVizingAccountFactoryABI.abi, owner);
    // let SyncRouter=new ethers.Contract(SyncRouterAddress, SyncRouterABI.abi, owner);
    // let WETH=new ethers.Contract(WETHAddress, WETHABI.abi, owner);


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


    async function CreateAccount(userAddress) {
        try {
            const userInfo = await ZKVizingAccountFactory.getUserAccountInfo(userAddress);
            const state = await userInfo.state;
            if (state != 0x01) {
                const createAccount = await ZKVizingAccountFactory.createAccount(userAddress);
                await createAccount.wait();
                console.log("Create Account success");
                const afterUserInfo = await ZKVizingAccountFactory.getUserAccountInfo(userAddress);
                const zkVizingAccount = await afterUserInfo.zkVizingAccount;
                console.log("zkVizingAccount:", zkVizingAccount);
                return zkVizingAccount;
            } else {
                const zkVizingAccount = await userInfo.zkVizingAccount;
                console.log("zkVizingAccount:", zkVizingAccount);
            }
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
                await DeployWETH();
                await DeploySyncRouter(setup["VizingPad-TestNet"][i].Address, WETH);
                await DeploySenderCreator();
                // await DeployVerifyManager();
                await DeployZKVizingAAEncode();

                //create zkaa account
                let createdZKAccount=ADDRESS_ZERO;
                createdZKAccount=await CreateAccount(testUser.address);
                
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