// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "./HttpConstants.sol";
import "./Integers.sol";
import "./StringConcat.sol";
import "./StringCase.sol";
import "./StringCompare.sol";
import "forge-std/console.sol";

/**
 * Utility contract to for working with HTTP messages (i.e. requests and
 * responses).
 */
contract HttpMessages {
    using StringCase for string;
    using StringConcat for string;
    using StringConcat for string[];
    using StringCompare for string;
    using Strings for uint16;
    using Strings for uint256;

    struct Options {
        /**
         * The maximum number of HTTP request headers to support.
         */
        uint256 maxRequestHeaders;
        /**
         * The maximum length of a single HTTP request header to support.
         */
        uint256 maxRequestHeaderLength;
        /**
         * The maximum path length to support.
         */
        uint256 maxPathLength;
    }

    struct Request {
        /**
         * The HTTP method of the request
         */
        HttpConstants.Method method;
        /**
         * The path of the request
         */
        string path;
        /**
         * Request headers
         */
        string[] headers;
        /**
         * Request content legnth
         */
        uint256 contentLength;
        /**
         * Request content
         */
        bytes content;
        /**
         * Raw request bytes
         */
        bytes raw;
    }

    struct Response {
        /**
         * Response status code
         */
        uint16 statusCode;
        /**
         * Response headers
         */
        string[] headers;
        /**
         * Response content
         */
        string content;
    }

    Options options;
    HttpConstants constants = new HttpConstants();
    bytes1 constant SPACE_BYTE = hex"20";
    bytes1 constant CARRIAGE_RETURN_BYTE = hex"0D";
    bytes1 constant LINE_FEED_BYTE = hex"0A";

    constructor(Options memory _options) {
        options = _options;
    }

    /**
     * Gets the next non-space character's index,
     * starting at `startIndex`. If the character at
     * `startIndex` is already a space, returns immediately.
     */
    function getNextNonSpaceIndex(
        uint256 startIndex,
        bytes calldata messageBytes
    ) private pure returns (uint256 nextNonSpaceIndex) {
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
        pure
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
        view
        returns (HttpConstants.Method method, string memory path)
    {
        uint256 i = getNextNonSpaceIndex(0, requestBytes);
        uint256 methodStartIndex = i;

        // According to SO, the longest HTTP verb is 17 characters.
        // So initializing a 32-byte array to store the method name
        // should suffice.
        // https://stackoverflow.com/questions/41411152/how-many-http-verbs-are-there
        bytes memory methodBytes = new bytes(32);
        uint256 methodLength = 0;
        while (requestBytes[i] != SPACE_BYTE) {
            methodBytes[i - methodStartIndex] = requestBytes[i];
            methodLength += 1;
            i += 1;
        }
        assembly {
            mstore(methodBytes, sub(mload(methodBytes), sub(32, methodLength)))
        }
        method = constants.METHOD_ENUMS(string(methodBytes).toLowerCase());

        // requestBytes[i] is now a space, so we increment by 1
        // to get the path
        i += 1;
        uint256 pathStartIndex = i;
        bytes memory pathBytes = new bytes(options.maxPathLength);
        uint256 pathLength = 0;
        while (requestBytes[i] != SPACE_BYTE) {
            pathBytes[i - pathStartIndex] = requestBytes[i];
            pathLength += 1;
            i += 1;
        }

        // Change array size to actual size
        // https://ethereum.stackexchange.com/questions/51891/how-to-pop-from-decrease-the-length-of-a-memory-array-in-solidity
        uint256 maxPathLength = options.maxPathLength;
        assembly {
            mstore(
                pathBytes,
                sub(mload(pathBytes), sub(maxPathLength, pathLength))
            )
        }
        path = string(pathBytes);

        return (method, path);
    }

    /**
     * Parses request headers from the raw request.
     */
    function parseRequestHeaders(bytes calldata requestBytes)
        private
        view
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
        requestHeaders = new string[](options.maxRequestHeaders);
        uint256 requestHeadersCount = 0;
        while (i < requestBytes.length) {
            uint256 headerStartIndex = i;
            uint256 headerLength = 0;
            bytes memory headerBytes = new bytes(
                options.maxRequestHeaderLength
            );
            while (
                requestBytes[i - 1] != CARRIAGE_RETURN_BYTE &&
                requestBytes[i] != LINE_FEED_BYTE
            ) {
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
            uint256 maxRequestHeaderLength = options.maxRequestHeaderLength;
            assembly {
                mstore(
                    headerBytes,
                    sub(
                        mload(headerBytes),
                        sub(maxRequestHeaderLength, headerLength)
                    )
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
                contentLength = Integers.parseInt(string(contentLengthBytes));
            }

            // requestBytes[i] is now the line feed at the end of the header
            // Increment to move onto the next header
            i += 1;

            // If the most recently parsed header was blank,
            // it's the extra newline before the content, so
            // break.
            if (headerLength == 0) {
                // Subtract blank header
                requestHeadersCount -= 1;
                break;
            }
        }

        // Resize headers array
        uint256 maxRequestHeaders = options.maxRequestHeaders;
        assembly {
            mstore(
                requestHeaders,
                sub(
                    mload(requestHeaders),
                    // Since the last header was blank,
                    // there's actually one less header
                    sub(maxRequestHeaders, requestHeadersCount)
                )
            )
        }

        return (i, requestHeaders, contentLength);
    }

    function parseRequestContent(
        uint256 startIndex,
        uint256 contentLength,
        bytes calldata requestBytes
    ) private pure returns (bytes memory requestContent) {
        // Start iterating thru the request content after the headers
        uint256 i = startIndex;
        uint256 contentStartIndex = i;
        requestContent = new bytes(contentLength);
        // Make sure we don't go out of bounds
        uint256 contentEndIndex = Math.min(
            contentStartIndex + contentLength,
            requestBytes.length
        );

        while (i < contentEndIndex) {
            requestContent[i - contentStartIndex] = requestBytes[i];
            i += 1;
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
        view
        returns (Request memory request)
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

        bytes memory requestContent = parseRequestContent(
            contentStartIndex,
            contentLength,
            requestBytes
        );

        request.method = method;
        request.path = path;
        request.headers = requestHeaders;
        request.contentLength = contentLength;
        request.content = requestContent;
        request.raw = requestBytes;
        return request;
    }

    /**
     * Given the parts of an HTTP response, builds the response
     * and returns the raw bytes which can be sent back to the
     * client.
     */
    function buildResponse(Response memory response)
        external
        view
        returns (bytes memory responseBytes)
    {
        // Default to 200 if status code is unset
        if (response.statusCode == 0) {
            response.statusCode = 200;
        }

        string memory responseHeadersString = StringConcat
            .concat(
                "HTTP/1.1 ",
                response.statusCode.toString(),
                " ",
                constants.STATUS_CODE_STRINGS(response.statusCode),
                "\r\n",
                "Server: fallback()\r\n"
            )
            .concat(response.headers.join("\r\n"));

        // Default to text/html if no headers but has content
        uint256 contentLength = bytes(response.content).length;
        if (response.headers.length == 0 && contentLength != 0) {
            responseHeadersString = responseHeadersString.concat(
                "Content-Type: text/html"
            );
        }

        responseBytes = bytes(
            responseHeadersString.concat(
                "\r\n",
                "Date: ",
                block.timestamp.toString(),
                "\r\n"
                "Content-Length: ",
                contentLength.toString(),
                "\r\n\r\n",
                response.content
            )
        );

        return responseBytes;
    }
}
