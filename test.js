//const wdio = require("webdriverio");
//
//const opts = {
//  hostname: "localhost",
//  port: 4723,
//  path: "/",
//  capabilities: {
//    platformName: "Android",
//    "appium:deviceName": "Pixel 8 API 34", // Replace with your emulator/device name
//    "appium:app": "C:\Users\shams\flutter_projects\recipeasy\build\app\outputs\flutter-apk\app-debug.apk", // Path to your APK
//    "appium:automationName": "Flutter"
//  }
//};
//
//async function main() {
//  const driver = await wdio.remote(opts);
//  console.log("App launched successfully!");
//  await driver.deleteSession();
//}
//
//main();
const wdio = require("webdriverio");

const opts = {
    hostname: "localhost",
    port: 4723,
    path: "/",
capabilities: {
        platformName: "Android",
        "appium:deviceName": "Pixel 8 API 34",
        "appium:app": "C:/Users/shams/flutter_projects/recipeasy/build/app/outputs/flutter-apk/app-debug.apk",
        "appium:automationName": "Flutter"
    }
};

async function main() {
    const driver = await wdio.remote(opts);
    console.log("App launched successfully!");
    await driver.deleteSession();
}

main();