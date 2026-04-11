/**
 * Cursor Stop Hook — 提交前安全检查
 *
 * 在 Agent 会话结束时检查是否有未经审查就暂存的文件，
 * 提醒 Agent 不要跳过审查流程直接提交。
 *
 * 输入 (stdin JSON):
 *   - conversation_id: 会话 ID
 *   - status: "completed" | "aborted" | "error"
 *   - loop_count: 当前循环次数
 *
 * 输出 (stdout JSON):
 *   - {} 表示放行
 *   - { followup_message: "..." } 表示发出警告
 */

import { execSync } from "child_process";

interface StopHookInput {
  conversation_id: string;
  status: "completed" | "aborted" | "error";
  loop_count: number;
}

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

  if (input!.status !== "completed" || input!.loop_count >= 1) {
    pass();
  }

  try {
    const staged = execSync("git diff --cached --name-only", {
      encoding: "utf-8",
      timeout: 5000,
    }).trim();

    if (!staged) {
      pass();
    }

    const stagedFiles = staged.split("\n").filter(Boolean);
    const hasCodeChanges = stagedFiles.some((f) =>
      /\.(ts|tsx|js|jsx|py|java|go|rs|rb|cs|cpp|c|h|vue|svelte)$/.test(f)
    );

    if (hasCodeChanges) {
      console.log(
        JSON.stringify({
          followup_message: [
            "[提交安全检查]",
            "",
            `检测到 ${stagedFiles.length} 个已暂存文件包含代码变更：`,
            ...stagedFiles.slice(0, 10).map((f) => `  - ${f}`),
            ...(stagedFiles.length > 10
              ? [`  ... 及其他 ${stagedFiles.length - 10} 个文件`]
              : []),
            "",
            "请确认：",
            "- 用户是否已明确授权提交？（git-conventions 铁律：禁止自动 commit/push）",
            "- 代码是否已通过 Kyle 两阶段审查？",
            "",
            "如果用户已授权且审查已通过，可以继续提交。",
          ].join("\n"),
        })
      );
    } else {
      console.log(JSON.stringify({}));
    }
  } catch {
    console.log(JSON.stringify({}));
  }
}

main();
