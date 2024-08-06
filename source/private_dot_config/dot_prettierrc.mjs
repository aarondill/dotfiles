export default {
  arrowParens: "avoid",
  bracketSameLine: true,
  bracketSpacing: true,
  embeddedLanguageFormatting: "auto",
  quoteProps: "as-needed",
  endOfLine: "lf",
  semi: true,
  singleAttributePerLine: false,
  singleQuote: false,
  trailingComma: "es5",
  useTabs: false,
  tabWidth: 2,
  overrides: [
    {
      files: ["*.jsonc", "*.json", ".eslintrc", "tsconfig*.json"],
      options: {
        trailingComma: "none",
      },
    },
  ],
};
