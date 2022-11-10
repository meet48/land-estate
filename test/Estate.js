const {expect} = require("chai");

const {loadFixture} = require("@nomicfoundation/hardhat-network-helpers");


describe("Estate contract", function () {

    async function deployEstateFixture() {

        const LibInt = await ethers.getContractFactory("LibInt");
        const libint = await LibInt.deploy();
        await libint.deployed();

        const LibString = await ethers.getContractFactory("LibString");
        const libstring = await LibString.deploy();
        await libstring.deployed();

        const Land = await ethers.getContractFactory("Land", {
            libraries: {
                LibInt: libint.address,
                LibString: libstring.address
            }
        });
        const land = await Land.deploy();
        await land.deployed();

        const Estate = await ethers.getContractFactory("Estate");
        const estate = await Estate.deploy();
        await estate.deployed();

        const [owner, addr1, addr2] = await ethers.getSigners();

        await land.setEstateContract(estate.address);
        await estate.setLandContract(land.address);

        let x = [1, 2, 3];
        let y = [1, 2, 3];

        await land.mintMany(owner.address, x, y);

        await land.createEstate(x, y, owner.address, "");

        await land.mint(owner.address, 10, 10)

        let landId1 = await land.encodeTokenId(1, 1);
        let landId10 = await land.encodeTokenId(10, 10);
        let estateId = await estate.landIdEstate(landId1);

        return {land, estate, owner, addr1, addr2, landId1, landId10, estateId};
    }

    describe("Estate relevant", function () {

        it('should set the right contract owner', async function () {
            const {estate, owner} = await loadFixture(deployEstateFixture);

            expect(await estate.owner()).to.equal(owner.address);
        });

        it('transferOwnership ', async function () {
            const {estate, addr1} = await loadFixture(deployEstateFixture);

            let newOwner = addr1.address;

            await estate.transferOwnership(newOwner);

            expect(await estate.owner()).to.equal(newOwner);
        });

        it('transferLand ', async function () {
            const {estate, owner, landId1, estateId} = await loadFixture(deployEstateFixture);

            let ownerAddress = owner.address;

            await estate.transferLand(estateId, landId1, ownerAddress);

            expect(await estate.getLandIds(estateId)).to.not.include(landId1);
        });

        it('setUpdateManager ', async function () {
            const {estate, owner, addr1} = await loadFixture(deployEstateFixture);

            let approved = true;
            let ownerAddress = owner.address;
            let operator = addr1.address;

            await estate.setUpdateManager(ownerAddress, operator, approved);

            expect(await estate.updateManager(ownerAddress, operator)).to.be.true;
        });

        it('setUpdateOperator ', async function () {
            const {estate, addr1, estateId} = await loadFixture(deployEstateFixture);

            let operator = addr1.address;

            await estate.setUpdateOperator(estateId, operator);

            let operatorAddress = await estate.updateOperator(estateId);

            expect(operatorAddress).to.equal(operator)
        });

        it('isUpdateAuthorized ', async function () {
            const {estate, addr1, estateId} = await loadFixture(deployEstateFixture);

            let operator = addr1.address;

            await estate.setUpdateOperator(estateId, operator);

            expect(await estate.isUpdateAuthorized(operator, estateId)).to.be.true;
        });

        it('updateMetadata ', async function () {
            const {estate, estateId} = await loadFixture(deployEstateFixture);

            await estate.updateMetadata(estateId, "MEET");

            expect(await estate.estateData(estateId)).to.equal("MEET");
        });

        it('updateLandData ', async function () {
            const {land, estate, landId1, estateId} = await loadFixture(deployEstateFixture);

            await estate.updateLandData(estateId, landId1, "MEET");

            expect(await land.landData(1, 1)).to.equal("MEET");
        });

        it('setLandUpdateOperator ', async function () {
            const {land, estate, addr1, landId1, estateId} = await loadFixture(deployEstateFixture);

            let operatorAddress = addr1.address;

            await estate.setLandUpdateOperator(estateId, landId1, operatorAddress);

            expect(await land.updateOperator(landId1)).to.equal(operatorAddress);
        });
    });
});