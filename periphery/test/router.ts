import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { ethers } from 'hardhat'
import { expect } from 'chai'
import { Factory, Pair, TzCoin } from '../typechain-types'

const { parseEther, formatEther } = ethers.utils

async function deployPair(factory: Factory, token0: TzCoin, token1: TzCoin): Promise<Pair> {
    const tx = await factory.createPair(token0.address, token1.address)
    const txReciept = await tx.wait()
    const pairAddress = txReciept.events && txReciept.events[0].args?.pair
    return await ethers.getContractAt('Pair', pairAddress)
}



describe('Test Router', async () => {
    async function initFixture() {
        const [deployer, user] = await ethers.getSigners()
        const tokenFactory = await ethers.getContractFactory('TzCoin')
        const token0 = await tokenFactory.deploy('Tz1', 'Tz1', parseEther('1000'))
        const token1 = await tokenFactory.deploy('Tz2', 'Tz2', parseEther('2000'))
        const token2 = await tokenFactory.deploy('Tz3', 'Tz3', parseEther('3000'))
        const factory = await (await ethers.getContractFactory('Factory')).deploy(deployer.address)
        const router = await (await ethers.getContractFactory('Router')).deploy(factory.address)

        await token0.deployed()
        await token1.deployed()
        await token2.deployed()
        await factory.deployed()
        await router.deployed()

        const pair0_1 = await deployPair(factory, token0, token1)
        const pair1_2 = await deployPair(factory, token1, token2)

        return { router, token0, token1, token2, pair0_1, pair1_2, deployer, user }
    }

    async function addLiquidityFixture() {
        const { router, token0, token1, token2, pair0_1, pair1_2, deployer, user } = await loadFixture(initFixture)
        await token0.approve(router.address, parseEther('1000'))
        await token1.approve(router.address, parseEther('2000'))
        await token0.transfer(user.address, parseEther('500'))
        await token1.transfer(user.address, parseEther('1000'))
        await token0.connect(user).approve(router.address, parseEther('1000'))
        await token1.connect(user).approve(router.address, parseEther('2000'))
        await router.addLiquidity(
            token0.address,
            token1.address,
            parseEther('500'),
            parseEther('1000'),
            0,
            0,
            deployer.address
        )
        await router.connect(user).addLiquidity(
            token0.address,
            token1.address,
            parseEther('500'),
            parseEther('1000'),
            parseEther('495'),
            parseEther('990'),
            user.address
        )

        const liquidity_deployer = await pair0_1.balanceOf(deployer.address)
        const liquidity_user = await pair0_1.balanceOf(user.address)
        return {
            liquidity_deployer,
            liquidity_user
        }
    }
    it('test addLiquidity', async () => {
        const { liquidity_deployer, liquidity_user } = await loadFixture(addLiquidityFixture)

        expect(liquidity_deployer).to.be.above(parseEther('707'))
        expect(liquidity_user).to.be.above(parseEther('707'))
    })

    it('test removeLiquidity', async () => {
        const { router, token0, token1, token2, pair0_1, pair1_2, deployer, user } = await loadFixture(initFixture)
        const { liquidity_deployer, liquidity_user } = await loadFixture(addLiquidityFixture)
        expect(await token0.balanceOf(user.address)).to.equal(0)
        expect(await token1.balanceOf(user.address)).to.equal(0)
        await pair0_1.connect(user).approve(router.address, parseEther('707'))
        await router.connect(user).removeLiquidity(
            token0.address,
            token1.address,
            parseEther('707'),
            parseEther('495'),
            parseEther('990'),
            user.address
        )
        expect(await token0.balanceOf(user.address)).to.be.above(parseEther('495'))
        expect(await token1.balanceOf(user.address)).to.be.above(parseEther('990'))
    })

    it('test swap', async () => {
        
    })
})

