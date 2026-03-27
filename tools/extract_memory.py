#!/usr/bin/env python3
"""Extract key facts from Claude Code transcript → homeos.knowledge format"""
import json, sys, re
from datetime import datetime

TRANSCRIPT = "/home/lupin/.claude/projects/-home-lupin/2b576cb9-b677-4045-8c64-492a89439a4c.jsonl"
OUTPUT = "/home/lupin/Origin/nox_brain_extract.txt"

def extract_text(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for c in content:
            if isinstance(c, dict) and c.get('type') == 'text':
                parts.append(c.get('text', ''))
        return '\n'.join(parts)
    return ''

def is_significant(text):
    """Filter for significant messages"""
    if len(text) < 10:
        return False
    # Skip system/command messages
    if text.startswith('<') or text.startswith('/'):
        return False
    return True

# Extract user messages (what Lupin said)
user_msgs = []
assistant_summaries = []
timestamps = []

with open(TRANSCRIPT) as f:
    for line in f:
        d = json.loads(line)

        if d.get('type') == 'user':
            msg = d.get('message', {})
            text = extract_text(msg.get('content', ''))
            ts = msg.get('timestamp', '')
            if is_significant(text) and len(text) < 200:
                user_msgs.append((ts, text.strip()[:150]))

        elif d.get('type') == 'assistant':
            msg = d.get('message', {})
            text = extract_text(msg.get('content', ''))
            # Extract key achievements (lines with ✅, PASS, fix, feat)
            for line_text in text.split('\n'):
                line_text = line_text.strip()
                if any(kw in line_text for kw in ['✅', 'PASS', 'ALL PASS', 'pushed', 'Pushed']):
                    if 20 < len(line_text) < 150:
                        assistant_summaries.append(line_text)

# Write extracted facts
with open(OUTPUT, 'w') as f:
    f.write("# Nox Brain Extract — from transcript\n")
    f.write(f"# Extracted: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n")
    f.write(f"# User messages: {len(user_msgs)}\n")
    f.write(f"# Key events: {len(assistant_summaries)}\n\n")

    f.write("## Lupin's words (chronological)\n")
    for ts, msg in user_msgs[:100]:  # First 100 significant messages
        f.write(f"- {msg}\n")

    f.write(f"\n## Key achievements\n")
    seen = set()
    for s in assistant_summaries:
        clean = s.strip('- ●*')[:120]
        if clean not in seen:
            seen.add(clean)
            f.write(f"- {clean}\n")

print(f"Extracted {len(user_msgs)} user messages, {len(assistant_summaries)} events")
print(f"Output: {OUTPUT}")
