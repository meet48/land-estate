const {expect} = require("chai");

const {loadFixture} = require("@nomicfoundation/hardhat-network-helpers");


describe("Land contract", function () {

    async function deployLandFixture() {

        const LibInt = await ethers.getContractFactory("LibInt");
        let libint = await LibInt.deploy();
        await libint.deployed();

        const LibString = await ethers.getContractFactory("LibString");
        let libstring = await LibString.deploy();
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
        let estate = await Estate.deploy();
        await estate.deployed();

        const [owner, addr1, addr2] = await ethers.getSigners();
        return {land, estate, owner, addr1, addr2};
    }

    describe('land relevant', function () {

        it('should set the right contract owner', async function () {
            const {land, owner} = await loadFixture(deployLandFixture);

            expect(await land.owner()).to.equal(owner.address);
        });

        it('transferOwnership', async function () {
            const {land, addr1} = await loadFixture(deployLandFixture);

            let newOwner = addr1.address;

            await land.transferOwnership(newOwner);

            expect(await land.owner()).to.equal(newOwner);
        });

        it('mint ', async function () {
            const {land, owner} = await loadFixture(deployLandFixture);

            let ownerAddress = owner.address;

            await land.mint(ownerAddress, 10, 10);

            const tokenId = await land.encodeTokenId(10, 10);
            const tokenOwner = await land.ownerOf(tokenId);

            expect(tokenOwner).to.equal(ownerAdderss);
        });

        it('mintMany ', async function () {
            const {land, owner} = await loadFixture(deployLandFixture);

            let x = [1, 2, 3, 4, 5, 6];
            let y = [1, 2, 3, 4, 5, 6];
            let ownerAddress = owner.address;

            await land.mintMany(ownerAddress, x, y);

            for (let i = 0; i < x.length; i++) {

                const tokenId = await land.encodeTokenId(x[i], y[i]);
                const tokenOwner = await land.ownerOf(tokenId);

                expect(tokenOwner).to.equal(ownerAdderss);
            }
        });

        it('setUpdateManager ', async function () {
            const {land, owner, addr1} = await loadFixture(deployLandFixture);

            let approved = true;
            let ownerAddress = owner.address;
            let operator = addr1.address;

            await land.setUpdateManager(ownerAddress, operator, approved);

            expect(await land.updateManager(ownerAddress, operator)).to.be.true;
        });

        it('setUpdateOperator ', async function () {
            const {land, owner, addr1} = await loadFixture(deployLandFixture);

            let ownerAddress = owner.address;
            let operator = addr1.address;

            await land.mint(ownerAddress, 10, 10);

            const tokenId = await land.encodeTokenId(10, 10);

            await land.setUpdateOperator(tokenId, operator);

            let operatorAddress = await land.updateOperator(tokenId);

            expect(operatorAddress).to.equal(operator)
        });

        it('isUpdateAuthorized ', async function () {
            const {land, owner, addr1} = await loadFixture(deployLandFixture);

            let ownerAddress = owner.address;
            let operator = addr1.address;


            await land.mint(ownerAddress, 10, 10);

            const tokenId = await land.encodeTokenId(10, 10);

            await land.setUpdateOperator(tokenId, operator);

            expect(await land.isUpdateAuthorized(operator, tokenId)).to.be.true;
        });

        it('exists ', async function () {
            const {land, owner} = await loadFixture(deployLandFixture);

            let ownerAddress = owner.address;

            await land.mint(ownerAddress, 10, 10);

            expect(await land.exists(10, 10)).to.be.true;
        });

        it('ownerOfLand ', async function () {
            const {land, owner} = await loadFixture(deployLandFixture);

            let ownerAddress = owner.address;

            await land.mint(ownerAddress, 10, 10);

            expect(await land.ownerOfLand(10, 10)).to.equal(ownerAddress);
        });

        it('landData ', async function () {
            const {land, owner} = await loadFixture(deployLandFixture);

            let ownerAddress = owner.address;

            await land.mint(ownerAddress, 10, 10);

            expect(await land.landData(10, 10)).to.be.empty;
        });

        it('landOf ', async function () {
            const {land, owner} = await loadFixture(deployLandFixture);
            let x = [1, 2, 3, 4, 5, 6];
            let y = [1, 2, 3, 4, 5, 6];
            let ownerAddress = owner.address;

            await land.mintMany(ownerAddress, x, y);

            let a = await land.landOf(ownerAddress);
            let i = a[0];
            let j = a[1];

            expect(i).to.deep.equal(x);
            expect(j).to.deep.equal(y);

        });

        it('tokenOfOwnerByIndex ', async function () {
            const {land, owner} = await loadFixture(deployLandFixture);

            let x = [1, 2, 3, 4, 5, 6];
            let y = [1, 2, 3, 4, 5, 6];
            let ownerAddress = owner.address;

            await land.mintMany(ownerAddress, x, y);

            for (let i = 0; i < x.length; i++) {

                const tokenId = await land.encodeTokenId(x[i], y[i]);
                const tokenOwner = await land.ownerOf(tokenId);

                let tokenByIndex = await land.tokenOfOwnerByIndex(ownerAddress, i);

                const TokenIndexOwner = await land.ownerOf(tokenByIndex);

                expect(tokenOwner).to.equal(TokenIndexOwner);
            }
        });

        it('tokenURI ', async function () {
            const {land, owner} = await loadFixture(deployLandFixture);

            let ownerAddress = owner.address;

            await land.mint(ownerAddress, 10, 10);

            const tokenId = await land.encodeTokenId(10, 10);

            expect(await land.tokenURI(tokenId)).to.equal(tokenId + ".json");
        });

        it('transferFrom ', async function () {
            const {land, owner, addr1} = await loadFixture(deployLandFixture);

            let ownerAddress = owner.address;
            let addr1Address = addr1.address;

            await land.mint(ownerAddress, 10, 10);

            let tokenId = land.encodeTokenId(10, 10);

            await land.transferFrom(ownerAddress, addr1Address, tokenId);

            expect(await land.ownerOf(tokenId)).to.equal(addr1Address);
        });
    });

    describe('Estate in Land contract', function () {

        it('setEstateContract ', async function () {
            const {land, estate} = await loadFixture(deployLandFixture);

            let estateAddress = estate.address;

            await land.setEstateContract(estateAddress);

            expect(await land.Estate()).to.equal(estateAddress);
        });

        it('createEstate ', async function () {
            const {land, estate, owner, addr1} = await loadFixture(deployLandFixture);

            let x = [1, 2, 3, 4, 5, 6];
            let y = [1, 2, 3, 4, 5, 6];
            let landAddress = land.address;
            let estateAddress = estate.address;
            let ownerAddress = owner.address;
            let addr1Address = addr1.address;

            await land.setEstateContract(estateAddress);
            await estate.setLandContract(landAddress);

            await land.mintMany(ownerAddress, x, y);

            await land.createEstate(x, y, addr1Address, "");

            let a = await land.landOf(ownerAddress);
            let i = a[0];

            expect(i).to.be.empty;
        });

        it('transferLandToEstate ', async function () {
            const {land, estate, owner} = await loadFixture(deployLandFixture);

            let x = [1, 2, 3, 4, 5, 6];
            let y = [1, 2, 3, 4, 5, 6];
            let landAddress = land.address;
            let estateAddress = estate.address;
            let ownerAddress = owner.address;

            await land.setEstateContract(estateAddress);
            await estate.setLandContract(landAddress);

            await land.mintMany(ownerAddress, x, y);

            await land.createEstate(x, y, ownerAddress, "");

            await land.mint(ownerAddress, 10, 10)

            let i = await estate.estateOf(ownerAddress);

            await land.transferLandToEstate(10, 10, i[0]);

            expect(await land.ownerOfLand(10, 10)).to.be.equal(estateAddress);
        });
    });
});