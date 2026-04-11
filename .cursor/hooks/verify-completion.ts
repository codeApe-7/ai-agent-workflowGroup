/**
 * Cursor Stop Hook — 完成前验证守卫
 *
 * 当 Agent 会话结束时自动执行。检查 .cursor/scratchpad.md 中是否标记了 DONE，
 * 若未标记则提示 Agent 继续完成验证步骤。
 *
 * 输入 (stdin JSON):
 *   - conversation_id: 会话 ID
 *   - status: "completed" | "aborted" | "error"
 *   - loop_count: 当前循环次数
 *
 * 输出 (stdout JSON):
 *   - {} 表示放行
 *   - { followup_message: "..." } 表示要求 Agent 继续
 */

import { readFileSync, existsSync } from "fs";

interface StopHookInput {
  conversation_id: string;
  status: "completed" | "aborted" | "error";
  loop_count: number;
}

const MAX_ITERATIONS = 3;

function pass(): never {
  console.log(JSON.stringify({}));
  process.exit(0);
}

async function readStdin(): Promise<string> {
  const chunks: Buffer[] = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString("utf-8");
}

async function main() {
  const raw = await readStdin();

  let input: StopHookInput;
  try {
    input = JSON.parse(raw);
  } catch {
    pass();
  }

  if (input!.status !== "completed" || input!.loop_count >= MAX_ITERATIONS) {
    pass();
  }

  const scratchpadPath = ".cursor/scratchpad.md";
  const scratchpad = existsSync(scratchpadPath)
    ? readFileSync(scratchpadPath, "utf-8")
    : "";

  if (scratchpad.includes("DONE")) {
    console.log(JSON.stringify({}));
  } else {
    console.log(
      JSON.stringify({
        followup_message: [
          `[验证守卫 - 第 ${input!.loop_count + 1}/${MAX_ITERATIONS} 轮]`,
          "",
          "检测到任务尚未标记完成。请确认：",
          "1. 是否已运行验证命令并确认通过？",
          "2. 是否已将验证证据展示给用户？",
          "",
          "如果已全部完成，请在 `.cursor/scratchpad.md` 中写入 DONE。",
          "如果仍有未完成的工作，请继续执行。",
        ].join("\n"),
      })
    );
  }
}

main();
