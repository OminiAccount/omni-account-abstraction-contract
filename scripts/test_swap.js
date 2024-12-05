const hre = require("hardhat");

const ERC20ABI=require("../artifacts/contracts/TestToken.sol/TestToken.json");
const WETHABI=require("../artifacts/contracts/WETH.sol/WETH9.json");
const VizingSwapABI=require("../artifacts/contracts/uniswap/VizingSwap.sol/VizingSwap.json");

async function main() {
    const [owner] = await hre.ethers.getSigners();
    const provider = ethers.provider;
    console.log("owner:",owner.address);
    const ownerETHBalance=await provider.getBalance(owner.address);
    console.log("ownerETHBalance:",ownerETHBalance);
    if(ownerETHBalance<=ethers.parseEther("0.01")){
      throw("ETH insufficient");
    }
    const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";
    const baseRouter="0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4";

    const WETHAddress="0x847ea91D70532C03dAdCdB59df860E3550191187";
    const WETH=new ethers.Contract(WETHAddress, WETHABI.abi, owner);

    const USDCAddress="0x2f4555dD23ff52a01e26ab94FE84695a6df7885c";
    const USDTAddress="0x534D0e7eC92524338735952863c874f9Cc810492";
    const FlyDogeAddress="0xDa5Dd0d968e439307A606417c96804440132514E";

    const USDC=new ethers.Contract(USDCAddress, ERC20ABI.abi, owner);
    const USDT=new ethers.Contract(USDTAddress, ERC20ABI.abi, owner);
    const FlyDoge=new ethers.Contract(FlyDogeAddress, ERC20ABI.abi, owner);
    const VizingSwapAddress="0xA402a302764E0142a8FaAeB31190d8b406611511";
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
        const v3ExactInputParams={
            index: 0, 
            tokenIn: token0,
            tokenOut: token1,
            recipient: owner.address,
            amountIn: amountIn,
            amountOutMinimum: 0,
            fee: 10000,
            sqrtPriceLimitX96: 0
        };
        let ethSwapAmount=0;
        if(token0 == ADDRESS_ZERO){
          ethSwapAmount=amountIn;
        }
        const v3ETHSwapToOther=await VizingSwap.v3ExactInputSingle(v3ExactInputParams,{value: ethSwapAmount});
        const v3ETHSwapToOtherTx=await v3ETHSwapToOther.wait();
        console.log("v3Swap success🥳🥳🥳","\n",v3ETHSwapToOtherTx);
      }catch(e){
        console.log("swap fail:",e);
      }
    }

    // await V3Swap(ADDRESS_ZERO, USDCAddress, 100n*10n**6n);
    // await V3Swap(WETHAddress, USDCAddress, 1n*10n**8n);
    // await V3Swap(ADDRESS_ZERO, FlyDogeAddress, ethers.parseEther("0.005"));

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});