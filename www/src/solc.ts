importScripts(
  "https://binaries.soliditylang.org/bin/soljson-v0.8.13+commit.abaa5c0e.js"
);
import wrapper from "solc/wrapper";

import OwnableContract from "raw-loader!../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import ContextContract from "raw-loader!../../lib/openzeppelin-contracts/contracts/utils/Context.sol";
import StringsContract from "raw-loader!../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import MathContract from "raw-loader!../../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import HContract from "raw-loader!../../src/html-dsl/H.sol";
import HtmlDslContract from "raw-loader!../../src/html-dsl/HtmlDsl.sol";
import HttpConstantsContract from "raw-loader!../../src/http/HttpConstants.sol";
import HttpHandlerContract from "raw-loader!../../src/http/HttpHandler.sol";
import HttpMessagesContract from "raw-loader!../../src/http/HttpMessages.sol";
import HttpProxyContract from "raw-loader!../../src/http/HttpProxy.sol";
import IntegersContract from "raw-loader!../../src/integers/Integers.sol";
import StringCaseContract from "raw-loader!../../src/strings/StringCase.sol";
import StringCompareContract from "raw-loader!../../src/strings/StringCompare.sol";
import StringConcatContract from "raw-loader!../../src/strings/StringConcat.sol";
import WebAppContract from "raw-loader!../../src/WebApp.sol";
import HttpServerContract from "raw-loader!../../src/HttpServer.sol";

const solc = wrapper(self.Module);

self.onmessage = ({
  data: { id, path, routeFunctionName, responseType, responseContent },
}) => {
  const myAppSol = `
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {HttpConstants} from "./http/HttpConstants.sol";
import {HttpMessages} from "./http/HttpMessages.sol";
import {DefaultServer} from "./HttpServer.sol";
import {WebApp} from "./WebApp.sol";

contract MyApp is WebApp {
    constructor() {
        routes[HttpConstants.Method.GET]["/${path}"] = "${routeFunctionName}";
    }

    function ${routeFunctionName}(HttpMessages.Request calldata request)
        external
        pure${routeFunctionName === "getIndex" ? "\n        override" : ""}
        returns (HttpMessages.Response memory)
    {
        request;
        return ${responseType}('${responseContent}');
    }
}

contract MyServer is DefaultServer {
  constructor() DefaultServer(new MyApp()) {
      app.setDebug(true);
  }
}
  `;

  const input = JSON.stringify({
    language: "Solidity",
    sources: {
      "lib/openzeppelin-contracts/contracts/access/Ownable.sol": {
        content: OwnableContract,
      },
      "lib/openzeppelin-contracts/contracts/utils/Context.sol": {
        content: ContextContract,
      },
      "lib/openzeppelin-contracts/contracts/utils/Strings.sol": {
        content: StringsContract,
      },
      "lib/openzeppelin-contracts/contracts/utils/math/Math.sol": {
        content: MathContract,
      },
      "html-dsl/H.sol": {
        content: HContract,
      },
      "html-dsl/HtmlDsl.sol": {
        content: HtmlDslContract,
      },
      "http/HttpConstants.sol": {
        content: HttpConstantsContract,
      },
      "http/HttpHandler.sol": {
        content: HttpHandlerContract,
      },
      "http/HttpMessages.sol": {
        content: HttpMessagesContract,
      },
      "http/HttpProxy.sol": {
        content: HttpProxyContract,
      },
      "integers/Integers.sol": {
        content: IntegersContract,
      },
      "strings/StringCase.sol": {
        content: StringCaseContract,
      },
      "strings/StringCompare.sol": {
        content: StringCompareContract,
      },
      "strings/StringConcat.sol": {
        content: StringConcatContract,
      },
      "WebApp.sol": {
        content: WebAppContract,
      },
      "HttpServer.sol": {
        content: HttpServerContract,
      },
      "MyApp.sol": {
        content: myAppSol,
      },
    },
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      outputSelection: {
        "*": {
          "*": ["abi", "evm.bytecode"],
        },
      },
    },
  });

  const output = JSON.parse(solc.compile(input));

  if (output.contracts && output.contracts["MyApp.sol"]) {
    self.postMessage({
      id,
      evm: output.contracts["MyApp.sol"].MyServer.evm,
    });
  } else if (output.errors && output.errors.length > 0) {
    self.postMessage({
      id,
      errors: output.errors,
    });
  } else {
    self.postMessage({
      id,
      errors: [{ formattedMessage: "Compilation failed." }],
    });
  }
};
