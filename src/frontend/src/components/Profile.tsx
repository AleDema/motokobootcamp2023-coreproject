import React from "react"
import { useBalance, useWallet } from "@connect2ic/react"

const Profile = () => {

  const [wallet] = useWallet()
  const [assets] = useBalance()
  // await ledger.icrc1_balance_of();
  return (
    <div className="example">
      {wallet ? (
        <>
          <p>Wallet address: <span style={{ fontSize: "0.7em" }}>{wallet ? wallet.principal : "-"}</span></p>
          <table>
            <tbody>
              {assets && assets.map(asset => (
                <tr key={asset.canisterId}>
                  <td>
                    {asset.name}
                  </td>
                  <td>
                    {asset.amount}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </>
      ) : (
        <p className="example-disabled">Connect with a wallet to access</p>
      )}
    </div>
  )
}

export { Profile }
