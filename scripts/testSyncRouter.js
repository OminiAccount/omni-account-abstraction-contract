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

    const USDCAddress="0x2f4555dD23ff52a01e26ab94FE84695a6df7885c";
    const USDTAddress="0x534D0e7eC92524338735952863c874f9Cc810492";
    const FlyDogeAddress="0xDa5Dd0d968e439307A606417c96804440132514E";
    const EntryPointAddress="0xDB4e8D5eBCfd23298ad68eC0a6247D0D2Ef20115";
    const ZKVizingAccountFactoryAddress="0xBC401f905E78842e29a08b2d5886E3849E0ce3F9";
    const WETHAddress="0xD8EeaAD5e98c31a73c0253561b70c7a074C85Cd6";
    const SyncRouterAddress="0x3A5B354976e950c093ab350e343DeD8d9Ed9C6f0";
    const SenderCreatorAddress="0x72A3b74a7b8410ae2fdF66B42EFB1c070CBBBB12";

    let EntryPoint=new ethers.Contract(EntryPointAddress, EntryPointABI.abi, testUser);
    let ZKVizingAccountFactory=new ethers.Contract(ZKVizingAccountFactoryAddress, ZKVizingAccountFactoryABI.abi, testUser);
    let SyncRouter=new ethers.Contract(SyncRouterAddress, SyncRouterABI.abi, testUser);
    let WETH=new ethers.Contract(WETHAddress, WETHABI.abi, testUser);

    async function InitERC20Contract(tokenAddress, thisOwner){
        try{
            let ERC20Contract=new ethers.Contract(tokenAddress, ERC20ABI.abi, thisOwner);
            return ERC20Contract;
        }catch(e){
            console.log("Init ERC20 contract error:",e);
        }
    }

    const USDC=await InitERC20Contract(USDCAddress, testUser);
    const USDT=await InitERC20Contract(USDTAddress, testUser);
    const FlyDoge=await InitERC20Contract(FlyDogeAddress, testUser);

    //mint test token
    async function Mint(erc20Contract, receiver, amount){
        try{
            const tx=await erc20Contract.mint(receiver, amount);
            await tx.wait();
            console.log("Mint success");
        }catch(e){
            console.log("Mint error:",e);
        }
    }
    {
        const mintAmount=ethers.parseEther("10000000");
        await Mint(USDC, testUser.address, mintAmount);
        await Mint(USDT, testUser.address, mintAmount);
        await Mint(FlyDoge, testUser.address, mintAmount);
    }

    //approve
    async function Approve(erc20Contract, spender, amount){
        try{
            const tx=await erc20Contract.approve(spender, amount);
            await tx.wait();
            console.log("Approve success");
        }catch(e){
            console.log("Approve error:",e);
        }
    }

    {
        const approveAmount=ethers.parseEther("10000000");
        await Approve(USDC, testUser.address, approveAmount);
        await Approve(USDT, testUser.address, approveAmount);
        await Approve(FlyDoge, testUser.address, approveAmount);
    }

    //create account

    async function CreateAccount(userAddress, salt){
        try{
            const tx=await ZKVizingAccountFactory.createAccount(userAddress, salt);
            await tx.wait();
            console.log("createAccount success");
        }catch(e){
            console.log("createAccount fail:",e);
        }
    }
    
    let zkaaAccount=await ZKVizingAccountFactory.getAccountAddress(testUser.address, 2);
    console.log("zkaaAccount:",zkaaAccount);
    await CreateAccount(testUser.address, 2);
    

    //deposite gas
    let ZKAAContract=new ethers.Contract(zkaaAccount, ZKVizingAccountFactoryABI.abi, testUser);
    

    //test syncRouter

    const CrossETHParams = {
        amount: 10000000n,
        reciever: testUser.address
    };
    const types = ["uint256", "address"];
    const values = [CrossETHParams.amount, CrossETHParams.reciever];
    // Encode the structure into bytes
    const encodedCrossETHParams = ethers.defaultAbiCoder.encode(types, values);
    console.log("Encoded CrossETHParams:", encodedCrossETHParams);

    const PackedUserOperation = ({
        operationType: 1, // 0 user; 1 deposit,2 withdraw system
        operationValue: 100000n,
        sender: testUser.address,
        nonce: 0,
        chainId: 421614n, 
        callData: "0x",
        mainChainGasLimit: 500000n,
        destChainGasLimit: 500000n,
        zkVerificationGasLimit: 500000n,
        mainChainGasPrice: 1000000000n,
        destChainGasPrice:10000000000n,
        owner: testUser.address
    });

    const CrossHookMessageParams=({
        way: 0,
        gasLimit: 500000n,
        gasPrice: 1_000_000_000n,
        destChainId: 421614n,  //arb
        minArrivalTime: 0n,
        maxArrivalTime: 0n,
        destContract:  "0x3A5B354976e950c093ab350e343DeD8d9Ed9C6f0",
        selectedRelayer: ADDRESS_ZERO,
        destChainExecuteUsedFee: 100000000n,
        batchsMessage: "0x",
        packCrossMessage: "0x",
        packCrossParams: encodedCrossETHParams
    });
    const CrossMessageParams={
        PackedUserOperation,
        CrossHookMessageParams
    };
    let ethValue=CrossETHParams.amount + gasLimit * gasPrice + destChainExecuteUsedFee;
    console.log("ethValue:",ethValue);
    const sendOmniMessage=await SyncRouter.sendOmniMessage(CrossMessageParams, {value:ethValue});
    const sendOmniMessageTx=await sendOmniMessage.wait();
    console.log("sendOmniMessageTx:",sendOmniMessageTx);

    

    


}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});