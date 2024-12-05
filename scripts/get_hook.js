const hre = require("hardhat");

async function main() {
    const [owner] = await hre.ethers.getSigners();
    console.log("owner:", owner.address);

    const hookSelecter = await ethers.getContractFactory("HookSelecter");
    const HookSelecter = await hookSelecter.deploy();
    console.log("HookSelecter:", HookSelecter.target);

    const a=await HookSelecter.getV2SwapSelector();
    console.log("a:",a);
    const b=await HookSelecter.getV3SwapSelector();
    console.log("b:",b);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});