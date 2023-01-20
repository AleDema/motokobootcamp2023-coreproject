import React from 'react'

import { useDialog, useConnect } from "@connect2ic/react"

function AuthButton() {
    const { open, close, isOpen } = useDialog()
    const { isConnected, disconnect } = useConnect();

  return (
    <>
      { isConnected ? <button onClick={disconnect}>Disconnect</button> : <button onClick={open}>Connect</button>}
    </>
  )
}

export default AuthButton