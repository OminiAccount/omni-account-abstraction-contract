const hre = require("hardhat");

const ERC20ABI=require("../artifacts/contracts/TestToken.sol/TestToken.json");
const WETHABI=require("../artifacts/contracts/WETH.sol/WETH9.json");
const VizingSwapABI=require("../artifacts/contracts/hook/VizingSwap.sol/VizingSwap.json");

async function main() {
    const [deployer, testUser, owner] = await hre.ethers.getSigners();
    const provider = ethers.provider;
    console.log("owner:",owner.address);
    const ownerETHBalance=await provider.getBalance(owner.address);
    console.log("ownerETHBalance:",ownerETHBalance);
    if(ownerETHBalance<=ethers.parseEther("0.01")){
      throw("ETH insufficient");
    }
    const network = await provider.getNetwork();
    const currentChainId = network.chainId;
    console.log("Current Chain ID:", currentChainId);

    const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";

    let USDCAddress=ADDRESS_ZERO;
    let USDTAddress=ADDRESS_ZERO;
    let FlyDogeAddress=ADDRESS_ZERO;
    let WETHAddress=ADDRESS_ZERO;
    let VizingSwapAddress=ADDRESS_ZERO;

    let poolFee;

    if(currentChainId===11155111n){
     
    }else if(currentChainId===28516n){
       
    }else if(currentChainId===84532n){
      USDCAddress="0x2f4555dD23ff52a01e26ab94FE84695a6df7885c";
      USDTAddress="0x534D0e7eC92524338735952863c874f9Cc810492";
      FlyDogeAddress="0xDa5Dd0d968e439307A606417c96804440132514E";
      WETHAddress="0x847ea91D70532C03dAdCdB59df860E3550191187";
      VizingSwapAddress="0x56396A6e39a401F1f4191206971547cD4aA45539";
      poolFee=10000;
    }else if(currentChainId===421614n){
      USDCAddress="0x0766668D5cf45B7903737D4Dd278Fb060a4132D7";
      USDTAddress="0x9daF2b336E2c10004910f2F70a174b3dEDba37E0";
      FlyDogeAddress="0x92B8227Df991CE01331918140eA18C97C49Dac00";
      WETHAddress="0xF9D889590E8EEeE356ebceA060Eb92be531f6c50";
      VizingSwapAddress="0x56396A6e39a401F1f4191206971547cD4aA45539";
      poolFee=500;
    }else if(currentChainId===808813n){
       
    }else if(currentChainId===2442n){
      
    }else if(currentChainId===195n){
        
    }else if(currentChainId===11155420n){
      USDCAddress="0x82eF120C7DC8C72F3d455725d89208ed508C8299";
      USDTAddress="0x9B2215050fb6d8D441E042BE09B1958bf10aa956";
      FlyDogeAddress="0xDBe3f5a973289F9Be5409d1D47375E0E49e9A2d4";
      WETHAddress="0xe2640272e2B86F83A236f51ddfC2D9eD7a3F5093";
      VizingSwapAddress="0x56396A6e39a401F1f4191206971547cD4aA45539";
      poolFee=3000;
    }else if(currentChainId===168587773n){
       
    }else if(currentChainId===534351n){
       
    }else if(currentChainId===300n){
        
    }else if(currentChainId===167009n){
        
    }else{
        throw("Not network");
    }

    const USDC=new ethers.Contract(USDCAddress, ERC20ABI.abi, owner);
    const USDT=new ethers.Contract(USDTAddress, ERC20ABI.abi, owner);
    const FlyDoge=new ethers.Contract(FlyDogeAddress, ERC20ABI.abi, owner);
    const WETH=new ethers.Contract(WETHAddress, WETHABI.abi, owner);
    const VizingSwap=new ethers.Contract(VizingSwapAddress, VizingSwapABI.abi, owner);

    // const vizingSwap=await hre.ethers.getContractFactory("VizingSwap");
    // const VizingSwap=await vizingSwap.deploy(baseRouter, WETHAddress);
    // const VizingSwapAddress=VizingSwap.target;
    // console.log("VizingSwap Address:", VizingSwapAddress);

    //Approve
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

    async function V3Swap(token0, token1, amountIn){
      try{
        const V3SwapParams={
            index: 0, 
            fee: poolFee,
            sqrtPriceLimitX96: 0,
            tokenIn: token0,
            tokenOut: token1,
            recipient: owner.address,
            amountIn: amountIn,
            amountOutMinimum: 0
        };
        let ethSwapAmount=0;
        if(token0 == ADDRESS_ZERO){
          ethSwapAmount=amountIn;
        }
        const v3ETHSwapToOther=await VizingSwap.v3Swap(V3SwapParams,{value: ethSwapAmount});
        const v3ETHSwapToOtherTx=await v3ETHSwapToOther.wait();
        console.log("v3Swap success🥳🥳🥳","\n",v3ETHSwapToOtherTx);
      }catch(e){
        console.log("swap fail:",e);
      }
    }

    // await V3Swap(ADDRESS_ZERO, USDCAddress, 100n*10n**6n);
    await V3Swap(USDCAddress, WETHAddress, 1000n*10n**8n);
    await V3Swap(WETHAddress, USDCAddress, 1n*10n**8n);
    // await V3Swap(USDCAddress, FlyDogeAddress, 100n*10n**6n);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});