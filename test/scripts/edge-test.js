const ETHCallOptionToken = artifacts.require('ETHCallOptionToken')
const ETHPutOptionToken = artifacts.require('ETHPutOptionToken')
const DefaultBalanceToken = artifacts.require('DefaultBalanceToken')

const { fromWei } = web3.utils

contract('Option Token', accounts => {
    let call, put, zeroBalance, edgeBalance

    before(async () => {
        edgeBalance = accounts[0]
        zeroBalance = accounts[9]
        call = await ETHCallOptionToken.deployed()
        put = await ETHPutOptionToken.deployed()
    })

    it('returns the edge of a trader with DefaultBalance', async () => {
        const edge = fromWei(await call.edge(edgeBalance))
        expect(edge).to.eq('0.02999963212506995')
    })

    it('returns zero edge for a trader with no balance', async() => {
        const edge = fromWei(await call.edge(zeroBalance))
        expect(edge).to.eq('0')
    })

    it('put | returns the edge of a trader with DefaultBalance', async () => {
        const edge = fromWei(await put.edge(edgeBalance))
        expect(edge).to.eq('0.02999963212506995')
    })

    it('put | returns zero edge for a trader with no balance', async() => {
        const edge = fromWei(await put.edge(zeroBalance))
        expect(edge).to.eq('0')
    })
})