import json

log_file = "/Users/akhandpratapsingh/.gemini/antigravity/brain/2b46d7aa-2dcb-4da1-8c76-49b2892fb06f/.system_generated/logs/transcript_full.jsonl"

for line in open(log_file):
    try:
        data = json.loads(line)
        if "tool_calls" in data:
            for call in data["tool_calls"]:
                if call["name"] in ["replace_file_content", "multi_replace_file_content", "write_to_file"]:
                    args = call["args"]
                    target = args.get("TargetFile", "")
                    if "HomeView.swift" in target or "StaffView.swift" in target:
                        print(f"Step {data.get('step_index')}: {call['name']} on {target}")
                        if "Description" in args:
                            print(f"Description: {args['Description']}")
                        elif "Instruction" in args:
                            print(f"Instruction: {args['Instruction']}")
    except Exception as e:
        pass
