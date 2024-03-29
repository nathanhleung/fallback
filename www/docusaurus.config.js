// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require("prism-react-renderer/themes/github");
const darkCodeTheme = require("prism-react-renderer/themes/dracula");
const NodePolyfillPlugin = require("node-polyfill-webpack-plugin");

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: "fallback()",
  tagline: "Write web apps in Solidity. Serve HTTP over Ethereum.",
  url: "https://fallback.natecation.xyz",
  baseUrl: "/",
  onBrokenLinks: "throw",
  onBrokenMarkdownLinks: "warn",
  favicon: "img/logo-256.png",

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: "nathanhleung", // Usually your GitHub org/user name.
  projectName: "fallback", // Usually your repo name.

  // Even if you don't use internalization, you can use this field to set useful
  // metadata like html lang. For example, if your site is Chinese, you may want
  // to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: "en",
    locales: ["en"],
  },

  presets: [
    [
      "classic",
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve("./sidebars.js"),
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            "https://github.com/facebook/docusaurus/tree/main/packages/create-docusaurus/templates/shared/",
        },
        theme: {
          customCss: require.resolve("./src/css/custom.css"),
        },
      }),
    ],
  ],

  plugins: [
    // https://www.swyx.io/tailwind-docusaurus-2022/
    async () => {
      return {
        name: "docusaurus-tailwindcss",
        configurePostCss(postcssOptions) {
          // Appends TailwindCSS and AutoPrefixer.
          postcssOptions.plugins.push(require("tailwindcss"));
          postcssOptions.plugins.push(require("autoprefixer"));
          return postcssOptions;
        },
      };
    },
    // Add Node module polyfills
    () => {
      return {
        name: "docusaurus-node-polyfills",
        configureWebpack() {
          return {
            resolve: {
              fallback: {
                fs: false,
              },
            },
            plugins: [new NodePolyfillPlugin()],
          };
        },
      };
    },
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        title: "fallback()",
        logo: {
          alt: "fallback() Logo",
          src: "img/logo.svg",
        },
        items: [
          {
            to: "/docs/quickstart",
            position: "left",
            label: "Quick Start",
            activeBaseRegex: "quickstart",
          },
          {
            to: "/docs/how-it-works",
            position: "left",
            label: "How It Works",
            activeBaseRegex: "how-it-works",
          },
          {
            to: "/docs/api",
            position: "left",
            label: "API Reference",
            activeBaseRegex: "api",
          },
          {
            to: "/docs/roadmap",
            position: "left",
            label: "Roadmap",
            activeBaseRegex: "roadmap",
          },
          {
            to: "/docs/acknowledgments",
            position: "left",
            label: "Acknowledgments",
            activeBaseRegex: "acknowledgments",
          },
          {
            href: "https://github.com/nathanhleung/fallback",
            label: "GitHub",
            position: "right",
          },
        ],
      },
      footer: {
        style: "dark",
        links: [
          {
            title: "Links",
            items: [
              {
                label: "Quick Start",
                to: "/docs/quickstart",
              },
              {
                label: "How It Works",
                to: "/docs/how-it-works",
              },
              {
                label: "API Reference",
                to: "/docs/api",
              },
              {
                label: "Roadmap",
                to: "/docs/roadmap",
              },
              {
                label: "Acknowledgments",
                to: "/docs/acknowledgments",
              },
              {
                label: "GitHub",
                href: "https://github.com/facebook/docusaurus",
              },
            ],
          },
        ],
        copyright: `Built with Docusaurus.`,
      },
      prism: {
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
        additionalLanguages: ["solidity"],
      },
    }),
};

module.exports = config;
