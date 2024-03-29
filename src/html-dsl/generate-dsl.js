/**
 * Generates an HTML DSL for Solidity by creating a Solidity
 * library with a function for each valid HTML element. Run
 * `node ./generate-dsl` to generate the DSL and write it to
 * `H.sol` in this directory.
 */

const { writeFileSync } = require("fs");
const { resolve } = require("path");

/**
 * Set of all HTML tags. Generated from
 * https://gist.github.com/bramus/a9c1bad426e6f4fd9af0f19ecb2e24a3
 */
const HTML_TAGS = new Set([
  "html",
  "base",
  "head",
  "link",
  "meta",
  "style",
  "title",
  "body",
  "address",
  "article",
  "aside",
  "footer",
  "header",
  "h1",
  "h2",
  "h3",
  "h4",
  "h5",
  "h6",
  "main",
  "nav",
  "section",
  "blockquote",
  "dd",
  "div",
  "dl",
  "dt",
  "figcaption",
  "figure",
  "hr",
  "li",
  "menu",
  "ol",
  "p",
  "pre",
  "ul",
  "a",
  "abbr",
  "b",
  "bdi",
  "bdo",
  "br",
  "cite",
  "code",
  "data",
  "dfn",
  "em",
  "i",
  "kbd",
  "mark",
  "q",
  "rp",
  "rt",
  "ruby",
  "s",
  "samp",
  "small",
  "span",
  "strong",
  "sub",
  "sup",
  "time",
  "u",
  "var",
  "wbr",
  "area",
  "audio",
  "img",
  "map",
  "track",
  "video",
  "embed",
  "iframe",
  "object",
  "picture",
  "portal",
  "source",
  "svg",
  "canvas",
  "noscript",
  "script",
  "del",
  "ins",
  "caption",
  "col",
  "colgroup",
  "table",
  "tbody",
  "td",
  "tfoot",
  "th",
  "thead",
  "tr",
  "button",
  "datalist",
  "fieldset",
  "form",
  "input",
  "label",
  "legend",
  "meter",
  "optgroup",
  "option",
  "output",
  "progress",
  "select",
  "textarea",
  "details",
  "dialog",
  "summary",
  "slot",
  "template",
  "acronym",
  "applet",
  "bgsound",
  "big",
  "blink",
  "center",
  "content",
  "dir",
  "font",
  "frame",
  "frameset",
  "image",
  "keygen",
  "marquee",
  "menuitem",
  "nobr",
  "noembed",
  "noframes",
  "param",
  "plaintext",
  "rb",
  "rtc",
  "shadow",
  "spacer",
  "strike",
  "tt",
  "xmp",
]);

/**
 * Set of self-closing HTML tags. Copied from
 * https://html.spec.whatwg.org/multipage/syntax.html#void-elements
 */
const SELF_CLOSING_HTML_TAGS = new Set([
  "area",
  "base",
  "br",
  "col",
  "embed",
  "hr",
  "img",
  "input",
  "link",
  "meta",
  "source",
  "track",
  "wbr",
]);

/**
 * Set of reserved Solidity keywords. Copied from
 * https://docs.soliditylang.org/en/v0.8.15/cheatsheet.html?highlight=reserved#reserved-keywords
 */
const SOLIDITY_RESERVED_KEYWORDS = new Set([
  "after",
  "alias",
  "apply",
  "auto",
  "byte",
  "case",
  "copyof",
  "default",
  "define",
  "final",
  "implements",
  "in",
  "inline",
  "let",
  "macro",
  "match",
  "mutable",
  "null",
  "of",
  "partial",
  "promise",
  "reference",
  "relocatable",
  "sealed",
  "sizeof",
  "static",
  "supports",
  "switch",
  "typedef",
  "typeof",
  "var",
]);

/**
 * Set of Solidity types. Grabbed from
 * https://docs.soliditylang.org/en/v0.8.17/types.html
 *
 * TODO(nathanhleung):
 * This isn't exhaustive right now, but only covers the types
 * which might conflict with HTML tag names.
 */
const SOLIDITY_TYPES = new Set(["address"]);

