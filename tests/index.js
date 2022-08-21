const assert = require("assert");
const path = require("path");
const fs = require("fs/promises");
const Module = require("../dist/ffmpeg");

before(async function () {
  await fs.mkdir(path.join(__dirname, "out"), { recursive: true });
});

describe("all", function () {
  it("should convert audio", async function () {
    const exitStatus = await callMain([
      "-y",
      "-i",
      "assets/sample.mp4",
      "-threads",
      "1",
      "out/out.mp3",
    ]);
    assert.equal(exitStatus, 0);
  });

  // Ensure this doesn't call `process.exit`
  it("should exit properly on error", async function () {
    const exitStatus = await callMain(["unknown-subcommand"]);
    assert.equal(exitStatus, 1);
  });
});

async function callMain(args) {
  let quit;
  const promise = new Promise((resolve) => (quit = resolve));
  const mod = await Module({
    // Since we are using `PROXY_TO_PTHREAD`, the main thread doesn't block.
    // Use the `quit` callback so we know when the process completes.
    quit,
    // Make the threadpool terminate once finished or else the (node) process will hang.
    noExitRuntime: false,
  });
  const working = "/working";
  mod.FS.mkdir(working);
  mod.FS.mount(mod.NODEFS, { root: __dirname }, working);
  mod.FS.chdir(working);
  mod.callMain(args);
  return promise;
}
