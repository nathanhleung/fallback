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
        <div className="mt-4">
          <Link to="/docs/how-it-works">How it Works</Link>
        </div>
      </div>
    </header>
  );
}

export default function Home(): JSX.Element {
  const [path, setPath] = useState("");
  const [routeFunctionName, setRouteFunctionName] = useState("getMyPath");
  const [responseType, setResponseType] = useState("text");
  const [responseContent, setResponseContent] = useState("Hello world!");
  const [compiling, setCompiling] = useState(false);
  const [deploying, setDeploying] = useState(false);
  const [contractAddress, setContractAddress] = useState("");
  const [requestPath, setRequestPath] = useState("");
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
    return new Promise((resolve, reject) => {
      const id = compileCounterRef.current;
      solc.postMessage({
        id,
        path,
        routeFunctionName,
        responseType,
        responseContent,
      });
      compileCounterRef.current += 1;
      solc.onmessage = ({ data }) => {
        if (data.id === id) {
          if (data.evm) {
            resolve(data.evm);
          } else if (data.errors) {
            reject(data.errors);
          }
        }
      };
    });
  }

  async function handleCompileAndRun(e: React.FormEvent) {
    e.preventDefault();

    setContractAddress("");
    setResponse("");

    let bytecode;
    try {
      setCompiling(true);
      bytecode = (await compileContract()).bytecode;
    } catch (errs) {
      if (errs.length) {
        setResponse(
          errs
            .map((err) => {
              return err.formattedMessage;
            })
            .join("\n")
        );
      }
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
        data: Buffer.from(`GET /${requestPath} HTTP/1.1`),
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
          <h2 className="text-2xl">Try It</h2>
          <p>
            Write a fallback()-based web app and run it in your browser (Web
            Workers API support required).
          </p>
        </div>

        <form className="grid grid-cols-2 gap-4" onSubmit={handleCompileAndRun}>
          <div className="col-auto">
            <div className="grid gap-4 grid-cols-1 mb-8">
              <div className="col-auto">
                <h3>1. Configure a route handler</h3>
                <label className="block text-gray-700 dark:text-gray-300 text-sm font-bold mb-2">
                  1. Choose a path
                </label>
                <input
                  value={path}
                  onChange={(e) => {
                    setPath(e.target.value);
                    setRequestPath(e.target.value);
                  }}
                  placeholder="path"
                  className="shadow appearance-none border-[1px] dark:border-none rounded w-full py-2 px-3 text-gray-700 dark:text-gray-300 leading-tight focus:outline-none focus:shadow-outline text-lg"
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
                  className="shadow appearance-none border-[1px] dark:border-none rounded w-full py-2 px-3 text-gray-700 dark:text-gray-300 leading-tight focus:outline-none focus:shadow-outline text-lg"
                  required
                />
                <small>
                  The name of the route handler function in the web app contract
                </small>
              </div>
              <div className="col-auto">
                <label className="block text-gray-700 dark:text-gray-300 text-sm font-bold mb-2">
                  3. Choose a response type
                </label>
                <select
                  value={responseType}
                  onChange={(e) => {
                    const newResponseType = e.target.value;
                    setResponseType(newResponseType);

                    if (newResponseType !== responseType) {
                      if (newResponseType == "json") {
                        setResponseContent(JSON.stringify({ hello: "world" }));
                      } else if (newResponseType == "text") {
                        setResponseContent("Hello world!");
                      } else if (newResponseType == "html") {
                        setResponseContent("<h1>Hello world!</h1>");
                      } else if (newResponseType == "redirect") {
                        setResponseContent(
                          "https://github.com/nathanhleung/fallback"
                        );
                      }
                    }
                  }}
                  className="dark:bg-[rgb(59,59,59)] dark:border-none focus:outline-none active:outline-none rounded"
                >
                  <option value="text">Text</option>
                  <option value="json">JSON</option>
                  <option value="html">HTML</option>
                  <option value="redirect">Redirect</option>
                </select>
              </div>
              <div className="col-auto">
                <label className="block text-gray-700 dark:text-gray-300 text-sm font-bold mb-2">
                  4. Write your response content
                </label>
                <input
                  value={responseContent}
                  onChange={(e) => setResponseContent(e.target.value)}
                  placeholder="responseContent"
                  className="shadow appearance-none border-[1px] dark:border-none rounded w-full py-2 px-3 text-gray-700 dark:text-gray-300 leading-tight focus:outline-none focus:shadow-outline text-lg"
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
        return ${responseType}('${responseContent}');
    }
}`}
            </CodeBlock>
          </div>
          <div className="col-auto">
            <h3>3. Compile and send request</h3>
            <CodeBlock language="javascript" title="request.js">
              {`const CONTRACT_ADDRESS = "${contractAddress}";

const request = "GET /${requestPath} HTTP/1.1";
const result = await web3.eth.call({
  to: CONTRACT_ADDRESS,
  data: Buffer.from(request).toString("hex");
});
console.log(Buffer.from(result, "hex").toString());
        `.trim()}
            </CodeBlock>
            <div className="my-6">
              <label className="block text-gray-700 dark:text-gray-300 text-sm font-bold mb-2">
                Request Path
              </label>
              <input
                value={requestPath}
                onChange={(e) => setRequestPath(e.target.value)}
                placeholder="path"
                className="shadow appearance-none border-[1px] dark:border-none rounded w-full py-2 px-3 text-gray-700 dark:text-gray-300 leading-tight focus:outline-none focus:shadow-outline text-lg"
              />
            </div>
            <button
              type="submit"
              className="button button--secondary  button--lg"
              disabled={compiling || deploying}
            >
              {compiling
                ? "Compiling..."
                : deploying
                ? "Deploying..."
                : "Compile and Run In-Browser"}
            </button>
            <small className="mt-2 block">
              {compiling
                ? "Compilation may take a moment, please wait..."
                : "Your browser must support the Web Workers API"}
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
                  Now that you've tried it, write your own fallback() app by
                  following the <Link to="/docs/quickstart">Quick Start</Link>.
                </p>
                <Link
                  className="button button--primary button--lg"
                  to="/docs/quickstart"
                >
                  Go to Quick Start
                </Link>
              </>
            )}
          </div>
        </form>
      </main>
    </Layout>
  );
}
