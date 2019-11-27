const path = require("path");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const FixDefaultImportPlugin = require("webpack-fix-default-import-plugin");

module.exports = {
    mode: "development",
    devtool: "inline-source-map",
    entry: "./src/index.tsx",
    output: {
        path: path.resolve(__dirname, "./build"),
        filename: "bundle.js",
    },
    resolve: {
        extensions: [".ts", ".tsx", ".js"],
    },
    module: {
        rules: [
            {
                test: /\.tsx?$/,
                loader: "ts-loader"
            },
            {
                test: /\.scss$/,
                use: [
                    "style-loader",
                    "css-loader?modules=true&localIdentName=[name]__[local]___[hash:base64:5]",
                    "sass-loader",
                ],
            }
        ]
    },
    plugins: [
        new CopyWebpackPlugin([
            { from: "public" },
        ]),
        new FixDefaultImportPlugin(),
    ],
    externals: {
        "babylonjs": "BABYLON",
    },
    devServer: {
        contentBase: path.resolve(__dirname, "./build"),
        compress: true,
        port: 9000,
    },
}
