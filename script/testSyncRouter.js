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
    console.log("testUser:", testUser.address);
    const provider = ethers.provider;
    const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";
    const vizingPad = "0x0B5a8E5494DDE7039781af500A49E7971AE07a6b";

    const USDCAddress = "0x2f4555dD23ff52a01e26ab94FE84695a6df7885c";
    const USDTAddress = "0x534D0e7eC92524338735952863c874f9Cc810492";
    const FlyDogeAddress = "0xDa5Dd0d968e439307A606417c96804440132514E";
    const EntryPointAddress = "0xcE22fd390a19a6a526D953dBF7969F0b21675D78";
    const ZKVizingAccountFactoryAddress = "0x0e0b188a6df921829DF267c039a251b4a1ca4A46";
    const WETHAddress = "0x847ea91D70532C03dAdCdB59df860E3550191187";
    const SyncRouterAddress = "0xd985E5B96608C217378d075870cD1F814b834ebb";

    let EntryPoint = new ethers.Contract(EntryPointAddress, EntryPointABI.abi, testUser);
    let ZKVizingAccountFactory = new ethers.Contract(ZKVizingAccountFactoryAddress, ZKVizingAccountFactoryABI.abi, testUser);
    let SyncRouter = new ethers.Contract(SyncRouterAddress, SyncRouterABI.abi, testUser);
    let WETH = new ethers.Contract(WETHAddress, WETHABI.abi, testUser);

    async function InitERC20Contract(tokenAddress, thisOwner) {
        try {
            let ERC20Contract = new ethers.Contract(tokenAddress, ERC20ABI.abi, thisOwner);
            return ERC20Contract;
        } catch (e) {
            console.log("Init ERC20 contract error:", e);
        }
    }

    const USDC = await InitERC20Contract(USDCAddress, testUser);
    const USDT = await InitERC20Contract(USDTAddress, testUser);
    const FlyDoge = await InitERC20Contract(FlyDogeAddress, testUser);

    //mint test token
    async function Mint(erc20Contract, receiver, amount) {
        try {
            const tx = await erc20Contract.mint(receiver, amount);
            await tx.wait();
            console.log("Mint success");
        } catch (e) {
            console.log("Mint error:", e);
        }
    }
    {
        // const mintAmount=ethers.parseEther("10000000");
        // await Mint(USDC, testUser.address, mintAmount);
        // await Mint(USDT, testUser.address, mintAmount);
        // await Mint(FlyDoge, testUser.address, mintAmount);
    }

    //approve
    const minApprove = ethers.parseEther("100000000");
    async function Approve(erc20Contract, owner, spender, amount) {
        try {
            const allowance = await erc20Contract.allowance(owner, spender);
            if (allowance < minApprove) {
                const tx = await erc20Contract.approve(spender, amount);
                await tx.wait();
                console.log("Approve success");
            } else {
                console.log("Not approve");
            }
        } catch (e) {
            console.log("Approve error:", e);
        }
    }

    {
        const approveAmount = ethers.parseEther("10000000000000");
        await Approve(USDC, testUser.address, SyncRouterAddress, approveAmount);
        await Approve(USDT, testUser.address, SyncRouterAddress, approveAmount);
        await Approve(FlyDoge, testUser.address, SyncRouterAddress, approveAmount);
    }

    //create account
    async function CreateAccount(userAddress) {
        try {
            let userId = await ZKVizingAccountFactory.UserId();
            console.log("userId:", userId);
            let zkaaAccount = await ZKVizingAccountFactory.getAccountAddress(testUser.address, userId);
            console.log("zkaaAccount:", zkaaAccount);
            const tx = await ZKVizingAccountFactory.createAccount(userAddress);
            await tx.wait();
            console.log("createAccount success");
        } catch (e) {
            console.log("createAccount fail:", e);
        }
    }
    await CreateAccount(testUser.address);


    //deposite gas
    // let ZKAAContract=new ethers.Contract(zkaaAccount, ZKVizingAccountFactoryABI.abi, testUser);


    //test syncRouter

    const CrossETHParams = {
        amount: 10000000n,
        reciever: testUser.address
    };
    const types = ["uint256", "address"];
    const values = [CrossETHParams.amount, CrossETHParams.reciever];
    // Encode the structure into bytes
    const encodedCrossETHParams = ethers.AbiCoder.defaultAbiCoder().encode(types, values);
    // let getEncodeSignData = await ethers.keccak256(encodedCrossETHParams);
    console.log("getEncodeSignData hash:", encodedCrossETHParams);

    const PackedUserOperation = ({
        operationType: 0, // 0 user; 1 deposit,2 withdraw system
        operationValue: 100000n,
        sender: testUser.address,
        nonce: 0,
        chainId: 421614n,
        callData: "0x",
        mainChainGasLimit: 500000n,
        destChainGasLimit: 500000n,
        zkVerificationGasLimit: 500000n,
        mainChainGasPrice: 1000000000n,
        destChainGasPrice: 10000000000n,
        owner: testUser.address
    });

    const CrossHookMessageParams = ({
        way: 0,
        gasLimit: 350000n,
        gasPrice: 1_350_000_00n,
        destChainId: 421614n,  //arb
        minArrivalTime: 350n,
        maxArrivalTime: 1000000000000n,
        destContract: "0xA2B76dA0593fdEF8F8418F4c8B2D2F3cc5dB6376",
        selectedRelayer: ADDRESS_ZERO,
        destChainExecuteUsedFee: 100000000n,
        batchsMessage: "0x",
        packCrossMessage: "0x",
        packCrossParams: encodedCrossETHParams
    });
    const CrossMessageParams = {
        _packedUserOperation: PackedUserOperation,
        _hookMessageParams: CrossHookMessageParams
    };
    // let fetchUserOmniMessageFee=await SyncRouter.fetchUserOmniMessageFee(CrossMessageParams);
    // console.log("CrossMessageParams:",fetchUserOmniMessageFee);
    // let ethValue=CrossETHParams.amount + fetchUserOmniMessageFee + CrossHookMessageParams.destChainExecuteUsedFee;
    // console.log("ethValue:",ethValue);
    // const sendOmniMessage=await SyncRouter.sendUserOmniMessage(CrossMessageParams, {value:ethers.parseEther("0.003")});
    // const sendOmniMessageTx=await sendOmniMessage.wait();
    // console.log("sendOmniMessageTx:",sendOmniMessageTx);






}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});