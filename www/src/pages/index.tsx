import React, { useState, useRef, useEffect } from "react";
import clsx from "clsx";
import Head from "@docusaurus/Head";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import { Chain, Common, Hardfork } from "@ethereumjs/common";
import { Transaction } from "@ethereumjs/tx";
import { Account, Address } from "@ethereumjs/util";
import { VM } from "@ethereumjs/vm";
import Layout from "@theme/Layout";
import CodeBlock from "@theme/CodeBlock";
import keythereum from "keythereum";

import styles from "./index.module.css";
import { GithubStarsButton } from "../components/GithubStarsButton";

const solc = new Worker(new URL("../solc", import.meta.url));

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx("hero bg-transparent", styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title dark:text-white">{siteConfig.title}</h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>

        <div className={styles.buttons}>
          <GithubStarsButton />
          <Link
            className="button button--primary button--lg"
            to="/docs/quickstart"
          >
            Get Started
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home(): JSX.Element {
  const [path, setPath] = useState("");
  const [routeFunctionName, setRouteFunctionName] = useState("getMyPath");
  const [responseContent, setResponseContent] = useState("Hello world!");
  const [compiling, setCompiling] = useState(false);
  const [deploying, setDeploying] = useState(false);
  const [contractAddress, setContractAddress] = useState("");
  const [response, setResponse] = useState("");
  const compileCounterRef = useRef(0);
  const vmRef = useRef<VM>();

  const common = new Common({
    chain: Chain.Mainnet,
    hardfork: Hardfork.Merge,
  });

  useEffect(() => {
    VM.create({
      common,
    }).then((vm) => (vmRef.current = vm));
  }, []);

  async function compileContract() {
    return new Promise((resolve) => {
      const id = compileCounterRef.current;
      solc.postMessage({
        id,
        path,
        routeFunctionName,
        responseContent,
      });
      compileCounterRef.current += 1;
      solc.onmessage = ({ data }) => {
        if (data.id === id) {
          resolve(data.evm);
        }
      };
    });
  }

  async function handleCompileAndRun() {
    setContractAddress("");
    setResponse("");

    let bytecode;
    try {
      setCompiling(true);
      bytecode = (await compileContract()).bytecode;
    } catch (err) {
      console.log(err);
      return;
    } finally {
      setCompiling(false);
    }

    try {
      setDeploying(true);
      const privateKey = await new Promise((resolve) => {
        keythereum.create({}, (dk) => {
          resolve(dk.privateKey);
        });
      });

      // Add balance to account
      const account = Account.fromAccountData({
        nonce: 0,
        balance: BigInt(10) ** BigInt(18),
      });
      const senderAddress = Address.fromPrivateKey(privateKey);
      vmRef.current.stateManager.putAccount(senderAddress, account);

      const deploymentTx = Transaction.fromTxData(
        {
          nonce: 0,
          gasLimit: 10_000_000,
          gasPrice: 100,
          value: 0,
          data: `0x${bytecode.object}`,
        },
        { common }
      ).sign(privateKey);

      const { createdAddress } = await vmRef.current.runTx({
        tx: deploymentTx,
      });

      setContractAddress(createdAddress.toString());

      const callResult = await vmRef.current.evm.runCall({
        to: createdAddress,
        caller: senderAddress,
        origin: senderAddress,
        data: Buffer.from(`GET /${path} HTTP/1.1`),
      });

      setResponse(callResult.execResult.returnValue.toString("utf-8"));
    } catch (err) {
      console.log(err);
      return;
    } finally {
      setDeploying(false);
    }
  }

  return (
    <Layout
      title={`fallback() Solidity Web Framework`}
      description="Description will go into a meta tag in <head />"
    >
      <Head>
        <script
          type="text/javascript"
          src="https://binaries.soliditylang.org/bin/soljson-v0.8.16+commit.07a7930e.js"
          integrity="sha256-J7KCDvk4BaZcdreUWklDJYLTBv0XoomFcJpR5kA2d8I="
          crossOrigin="anonymous"
        ></script>
      </Head>
      <main className="container px-6 mx-auto pb-20">
        <HomepageHeader />
        <div
          className="text-center py-8"
          style={{ scrollMarginTop: "50px" }}
          id="try-it"
        >
          <h2 className="text-2xl">Try it</h2>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="col-auto">
            <div className="grid gap-4 grid-cols-1 mb-8">
              <div className="col-auto">
                <h3>1. Configure a route handler</h3>
                <label className="block text-gray-700 dark:text-gray-300 text-sm font-bold mb-2">
                  1. Choose a path
                </label>
                <input
                  value={path}
                  onChange={(e) => setPath(e.target.value)}
                  placeholder="path"
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 dark:text-gray-300 leading-tight focus:outline-none focus:shadow-outline"
                />
                <small>The path to write a handler for</small>
              </div>
              <div className="col-auto">
                <label className="block text-gray-700 dark:text-gray-300 text-sm font-bold mb-2">
                  2. Name your route handler
                </label>
                <input
                  value={routeFunctionName}
                  onChange={(e) => setRouteFunctionName(e.target.value)}
                  placeholder="routeFunctionName"
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 dark:text-gray-300 leading-tight focus:outline-none focus:shadow-outline"
                />
                <small>
                  The name of the route handler function in the web app contract
                </small>
              </div>
              <div className="col-auto">
                <label className="block text-gray-700 dark:text-gray-300 text-sm font-bold mb-2">
                  3. Write your response content
                </label>
                <input
                  value={responseContent}
                  onChange={(e) => setResponseContent(e.target.value)}
                  placeholder="responseContent"
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 dark:text-gray-300 leading-tight focus:outline-none focus:shadow-outline"
                />
                <small>The content of the HTTP response</small>
              </div>
            </div>
          </div>
          <div className="col-auto">
            <h3>2. View generated web app contract</h3>

            <CodeBlock language="solidity" title="MyApp.sol" showLineNumbers>
              {`import {HttpConstants} from "https://github.com/nathanhleung/fallback/blob/main/src/http/HttpConstants.sol";
import {HttpMessages} from "https://github.com/nathanhleung/fallback/blob/main/src/http/HttpMessages.sol";
import {WebApp} from "https://github.com/nathanhleung/fallback/blob/main/src/WebApp.sol";

contract MyApp is WebApp {
    constructor() {
        routes[HttpConstants.Method.GET]["/${path}"] = "${routeFunctionName}";
    }

    function ${routeFunctionName}(HttpMessages.Request calldata request)
        external
        pure${routeFunctionName === "getIndex" ? "\n        override" : ""}
        returns (HttpMessages.Response memory)
    {
        HttpMessages.Response memory response;
        response.content = "${responseContent}";
        return response;
    }
}`}
            </CodeBlock>
          </div>
          <div className="col-auto">
            <h3>3. Compile and send request</h3>
            <CodeBlock language="javascript" title="request.js">
              {`
${contractAddress ? `const CONTRACT_ADDRESS = "${contractAddress}";` : ""}

const request = "GET /${path} HTTP/1.1";
const result = await web3.eth.call({
  to: CONTRACT_ADDRESS,
  data: Buffer.from(request).toString("hex");
});
console.log(Buffer.from(result, "hex").toString());
        `.trim()}
            </CodeBlock>
            <button
              className="button button--secondary  button--lg"
              onClick={handleCompileAndRun}
              disabled={compiling || deploying}
            >
              {compiling
                ? "Compiling..."
                : deploying
                ? "Deploying..."
                : "Compile and Run Locally"}
            </button>
            <small className="mt-2 block">
              {compiling ? "Compilation may take a moment, please wait..." : ""}
            </small>
          </div>
          <div className="col-auto">
            <h3>4. Decode contract return value</h3>
            <CodeBlock title="Decoded Contract Return Value">
              {response
                ? response
                : compiling || deploying
                ? "Compiling..."
                : "// Compile and run to see response"}
            </CodeBlock>
            {response && (
              <>
                <p>
                  Now that you've tried it, you can write your own fallback()
                  app too!
                </p>
                <Link
                  className="button button--primary button--lg"
                  to="/docs/quickstart"
                >
                  Go to Quickstart
                </Link>
              </>
            )}
          </div>
        </div>
      </main>
    </Layout>
  );
}
