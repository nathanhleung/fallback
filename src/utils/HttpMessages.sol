// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "./StringConcat.sol";
import "./StringCase.sol";

/**
 * Utility contract to for working with HTTP messages (i.e. requests and
 * responses).
 */
contract HttpMessages {
    using StringCase for string;
    using StringConcat for string;
    using Strings for uint16;
    using Strings for uint256;

    enum Method {
        GET,
        POST
    }

    mapping(uint16 => string) statusCodeStrings;
    mapping(string => Method) methodEnums;

    bytes1 constant SPACE_BYTE = hex"20";
    bytes1 constant CARRIAGE_RETURN_BYTE = hex"0D";
    bytes1 constant LINE_FEED_BYTE = hex"0A";

    constructor() {
        statusCodeStrings[200] = "OK";

        statusCodeStrings[301] = "Moved Permanently";
        statusCodeStrings[302] = "Found";

        statusCodeStrings[400] = "Bad Request";
        statusCodeStrings[401] = "Unauthorized";
        statusCodeStrings[402] = "Payment Required";
        statusCodeStrings[403] = "Forbidden";
        statusCodeStrings[404] = "Not Found";

        statusCodeStrings[500] = "Internal Server Error";
        statusCodeStrings[502] = "Bad Gateway";
        statusCodeStrings[503] = "Service Unavailable";

        methodEnums["get"] = Method.GET;
        methodEnums["post"] = Method.POST;
    }

    function getNextNonSpaceIndex(uint256 startIndex, bytes memory messageBytes)
        private
        returns (uint256 nextNonSpaceIndex)
    {
        uint256 i = startIndex;

        while (messageBytes[i] == SPACE_BYTE) {
            i += 1;

            if (i >= messageBytes.length) {
                break;
            }
        }

        return i;
    }

    function parseRequestRoute(bytes memory requestBytes)
        private
        returns (Method method, string memory path)
    {
        uint256 i = getNextNonSpaceIndex(0, requestBytes);
        uint256 methodStartIndex = i;

        // According to SO, the longest HTTP verb is 17 characters.
        // So initializing a 32-byte array to store the method name
        // should suffice.
        // https://stackoverflow.com/questions/41411152/how-many-http-verbs-are-there
        bytes memory methodBytes = new bytes(32);
        while (requestBytes[i] != SPACE_BYTE) {
            methodBytes[i - methodStartIndex] = requestBytes[i];
            i += 1;
        }
        method = methodEnums[string(methodBytes).toLowerCase()];

        // requestBytes[i] is now a space, so we increment by 1
        // to get the path
        i += 1;
        uint256 pathStartIndex = i;
        // 4,000 characters for the path seems like a reasonable
        // assumption based on this SO answer.
        // https://stackoverflow.com/questions/1289585/what-is-apaches-maximum-url-length
        bytes memory pathBytes = new bytes(4000);
        uint256 pathLength = 0;
        while (requestBytes[i] != SPACE_BYTE) {
            pathBytes[i - pathStartIndex] = requestBytes[i];
            pathLength += 1;
            i += 1;
        }
        // TODO(nathanhleung) is there a better way than just copying?
        // need to pack so we can index in route map
        bytes memory packedPathBytes = new bytes(pathLength);
        for (uint256 j = 0; j < pathLength; j += 1) {
            packedPathBytes[j] = pathBytes[j];
        }
        path = string(packedPathBytes);

        return (method, path);
    }

    /**
     * Parses request headers from the raw request.
     */
    function parseRequestHeaders(bytes memory requestBytes)
        private
        returns (
            uint256 headersEndIndex,
            string[] memory requestHeaders,
            uint256 contentLength
        )
    {
        // Start from 1 since we look back to check for newlines
        uint256 i = 1;

        // Skip to the end of the first line. HTTP uses `\r\n`
        // newlines, so look for that.
        // https://stackoverflow.com/questions/27966357/new-line-definition-for-http-1-1-headers
        while (
            requestBytes[i - 1] != CARRIAGE_RETURN_BYTE &&
            requestBytes[i] != LINE_FEED_BYTE
        ) {
            i += 1;
        }

        // requestBytes[i] is now the line feed at the end of the
        // first line. We increment to start parsing the headers.
        i += 1;

        // Loop through headers until we get two line breaks in a row
        contentLength = 0;
        // TODO(nathanhleung) is 1000 headers a reasonable upper bound?
        requestHeaders = new string[](1000);
        uint256 requestHeadersCount = 0;
        while (
            requestBytes[i - 3] != CARRIAGE_RETURN_BYTE &&
            requestBytes[i - 2] != LINE_FEED_BYTE &&
            requestBytes[i - 1] != CARRIAGE_RETURN_BYTE &&
            requestBytes[i] != LINE_FEED_BYTE
        ) {
            uint256 headerStartIndex = i;
            // TODO(nathanhleung) assume 4000 characters per header?
            // Maybe make all this stuff configurable
            bytes memory headerBytes = new bytes(4000);
            while (
                requestBytes[i - 1] != CARRIAGE_RETURN_BYTE &&
                requestBytes[i] != LINE_FEED_BYTE
            ) {
                headerBytes[i - headerStartIndex] = requestBytes[i];
                i += 1;
            }
            // At this point, we've reached the end of the line
            // Remove the trailing \r\n and then add to headers array
            headerBytes[i - 1] = hex"00";
            headerBytes[i] = hex"00";
            string memory headerString = string(headerBytes);

            requestHeaders[requestHeadersCount] = headerString;
            requestHeadersCount += 1;

            // TODO(nathanhleung) implement content length
            // if (headerString.toLowerCase().startsWith("content-length: ")) {
            //     // get last part, then convert to int
            //     contentLength = headerString
            // }

            // requestBytes[i] is now the line feed at the end of the header
            // Increment to move onto the next header
            i += 1;

            // Don't overshoot
            if (i >= requestBytes.length) {
                break;
            }
        }

        // requestBytes[i] is now the line feed at the end of the
        // double line break after the headers. Increment and
        // return so the top-level `parseRequest` function can
        // consume the request content.
        i += 1;

        return (i, requestHeaders, contentLength);
    }

    /**
     * Given the raw bytes of an HTTP request, parses out the
     * method, headers, and request body.
     *
     * TODO(nathanhleung): better handling of pathological cases
     */
    function parseRequest(bytes memory requestBytes)
        external
        returns (
            Method method,
            string memory path,
            string[] memory requestHeaders,
            bytes memory requestContent
        )
    {
        (Method method, string memory path) = parseRequestRoute(requestBytes);

        // Skip HTTP version and just get headers for now.
        // TODO(nathanhleung): handle different HTTP versions?
        (
            uint256 headersEndIndex,
            string[] memory requestHeaders,
            uint256 contentLength
        ) = parseRequestHeaders(requestBytes);

        // Start iterating thru the request after the headers
        uint256 i = headersEndIndex;
        uint256 contentStartIndex = i;
        requestContent = new bytes(contentLength);
        // Make sure we don't go out of bounds
        uint256 contentEndIndex = Math.min(
            contentStartIndex + contentLength,
            requestBytes.length
        );
        while (i < contentEndIndex) {
            requestContent[i - contentStartIndex] = requestBytes[i];
        }

        return (method, path, requestHeaders, requestContent);
    }

    /**
     * Given the parts of an HTTP response, builds the response
     * and returns the raw bytes which can be sent back to the
     * client.
     */
    function buildResponse(
        uint16 statusCode,
        string[] calldata responseHeaders,
        string calldata responseContent
    ) external returns (bytes memory responseBytes) {
        string memory responseHeadersString = "";
        responseHeadersString = responseHeadersString.concat(
            "HTTP/1.1 ",
            statusCode.toString(),
            " ",
            statusCodeStrings[statusCode],
            "\r\n",
            "Server: fallback()\r\n"
        );

        for (uint8 i = 0; i < responseHeaders.length; i += 1) {
            responseHeadersString = responseHeadersString.concat(
                responseHeaders[i],
                "\r\n"
            );
        }

        responseBytes = bytes(
            responseHeadersString.concat(
                "Date: ",
                block.timestamp.toString(),
                "\r\n"
                "Content-Length: ",
                bytes(responseContent).length.toString(),
                "\r\n\r\n",
                responseContent
            )
        );

        return responseBytes;
    }
}