/**
 * Set of Solidity keywords.
 *
 * TODO(nathanhleung):
 * This isn't the set of all Solidity keywords, but just the
 * ones which might conflict with HTML tag names. More keywords
 * may need to be added in the future, if the Solidity or HTML
 * specs change.
 */
const SOLIDITY_KEYWORDS = new Set([
  ...SOLIDITY_TYPES,
  ...SOLIDITY_RESERVED_KEYWORDS,
]);

/**
 * Checks whether a given HTML tag is self-closing.
 * @param {string} tagName the tag name
 * @returns whether the tag is self-closing
 */
function isSelfClosing(tagName) {
  return SELF_CLOSING_HTML_TAGS.has(tagName);
}

function generateDsl() {
  let dsl = `
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {StringConcat} from "../strings/StringConcat.sol";
import {HtmlDsl} from "./HtmlDsl.sol";

/**
 * @title H, a Solidity HTML DSL
 * @author Generated by \`generate-dsl.js\` by nathanhleung
 * @notice An HTML DSL for Solidity.
 */
library H {
    /**
     * @dev Creates an arbitrary HTML tag
     */
    function h(string memory tagName) internal pure returns (string memory) {
        return HtmlDsl.customTag(tagName);
    }
    
    /**
     * @dev Creates an arbitrary HTML tag. If the tag is self-closing,
     *     the second parameter will be treated as attributes. If the
     *     tag is not self-closing, the second parameter will be treated
     *     as children.
     * @param tagName The name of the tag
     * @param childrenOrAttributes The children or attributes for the tag
     */
    function h(string memory tagName, string memory childrenOrAttributes)
        internal
        pure
        returns (string memory)
    {
        return HtmlDsl.customTag(tagName, childrenOrAttributes);
    }
    
    /**
     * @dev Creates an arbitrary HTML tag. If the tag is self-closing,
     *     the \`children\` parameter is ignored.
     * @param tagName The name of the tag 
     * @param attributes The attributes for the tag
     * @param children The children of the tag
     */
    function h(
        string memory tagName,
        string memory attributes,
        string memory children
    ) internal pure returns (string memory) {
        return HtmlDsl.customTag(tagName, attributes, children);
    }
    `;

  for (const tag of HTML_TAGS) {
    // If there is an HTML tag that's also a Solidity keyword,
    // prepend the tag name with `html` and camelCase.
    //
    // `address` is one such tag for which this codepath runs.
    let dslFunction = tag;
    if (SOLIDITY_KEYWORDS.has(tag)) {
      dslFunction = `html${tag.charAt(0).toUpperCase()}${tag.slice(1)}`;
    }

    dsl += `
    /**
     * @dev Creates a \`${tag}\` HTML tag.
     */
    function ${dslFunction}() internal pure returns (string memory) {
        return h("${tag}");
    }
    
    /**
     * @dev Creates a \`${tag}\` HTML tag.
     * @param ${
       isSelfClosing(tag)
         ? "attributes The attributes for the tag"
         : "children The children of the tag"
     } 
     */
    function ${dslFunction}(string memory ${
      isSelfClosing(tag) ? "attributes" : "children"
    })
        internal
        pure
        returns (string memory)
    {
        return h("${tag}", ${isSelfClosing(tag) ? "attributes" : "children"});
    }
    `;

    if (!isSelfClosing(tag)) {
      dsl += `
    /**
     * @dev Creates a \`${tag}\` HTML tag.
     * @param attributes The attributes for the tag
     * @param children The children of the tag
     */
    function ${dslFunction}(
        string memory attributes,
        string memory children
    ) internal pure returns (string memory) {
        return h("${tag}", attributes, children);
    }
      `;
    }
  }

  dsl += `
    /**
     * @dev Creates an \`html\` HTML tag with the correct HTML 5
     * \`DOCTYPE\`.
     */
    function html5(string memory children)
        internal
        pure
        returns (string memory)
    {
        return StringConcat.concat("<!DOCTYPE html>", html(children));
    }
}`;

  return dsl.trim();
}

const dsl = generateDsl();
writeFileSync(resolve(__dirname, "H.sol"), dsl, "utf-8");
console.log(`Wrote DSL to H.sol!`);
