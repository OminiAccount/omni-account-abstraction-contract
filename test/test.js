const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("ZkAA", function () {

  const provider = ethers.provider;
  const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";

  async function DeployEntryPointAndFactory() {
    const [owner, otherAccount] = await ethers.getSigners();
    const entryPoint = await ethers.getContractFactory("EntryPoint");
    const EntryPoint = await entryPoint.deploy();
    const zkVizingAccountFactory = await ethers.getContractFactory("ZKVizingAccountFactory");
    const ZKVizingAccountFactory = await zkVizingAccountFactory.deploy(EntryPoint);
    console.log("ZKVizingAccountFactory:", ZKVizingAccountFactory.target);
    console.log("EntryPoint:", EntryPoint.target);
    return { EntryPoint, ZKVizingAccountFactory };
  }

  async function DeployLibrary() {
    const goldilocksPoseidon = await ethers.getContractFactory("GoldilocksPoseidon");
    const GoldilocksPoseidon = await goldilocksPoseidon.deploy();
    const GoldilocksPoseidonAddress = GoldilocksPoseidon.target;
    console.log("GoldilocksPoseidon:", GoldilocksPoseidonAddress);
    return { GoldilocksPoseidonAddress };
  }

  async function DeploySyncRouter() {
    const [owner, otherAccount] = await ethers.getSigners();
    const base_vizingPad = "0x0B5a8E5494DDE7039781af500A49E7971AE07a6b";
    const base_router = "0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4";
    const weth = await ethers.getContractFactory("WETH9");
    const WETH = await weth.deploy();
    console.log("WETH:", WETH.target);
    const syncRouter = await ethers.getContractFactory("SyncRouter");
    const SyncRouter = await syncRouter.deploy(base_vizingPad, WETH);
    console.log("SyncRouter:", SyncRouter.target);
    return { SyncRouter, WETH};
  }

  async function DeployWETH() {
    const weth = await ethers.getContractFactory("WETH9");
    const WETH = await weth.deploy();
    console.log("WETH:", WETH.target);
    return { WETH };
  }


  let EntryPoint;
  let WETH;
  let SyncRouter;
  let ZKVizingAccountFactory;
  let ZKVizingAAEncode;

  describe("Deploy", function () {
    it("EntryPoint and Factory", async function () {
      ({ EntryPoint, ZKVizingAccountFactory } = await loadFixture(DeployEntryPointAndFactory));
    });

    it("SyncRouter and WETH", async function () {
      ({ SyncRouter, WETH } = await loadFixture(DeploySyncRouter));
    });


  });
  //   it("SyncRouter", async function () {
  //     const [owner, otherAccount] = await ethers.getSigners();

  //     let {WETH} = await loadFixture(DeployWETH);

  //     let {SyncRouter} = await loadFixture(DeploySyncRouter);
  //     const ownerBalance1=await WETH.balanceOf(owner);
  //     const routerBalance1=await WETH.balanceOf(SyncRouter);
  //     console.log("ownerBalance1:",ownerBalance1);
  //     console.log("routerBalance1:",routerBalance1);
  //     const wrapETHAmount=ethers.parseEther("0.1");
  //     const wrapETH=await SyncRouter.wrapETH(WETH.target,wrapETHAmount,{value: wrapETHAmount});
  //     await wrapETH.wait();
  //     const ownerBalance2=await WETH.balanceOf(owner);
  //     const routerBalance2=await WETH.balanceOf(SyncRouter);
  //     console.log("ownerBalance2:",ownerBalance2);
  //     console.log("routerBalance2:",routerBalance2);

  //   });

  //   it("GoldilocksPoseidon", async function () {
  //     let { GoldilocksPoseidonAddress} = await loadFixture(DeployLibrary);
  //   });


});
