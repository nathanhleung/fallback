// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * Contract containing useful HTTP constants.
 */
contract HttpConstants {
    enum Method {
        GET,
        POST
    }

    mapping(uint16 => string) public STATUS_CODE_STRINGS;
    mapping(string => Method) public METHOD_ENUMS;

    constructor() {
        STATUS_CODE_STRINGS[200] = "OK";

        STATUS_CODE_STRINGS[301] = "Moved Permanently";
        STATUS_CODE_STRINGS[302] = "Found";

        STATUS_CODE_STRINGS[400] = "Bad Request";
        STATUS_CODE_STRINGS[401] = "Unauthorized";
        STATUS_CODE_STRINGS[402] = "Payment Required";
        STATUS_CODE_STRINGS[403] = "Forbidden";
        STATUS_CODE_STRINGS[404] = "Not Found";

        STATUS_CODE_STRINGS[500] = "Internal Server Error";
        STATUS_CODE_STRINGS[502] = "Bad Gateway";
        STATUS_CODE_STRINGS[503] = "Service Unavailable";

        METHOD_ENUMS["get"] = Method.GET;
        METHOD_ENUMS["post"] = Method.POST;
    }
}
