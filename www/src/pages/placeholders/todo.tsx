import React from "react";
import Layout from "@theme/Layout";

export default function Todo(): JSX.Element {
  return (
    <Layout
      title={`todo demo app - fallback() Solidity Web Framework`}
      description="Write web apps in Solidity — fallback() is a Solidity web framework / a proof-of-concept implementation of HTTP over Ethereum."
    >
      <main className="container px-6 mx-auto pb-20">
        <div className="text-center pt-16">
          <h1>Unavailable</h1>
          <p>
            Due to rising cloud costs, the todo app at{" "}
            <a href="https://todo.fallback.natecation.xyz">
              todo.fallback.natecation.xyz
            </a>{" "}
            is currently unavailable.
          </p>
          <img className="lg:w-1/2" src="/img/placeholders/todo.png" />
        </div>
        <div className="pt-8">
          <h2>Self-Host</h2>
          <p>
            To run the app yourself, deploy the{" "}
            <a href="https://github.com/nathanhleung/fallback/blob/main/src/example/Dockerfile">
              Dockerfile
            </a>{" "}
            with the following environment variables set:
          </p>
          <div>
            <pre className="text-left">
              {`
ETHEREUM_RPC_URL=https://opt-goerli.g.alchemy.com/v2/[your api key]
FALLBACK_SERVER_CONTRACT_ADDRESS=0x919F31dAC93eBf9fFd15a54acd13082f34fDd6D3
PAYER_PRIVATE_KEY=[private key of account which sends transactions]
SERVER_MODE=send
            `.trim()}
            </pre>
          </div>
          <p>
            You can run the Dockerfile locally, or on a managed container
            runtime such as AWS Fargate if you push the image to the cloud.
          </p>
        </div>
        <div className="pt-8">
          <h2>Links</h2>
          <ul>
            <li>
              Code:{" "}
              <a href="https://github.com/nathanhleung/fallback/blob/main/src/example/Todo.sol">
                Todo.sol
              </a>
            </li>
            <li>
              Live Contract on Optimism Goerli:{" "}
              <a href="https://goerli-optimism.etherscan.io/address/0x919F31dAC93eBf9fFd15a54acd13082f34fDd6D3">
                0x919F31dAC93eBf9fFd15a54acd13082f34fDd6D3
              </a>
            </li>
          </ul>
        </div>
      </main>
    </Layout>
  );
}
