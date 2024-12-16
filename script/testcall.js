const hre = require("hardhat");
const fs = require("fs");

const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const WETHABI = require("../artifacts/contracts/WETH.sol/WETH9.json");
const EntryPointABI = require("../artifacts/contracts/core/EntryPoint.sol/EntryPoint.json");
const ZKVizingAccountFactoryABI = require("../artifacts/contracts/ZKVizingAccountFactory.sol/ZKVizingAccountFactory.json");
const SyncRouterABI = require("../artifacts/contracts/core/SyncRouter.sol/SyncRouter.json");
const VizingSwapABI=require("../artifacts/contracts/hook/VizingSwap.sol/VizingSwap.json");
const TestCallABI=require("../artifacts/contracts/hook/TestCall.sol/TestCall.json");

const setup = require("../setup/setup.json");
const { Network } = require("inspector");

async function main() {
    const [testUser] = await hre.ethers.getSigners();
    console.log("testUser:",testUser.address);
    const provider = ethers.provider;
    const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";
    const USDCAddress="0x2f4555dD23ff52a01e26ab94FE84695a6df7885c";
    const USDTAddress="0x534D0e7eC92524338735952863c874f9Cc810492";
    const FlyDogeAddress="0xDa5Dd0d968e439307A606417c96804440132514E";
    const WETHAddress="0x847ea91D70532C03dAdCdB59df860E3550191187";

    const baseRouter="0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4";
    const baseVizingPad="0x0B5a8E5494DDE7039781af500A49E7971AE07a6b";

    const testUserETHBalance = await provider.getBalance(testUser.address);
    console.log("testUserETHBalance:", testUserETHBalance);

    const network = await provider.getNetwork();
    const currentChainId = network.chainId; 
    console.log("currentChainId:", currentChainId); 

    // const VizingSwapAddress="0x61E50EE12D32b5efc22051502c19DA1FD38F613F";
    // const VizingSwap=new ethers.Contract(VizingSwapAddress, VizingSwapABI.abi, testUser);
    // const TestCallAddress="0x4f6fE7dE849E10e96db33428F87a6060B574d383";
    // const TestCall=new ethers.Contract(TestCallAddress, TestCallABI.abi, testUser);


    const testCall=await hre.ethers.getContractFactory("TestCall");
    const TestCall=await testCall.deploy();
    const TestCallAddress=TestCall.target;
    console.log("TestCall Address:", TestCallAddress);

    const vizingSwap=await hre.ethers.getContractFactory("VizingSwap");
    const VizingSwap=await vizingSwap.deploy(baseRouter, WETHAddress);
    const VizingSwapAddress=VizingSwap.target;
    console.log("VizingSwap Address:", VizingSwapAddress);

    
    const WETH=new ethers.Contract(WETHAddress, WETHABI.abi, testUser);

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
  // {
  //     const mintAmount=ethers.parseEther("10000000");
  //     await Mint(USDC, testUser.address, mintAmount);
  //     await Mint(USDT, testUser.address, mintAmount);
  //     await Mint(FlyDoge, testUser.address, mintAmount);
  // }

    const approveMax=ethers.parseEther("10000000000");
    const allowanceMin=ethers.parseEther("100");
    async function Approve(token, spender){
        try{
          const ERC20Contract=new ethers.Contract(token, ERC20ABI.abi, testUser);
          const allowance=await ERC20Contract.allowance(testUser.address, spender);
          if(allowance <= allowanceMin){
            const approve=await ERC20Contract.approve(spender, approveMax);
            await approve.wait();
            console.log("Approve success");
          }else{
            console.log("Not approve");
          }
        }catch(e){
          console.log("Approve fail:",e);
        }
    }

    await Approve(USDCAddress, VizingSwapAddress);
    await Approve(USDTAddress, VizingSwapAddress);
    await Approve(WETHAddress, VizingSwapAddress);
    await Approve(FlyDogeAddress, VizingSwapAddress);

    await Approve(USDCAddress, TestCallAddress);
    await Approve(USDTAddress, TestCallAddress);
    await Approve(WETHAddress, TestCallAddress);
    await Approve(FlyDogeAddress, TestCallAddress);

    async function CallSwap1(tokenIn, tokenOut, amount){
      try{
        const V3SwapParams={
          index: 0,
          fee: 10000,
          sqrtPriceLimitX96: 0,
          tokenIn: tokenIn,
          tokenOut: tokenOut,
          recipient: testUser.address,
          amountIn: amount,
          amountOutMinimum:0
        }
        let ethValue=0;
        if(tokenIn === ADDRESS_ZERO){
          ethValue=V3SwapParams.amountIn;
        }
        const callV3Swap=await TestCall.callV3Swap1(V3SwapParams, VizingSwapAddress,{value: ethValue});
        const callV3SwapTx=await callV3Swap.wait();
        console.log("callV3Swap success 🥳🥳🥳:",callV3SwapTx);
      }catch(e){
        console.log("Call swap error:",e);
      }
    }

    async function CallSwap2(tokenIn, tokenOut, amount){
      try{
        const V3SwapParams={
          index: 0,
          fee: 10000,
          sqrtPriceLimitX96: 0,
          tokenIn: tokenIn,
          tokenOut: tokenOut,
          recipient: testUser.address,
          amountIn: amount,
          amountOutMinimum:0
        }
        let ethValue=0;
        if(tokenIn === ADDRESS_ZERO){
          ethValue=V3SwapParams.amountIn;
        }
        const callV3Swap=await TestCall.callV3Swap2(V3SwapParams, VizingSwapAddress,{value: ethValue});
        const callV3SwapTx=await callV3Swap.wait();
        console.log("callV3Swap success 🥳🥳🥳:",callV3SwapTx);
      }catch(e){
        console.log("Call swap error:",e);
      }
    }

    async function CallSwap3(tokenIn, tokenOut, amount){
      try{
        const V3SwapParams={
          index: 0,
          fee: 10000,
          sqrtPriceLimitX96: 0,
          tokenIn: tokenIn,
          tokenOut: tokenOut,
          recipient: testUser.address,
          amountIn: amount,
          amountOutMinimum:0
        }
        let ethValue=0;
        if(tokenIn === ADDRESS_ZERO){
          ethValue=V3SwapParams.amountIn;
        }
        const callV3Swap=await TestCall.callV3Swap3(V3SwapParams, VizingSwapAddress, {value: ethValue});
        const callV3SwapTx=await callV3Swap.wait();
        console.log("callV3Swap3 success 🥳🥳🥳:",callV3SwapTx);
      }catch(e){
        console.log("Call swap error:",e);
      }
    }

    async function VizingSwapCall(tokenIn, tokenOut, amount){
      try{
        const V3SwapParams={
          index: 0,
          fee: 10000,
          sqrtPriceLimitX96: 0n,
          tokenIn: tokenIn,
          tokenOut: tokenOut,
          recipient: testUser.address,
          amountIn: amount,
          amountOutMinimum:0n
        }
        let ethValue=0;
        if(tokenIn === ADDRESS_ZERO){
          ethValue=V3SwapParams.amountIn;
        }
        const callV3Swap=await VizingSwap.callV3Swap(V3SwapParams,{value: ethValue});
        const callV3SwapTx=await callV3Swap.wait();
        console.log("VzingSwapCall success 🥳🥳🥳:",callV3SwapTx);
      }catch(e){
        console.log("VzingSwapCall error:",e);
      }
    }

    { 
      // await CallSwap1(ADDRESS_ZERO, USDCAddress, ethers.parseEther("0.000001"));
      // await CallSwap2(ADDRESS_ZERO, USDCAddress, ethers.parseEther("0.000001"));
      // await CallSwap3(ADDRESS_ZERO, USDCAddress, ethers.parseEther("0.000001"));
      // await CallSwap1(USDCAddress, ADDRESS_ZERO, 100n*10n**6n);
      // await CallSwap2(USDCAddress, ADDRESS_ZERO, 100n*10n**6n);
      await CallSwap3(USDCAddress, ADDRESS_ZERO, 100n*10n**6n);
    }

    {
      // await VizingSwapCall(ADDRESS_ZERO, USDCAddress, ethers.parseEther("0.000000001"));

      // await VizingSwapCall(USDCAddress, ADDRESS_ZERO, 100n*10n**6n);
    }


}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});