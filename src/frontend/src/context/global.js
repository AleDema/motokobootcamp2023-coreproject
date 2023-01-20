import { proxy } from 'valtio'

const state = proxy({ 
    count: 0, 
    text: 'hello' 
})

export default state;