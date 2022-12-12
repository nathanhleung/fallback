// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "./HttpConstants.sol";
import "./Integers.sol";
import "./StringConcat.sol";
import "./StringCase.sol";
import "./StringStartsWith.sol";
import "forge-std/console.sol";

/**
 * Utility contract to for working with HTTP messages (i.e. requests and
 * responses).
 */
contract HttpMessages {
    using StringCase for string;
    using StringConcat for string;
    using StringStartsWith for string;
    using Strings for uint16;
    using Strings for uint256;

    HttpConstants constants = new HttpConstants();
    bytes1 constant SPACE_BYTE = hex"20";
    bytes1 constant CARRIAGE_RETURN_BYTE = hex"0D";
    bytes1 constant LINE_FEED_BYTE = hex"0A";

    /**
     * Gets the next non-space character's index,
     * starting at `startIndex`. If the character at
     * `startIndex` is already a space, returns immediately.
     */
    function getNextNonSpaceIndex(
        uint256 startIndex,
        bytes calldata messageBytes
    ) private returns (uint256 nextNonSpaceIndex) {
        uint256 i = startIndex;

        while (messageBytes[i] == SPACE_BYTE) {
            i += 1;

            if (i >= messageBytes.length) {
                break;
            }
        }

        return i;
    }

    /**
     * Gets the index of the start of the next (HTTP) line,
     * starting at `startIndex`. Specifically, it looks for the
     * first index after the next `\r\n`. If `startIndex` is
     * already a `\n` after a `\r`, returns immediately.
     */
    function getNextLineIndex(uint256 startIndex, bytes calldata messageBytes)
        private
        returns (uint256 nextLineIndex)
    {
        uint256 i = startIndex;

        // Need to increment so we can safely look back for a `\r`.
        if (i == 0) {
            i += 1;
        }

        // HTTP uses `\r\n` newlines
        // https://stackoverflow.com/questions/27966357/new-line-definition-for-http-1-1-headers
        while (
            messageBytes[i - 1] != CARRIAGE_RETURN_BYTE &&
            messageBytes[i] != LINE_FEED_BYTE
        ) {
            i += 1;
        }

        i += 1;
        return i;
    }

    function parseRequestRoute(bytes calldata requestBytes)
        private
        returns (HttpConstants.Method method, string memory path)
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
        method = constants.METHOD_ENUMS(string(methodBytes).toLowerCase());

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

        // TODO(nathanhleung) pack other large array allocations
        // https://ethereum.stackexchange.com/questions/51891/how-to-pop-from-decrease-the-length-of-a-memory-array-in-solidity
        assembly {
            mstore(pathBytes, sub(mload(pathBytes), sub(4000, pathLength)))
        }
        path = string(pathBytes);

        return (method, path);
    }

    /**
     * Parses request headers from the raw request.
     */
    function parseRequestHeaders(bytes calldata requestBytes)
        private
        returns (
            uint256 contentStartIndex,
            string[] memory requestHeaders,
            uint256 contentLength
        )
    {
        // Skip to the start of the next line (first line
        // is HTTP method and path).
        uint256 i = getNextLineIndex(0, requestBytes);

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
            uint256 headerLength = 0;
            // TODO(nathanhleung) assume 4000 characters per header?
            // Maybe make all this stuff configurable
            bytes memory headerBytes = new bytes(4000);
            while (
                requestBytes[i - 1] != CARRIAGE_RETURN_BYTE &&
                requestBytes[i] != LINE_FEED_BYTE
            ) {
                console.log("in individual header loop");
                headerBytes[i - headerStartIndex] = requestBytes[i];
                headerLength += 1;
                i += 1;
            }
            // At this point, we've reached the end of the line
            // requestBytes[i] is the line feed; the last index of
            // headerBytes is a carriage return which we should
            // remove.
            headerLength -= 1;

            // Change string length to actual length rather than
            // allocated length
            // https://ethereum.stackexchange.com/questions/51891/how-to-pop-from-decrease-the-length-of-a-memory-array-in-solidity
            assembly {
                mstore(
                    headerBytes,
                    sub(mload(headerBytes), sub(4000, headerLength))
                )
            }
            string memory headerString = string(headerBytes);

            requestHeaders[requestHeadersCount] = headerString;
            requestHeadersCount += 1;

            if (headerString.toLowerCase().startsWith("content-length: ")) {
                uint256 headerLength = headerBytes.length;
                // "content-length: " is 16 characters
                bytes memory contentLengthBytes = new bytes(headerLength - 16);
                for (uint256 j = 16; j < headerLength; j += 1) {
                    contentLengthBytes[j - 16] = headerBytes[j];
                }

                console.log(headerString);
                console.logBytes(contentLengthBytes);
                console.log(Integers.parseInt(string(contentLengthBytes)) * 2);
                console.log("parseInt");
                // contentLength = headerString
            }

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

    function parseRequestContent(
        uint256 startIndex,
        uint256 contentLength,
        bytes calldata requestBytes
    ) private returns (bytes memory requestContent) {
        // Start iterating thru the request content after the headers
        uint256 i = startIndex;
        uint256 contentStartIndex = i;
        requestContent = new bytes(contentLength);
        // Make sure we don't go out of bounds
        uint256 contentEndIndex = Math.min(
            contentStartIndex + contentLength,
            requestBytes.length - 1
        );
        while (i < contentEndIndex) {
            requestContent[i - contentStartIndex] = requestBytes[i];
        }
        return requestContent;
    }

    /**
     * Given the raw bytes of an HTTP request, parses out the
     * method, headers, and request body.
     *
     * TODO(nathanhleung): better handling of pathological cases
     */
    function parseRequest(bytes calldata requestBytes)
        external
        returns (
            HttpConstants.Method,
            string memory path,
            string[] memory requestHeaders,
            bytes memory requestContent
        )
    {
        (HttpConstants.Method method, string memory path) = parseRequestRoute(
            requestBytes
        );

        // Skip HTTP version and just get headers for now.
        // TODO(nathanhleung): handle different HTTP versions?
        (
            uint256 contentStartIndex,
            string[] memory requestHeaders,
            uint256 contentLength
        ) = parseRequestHeaders(requestBytes);

        console.log("parsed headers");

        requestContent = parseRequestContent(
            contentStartIndex,
            contentLength,
            requestBytes
        );

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
    ) external view returns (bytes memory responseBytes) {
        string memory responseHeadersString = "";
        responseHeadersString = responseHeadersString.concat(
            "HTTP/1.1 ",
            statusCode.toString(),
            " ",
            constants.STATUS_CODE_STRINGS(statusCode),
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
