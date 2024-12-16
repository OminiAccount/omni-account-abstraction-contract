const hre = require("hardhat");
const fs = require("fs");

const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const WETHABI = require("../artifacts/contracts/WETH.sol/WETH9.json");
const EntryPointABI = require("../artifacts/contracts/core/EntryPoint.sol/EntryPoint.json");
const ZKVizingAccountFactoryABI = require("../artifacts/contracts/ZKVizingAccountFactory.sol/ZKVizingAccountFactory.json");
const SyncRouterABI = require("../artifacts/contracts/core/SyncRouter.sol/SyncRouter.json");
const ZKVizingAADataHelpABI = require("../artifacts/contracts/core/ZKVizingAADataHelp.sol/ZKVizingAADataHelp.json");
const ZKVizingAccountABI = require("../artifacts/contracts/ZKVizingAccount.sol/ZKVizingAccount.json");

const setup = require("../setup/setup.json");
const { Network } = require("inspector");

async function main() {
    const [deployer, testUser, owner] = await hre.ethers.getSigners();
    console.log("owner:", owner.address);
    console.log("testUser:",testUser.address);
    const provider = ethers.provider;
    const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";
    const vizingPad="0x0B5a8E5494DDE7039781af500A49E7971AE07a6b";

    const USDCAddress="0x2f4555dD23ff52a01e26ab94FE84695a6df7885c";
    const USDTAddress="0x534D0e7eC92524338735952863c874f9Cc810492";
    const FlyDogeAddress="0xDa5Dd0d968e439307A606417c96804440132514E";
    const EntryPointAddress="0x094202a231dCeA8D9eaE3Ea84840EB13dAE7D46A";
    const ZKVizingAccountFactoryAddress="0x211ffEFd85Cf4429d9FEeaba514E336840b4cd73";
    const WETHAddress="0x847ea91D70532C03dAdCdB59df860E3550191187";
    const SyncRouterAddress="0x647D4e3aA7D6068A838444eD161d5Df6341883cE";
    const ZKVizingAADataHelpAddress="0x99C580cf25269B1583D5b54f943066a43616f394";

    let EntryPoint=new ethers.Contract(EntryPointAddress, EntryPointABI.abi, owner);
    let ZKVizingAccountFactory=new ethers.Contract(ZKVizingAccountFactoryAddress, ZKVizingAccountFactoryABI.abi, owner);
    let SyncRouter=new ethers.Contract(SyncRouterAddress, SyncRouterABI.abi, owner);
    const ZKVizingAADataHelp=new ethers.Contract(ZKVizingAADataHelpAddress,ZKVizingAADataHelpABI.abi,owner);
    let WETH=new ethers.Contract(WETHAddress, WETHABI.abi, owner);

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
        // const mintAmount=ethers.parseEther("10000000");
        // await Mint(USDC, testUser.address, mintAmount);
        // await Mint(USDT, testUser.address, mintAmount);
        // await Mint(FlyDoge, testUser.address, mintAmount);
    }

    //approve
    const minApprove=ethers.parseEther("100000000");
    async function Approve(erc20Contract, owner, spender, amount){
        try{
            const allowance=await erc20Contract.allowance(owner, spender);
            if(allowance<minApprove){
                const tx=await erc20Contract.approve(spender, amount);
                await tx.wait();
                console.log("Approve success");
            }else{
                console.log("Not approve");
            }
        }catch(e){
            console.log("Approve error:",e);
        }
    }

    {
        const approveAmount=ethers.parseEther("10000000000000");
        // await Approve(USDC, testUser.address, SyncRouterAddress, approveAmount);
        // await Approve(USDT, testUser.address, SyncRouterAddress, approveAmount);
        // await Approve(FlyDoge, testUser.address, SyncRouterAddress, approveAmount);
    }

    //create account
    async function CreateAccount(userAddress){
        try{
            let userId=await ZKVizingAccountFactory.UserId();
            console.log("userId:",userId);
            let zkaaAccount=await ZKVizingAccountFactory.getAccountAddress(testUser.address, userId);
            console.log("zkaaAccount:",zkaaAccount);
            const tx=await ZKVizingAccountFactory.createAccount(userAddress);
            await tx.wait();
            console.log("createAccount success");
        }catch(e){
            console.log("createAccount fail:",e);
        }
    }
    // await CreateAccount(testUser.address);
    

    //deposite gas
    // let ZKAAContract=new ethers.Contract(zkaaAccount, ZKVizingAccountFactoryABI.abi, testUser);
    

    //test syncRouter

    const CrossETHParams = {
        amount: 100000000n,
        reciever: owner.address
    };
    const types = ["uint256", "address"];
    const values = [CrossETHParams.amount, CrossETHParams.reciever];
    // Encode the structure into bytes
    const encodeCrossETHParams1 = ethers.AbiCoder.defaultAbiCoder().encode(types, values);
    // let getEncodeSignData = await ethers.keccak256(encodedCrossETHParams);
    console.log("encodeCrossETHParams1 hash:", encodeCrossETHParams1);  

    const encodeCrossETHParams2 = await ZKVizingAADataHelp.encodeCrossETHParams(CrossETHParams);
    console.log("encodeCrossETHParams2 hash:", encodeCrossETHParams2);  

    const ExecData = {
        nonce: 0n,
        chainId: 28516n,
        mainChainGasLimit: 100000n,
        destChainGasLimit: 100000n,
        zkVerificationGasLimit: 100000n,
        mainChainGasPrice: 1000000000n,
        destChainGasPrice: 1000000000n,
        callData: '0x'
    }

    const PackedUserOperation = ({
        phase: 0n,
        operationType: 0n, // 0 user; 1 deposit; 2 withdraw;
        operationValue: 100000000n,
        sender: testUser.address,
        owner: testUser.address,
        exec: ExecData,
        innerExec: ExecData
    });

    const CrossHookMessageParams=({
        way: 255,
        gasLimit: 500000n,
        gasPrice: 1_550_000_000n,
        destChainId: 28516n,  //vizing sepolia
        minArrivalTime: 0n,
        maxArrivalTime: 0n,
        destContract:  "0xA2B76dA0593fdEF8F8418F4c8B2D2F3cc5dB6376",
        selectedRelayer: ADDRESS_ZERO,
        destChainExecuteUsedFee: 100000000n,
        batchsMessage: "0x",
        packCrossMessage: "0x",
        packCrossParams: encodeCrossETHParams2
    });
    const CrossMessageParams={
        _packedUserOperation: [PackedUserOperation],
        _hookMessageParams: CrossHookMessageParams
    };

    const fetchUserOmniMessageFee=await SyncRouter.fetchUserOmniMessageFee(CrossMessageParams);
    console.log("fetchUserOmniMessageFee:",fetchUserOmniMessageFee);

    const getUserOmniEncodeMessage=await SyncRouter.getUserOmniEncodeMessage(CrossMessageParams);
    console.log("getUserOmniEncodeMessage:",getUserOmniEncodeMessage);

    let ethAmount=0;
    ethAmount=getUserOmniEncodeMessage[0] + CrossHookMessageParams.destChainExecuteUsedFee + fetchUserOmniMessageFee;
    console.log("ethAmount:",ethAmount);

    //sendUserOmniMessage
    // try{
    //     const sendUserOmniMessage=await SyncRouter.sendUserOmniMessage(
    //         CrossMessageParams,
    //         {value: ethAmount}
    //     );
    //     const sendUserOmniMessageTx=await sendUserOmniMessage.wait();
    //     console.log("sendUserOmniMessage:",sendUserOmniMessageTx);
    // }catch(e){
    //     console.log("sendUserOmniMessage error:",e);
    // }

    const getUserAccountInfo=await ZKVizingAccountFactory.getUserAccountInfo(owner.address);
    console.log("getUserAccountInfo:",getUserAccountInfo);

    if(getUserAccountInfo.zkVizingAccount ===ADDRESS_ZERO){
        const createAccount=await ZKVizingAccountFactory.createAccount(owner.address, 1);
        await createAccount.wait();
        console.log("createAccount:",createAccount);
    }

    const getAccountAddress=await ZKVizingAccountFactory.getAccountAddress(owner.address, 1);
    console.log("getAccountAddress:",getAccountAddress);

    const ZKVizingAccount=new ethers.Contract(getAccountAddress,ZKVizingAccountABI.abi,owner);


       
    const depositGasRemote=await ZKVizingAccount.depositGasRemote(
        1n,
        100000000n,
        100000000n,
        CrossHookMessageParams.gasLimit,
        CrossHookMessageParams.gasPrice,
        0n,
        0n,
        ADDRESS_ZERO,
        {
            value: ethAmount + 100000000n
        }
    );
    const depositGasRemoteTx=await depositGasRemote.wait();
    console.log("depositGasRemoteTx:",depositGasRemoteTx);

}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});