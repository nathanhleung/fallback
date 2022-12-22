import React from "react";
import clsx from "clsx";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import CodeBlock from "@theme/CodeBlock";

import styles from "./index.module.css";
import { GithubStarsButton } from "../components/GithubStarsButton";

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx("hero bg-transparent", styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title dark:text-white">{siteConfig.title}</h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <GithubStarsButton />
          <Link className="button button--primary button--lg" to="/docs/intro">
            Get Started
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home(): JSX.Element {
  return (
    <Layout
      title={`fallback() Solidity Web Framework`}
      description="Description will go into a meta tag in <head />"
    >
      <main className="container px-6 mx-auto">
        <HomepageHeader />
        <div className="text-center py-8">
          <h2 className="text-2xl">Try it</h2>
        </div>
        <div className="text-center py-8">
          <h2 className="text-2xl">
            Create a Solidity web app in a few easy steps
          </h2>
        </div>
        <section className="space-y-12">
          <section>
            <h2 className="text-xl">
              1. Extend <code>WebApp</code>
            </h2>
            <CodeBlock language="solidity" title="MyApp.sol">
              {`import {WebApp} from "https://github.com/nathanhleung/fallback/blob/main/src/WebApp.sol";

contract MyApp is WebApp {
    constructor() {
    }
}
`}
            </CodeBlock>
          </section>
          <section>
            <h2 className="text-xl">2. Add your routes</h2>
            <CodeBlock language="solidity" title="MyApp.sol">
              {`// highlight-start
import {HttpConstants} from "https://github.com/nathanhleung/fallback/blob/main/src/http/HttpConstants.sol";
// highlight-end
import {WebApp} from "https://github.com/nathanhleung/fallback/blob/main/src/WebApp.sol";

contract MyApp is WebApp {
    constructor() {
        // highlight-start
        routes[HttpConstants.Method.GET]["/"] = "getIndex";
        routes[HttpConstants.Method.GET]["/github"] = "getGithub";
        // highlight-end
    }
}
`}
            </CodeBlock>
          </section>
          <section>
            <h2 className="text-xl">
              3. Create contract functions for your routes
            </h2>
            <CodeBlock language="solidity" title="MyApp.sol">
              {`import {HttpConstants} from "https://github.com/nathanhleung/fallback/blob/main/src/http/HttpConstants.sol";
// highlight-start
import {HttpMessages} from "https://github.com/nathanhleung/fallback/blob/main/src/http/HttpMessages.sol";
// highlight-end
import {WebApp} from "https://github.com/nathanhleung/fallback/blob/main/src/WebApp.sol";

contract MyApp is WebApp {
    constructor() {
        routes[HttpConstants.Method.GET]["/"] = "getIndex";
        routes[HttpConstants.Method.GET]["/github"] = "getGithub";
    }

    // highlight-start
    function getIndex(HttpMessages.Request calldata request) external pure override returns (HttpMessages.Response memory) {
    }
    // highlight-end

    // highlight-start
    function getGithub() external pure returns (HttpMessages.Response memory) {
    }
    // highlight-end
}
`}
            </CodeBlock>
          </section>
          <section>
            <h2 className="text-xl">4. Implement your routes</h2>
            <CodeBlock language="solidity" title="MyApp.sol">
              {`// highlight-start
import {H} from "https://github.com/nathanhleung/fallback/blob/main/src/html-dsl/H.sol";
// highlight-end
import {HttpConstants} from "https://github.com/nathanhleung/fallback/blob/main/src/http/HttpConstants.sol";
import {HttpMessages} from "https://github.com/nathanhleung/fallback/blob/main/src/http/HttpMessages.sol";
// highlight-start
import {StringConcat} from "https://github.com/nathanhleung/fallback/blob/main/src/strings/StringConcat.sol";
// highlight-end
import {WebApp} from "https://github.com/nathanhleung/fallback/blob/main/src/WebApp.sol";


contract MyApp is WebApp {
    constructor() {
        routes[HttpConstants.Method.GET]["/"] = "getIndex";
        routes[HttpConstants.Method.GET]["/github"] = "getGithub";
    }

    // highlight-start
    function getIndex(HttpMessages.Request calldata request) external pure override returns (HttpMessages.Response memory) {
        string memory htmlString = H.html5(
            H.body(
                StringConcat.concat(
                    H.h1("fallback() web framework"),
                    H.p(H.i("a solidity web framework"))
                )
            )
        );
        return html(htmlString);
    }
    // highlight-end

    // highlight-start
    function getGithub() external pure returns (HttpMessages.Response memory) {
        return redirect(302, "https://github.com/nathanhleung/fallback");
    }
    // highlight-end
}
`}
            </CodeBlock>
          </section>
          <section>
            <h2 className="text-xl">
              5. Pass your app to the <code>DefaultServer</code> contract
            </h2>
            <CodeBlock language="solidity" title="MyServer.sol">
              {`import {DefaultServer} from "https://github.com/nathanhleung/fallback/blob/main/src/HttpServer.sol";
import {MyApp} from "./MyApp.sol";

contract MyServer is DefaultServer {
    constructor() DefaultServer(new MyApp()) {
        app.setDebug(true);
    }
}
`}
            </CodeBlock>
          </section>
          <section>
            <h2 className="text-xl">
              6. Deploy <code>MyServer</code>
            </h2>
            <CodeBlock language="bash" title="Terminal">
              {`forge create MyServer.sol:MyServer`}
            </CodeBlock>
          </section>
          <section>
            <h2 className="text-xl">7. Send HTTP requests to the contract</h2>
            <CodeBlock language="javascript" title="request.js">
              {`const http = require("http");

// Construct JSON-RPC request
const jsonRpcData = JSON.stringify({
  jsonrpc: "2.0",
  id: "1",
  method: "eth_call",
  params: [
    {
      to: CONTRACT_ADDRESS,
      // HTTP request to send to contract
      data: "GET / HTTP/1.1\\r\\nHost: 127.0.0.1".toString("hex"),
    },
  ],
});

// Send JSON-RPC request
const httpRequest = http.request(
  {
    host: ETHEREUM_RPC_HOST,
    path: "/",
    port: ETHEREUM_RPC_PORT,
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
  },
  // Receive response
  (response) => {
    let responseData = "";
    response.on("data", (chunk) => (responseData += chunk));
    response.on("end", () => {
      const responseJson = JSON.parse(responseData);
      const responseBytes = Buffer.from(responseJson.result.slice(2), "hex");
      console.log(responseBytes.toString());
      // HTTP/1.1 200 OK
      // Server: fallback()
      // Content-Type: text/html
      // ...
    });
  }
);
httpRequest.write(jsonRpcData);
httpRequest.end();
`}
            </CodeBlock>
          </section>
        </section>
      </main>
    </Layout>
  );
}
