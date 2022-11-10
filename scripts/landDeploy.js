// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    let libint;
    let libstring;
    let land;

    // LibInt
    const LibInt = await hre.ethers.getContractFactory("LibInt");
    libint = await LibInt.deploy();
    await libint.deployed();

    // LibString
    const LibString = await hre.ethers.getContractFactory("LibString");
    libstring = await LibString.deploy();
    await libstring.deployed();

    // Land
    const Land = await hre.ethers.getContractFactory("Land" , {
        libraries: {
            LibInt: libint.address,
            LibString: libstring.address
        }
    });
    land = await Land.deploy();
    await land.deployed();

    console.log('LibInt contract address: '+ libint.address);
    console.log('LibString contract address: '+ libstring.address);
    console.log('Land contract address: '+ land.address);
    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
