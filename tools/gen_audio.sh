#!/usr/bin/env bash
# Generate HackerQuest's themed SFX + music with the ElevenLabs API.
#
#   export ELEVENLABS_API_KEY=sk_...
#   ./tools/gen_audio.sh            # everything (sfx + music)
#   ./tools/gen_audio.sh sfx        # just sound effects (cheap, fast)
#   ./tools/gen_audio.sh music      # just the music loops
#   ./tools/gen_audio.sh sfx hit    # regenerate a single sfx by name
#
# Files land in assets/audio/{sfx,music}/<name>.mp3 — exactly where Audio
# (scripts/audio.gd) loads them. Re-run any time to retune a prompt; existing
# files are overwritten. Open the project in Godot afterward so it imports them.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY first (export ELEVENLABS_API_KEY=sk_...)}"
API="https://api.elevenlabs.io/v1"
FMT="mp3_44100_128"

# name|duration_seconds|prompt   (cyberpunk hacker vibe; keep prompts apostrophe-free)
SFX=(
  "bust|1.6|harsh digital alarm error buzzer, system breach detected, menacing"
  "alarm|2.0|rising cyberpunk siren alert, intrusion trace detected, tense pulsing"
  "escape|1.0|quick upward digital whoosh, connection dropped, clean getaway"
  "sleep|2.2|soft warm ambient synth chime, fade to black, calm night rest"
  "gig|0.7|short pleasant retro-computer confirm blip, task accepted"
  "hack_ok|1.2|satisfying glitchy unlock success chime, access granted"
  "hack_fail|0.9|negative denied error buzz, access denied, short"
  "ui_open|0.5|subtle holographic interface panel open click, soft"
  "hit|0.5|punchy digital glitch impact, data attack"
  "win|1.6|triumphant short cyberpunk victory sting, bright synth"
  "lose|1.6|somber descending failure tone, system shutdown"
  "levelup|1.6|bright ascending arpeggio level up flourish, synth"
  "cash|0.8|digital credits payout, pleasant cha-ching cash register, retro"
  "click|0.5|crisp short UI button tap blip, holographic interface"
  "search|1.3|rummaging through a pile of trash and e-waste, plastic and metal clatter, digging"
  "travel|1.2|quick digital whoosh transition, fast travel across the city, synth sweep"
  "riot_sting|1.6|menacing rival hacker arrival sting, distorted glitch synth stab, villain signature motif, aggressive cyber, dramatic"
  "crew_sting|1.0|short dark glitch enemy appears cue, cyber crew enforcer arrives, tense synth stab"
  "riot_down|1.8|heavy triumphant cyberpunk boss defeated sting, rival process terminated, distorted synth fanfare collapsing into static, dramatic"
  "crew_down|1.2|short cyber enemy defeated sting, crew member knocked offline, glitchy synth downfall"
)

# name|length_ms|prompt   (instrumental loops)
MUSIC=(
  "title|30000|dark synthwave cyberpunk main theme, brooding neon atmosphere, slow driving beat, looping"
  "city|40000|chill cyberpunk lo-fi beat, rainy neon street ambience, relaxed late night, looping"
  "corp|32000|cold corporate synth ambience, sterile clean tension, cyberpunk, looping"
  "darknet|32000|dark glitchy underground darknet ambience, mysterious low pulse, looping"
  "drowned|40000|endgame submerged cyberpunk descent, deep ominous synth drone, distant detuned choir pads, slow climactic pulse beneath black water, glitchy data whispers, haunting and final, looping"
  "riot_boss|40000|intense endgame cyberpunk boss battle theme, aggressive distorted synth bass, glitchy breakbeat drums, menacing rival hacker showdown, dark driving arpeggios, high stakes, looping"
  "battle|32000|fast driving cyberpunk combat music, tense electronic battle, pulsing synth bassline, urgent arpeggios, neon hacker duel, adrenaline, looping"
)

json_escape() { python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$1"; }

gen_sfx() {
  local name="$1" dur="$2" prompt="$3"
  echo "  sfx/$name.mp3  ($dur s)"
  curl -fsS -X POST "$API/sound-generation?output_format=$FMT" \
    -H "xi-api-key: $ELEVENLABS_API_KEY" -H "Content-Type: application/json" \
    -d "{\"text\": $(json_escape "$prompt"), \"duration_seconds\": $dur, \"prompt_influence\": 0.4}" \
    -o "assets/audio/sfx/$name.mp3"
}

gen_music() {
  local name="$1" len="$2" prompt="$3"
  echo "  music/$name.mp3  ($len ms)"
  curl -fsS -X POST "$API/music?output_format=$FMT" \
    -H "xi-api-key: $ELEVENLABS_API_KEY" -H "Content-Type: application/json" \
    -d "{\"prompt\": $(json_escape "$prompt"), \"music_length_ms\": $len, \"force_instrumental\": true}" \
    -o "assets/audio/music/$name.mp3"
}

WHAT="${1:-all}"
ONLY="${2:-}"

if [[ "$WHAT" == "all" || "$WHAT" == "sfx" ]]; then
  echo "Generating SFX..."
  for row in "${SFX[@]}"; do
    IFS='|' read -r n d p <<< "$row"
    [[ -n "$ONLY" && "$ONLY" != "$n" ]] && continue
    gen_sfx "$n" "$d" "$p"
  done
fi

if [[ "$WHAT" == "all" || "$WHAT" == "music" ]]; then
  echo "Generating music (slower)..."
  for row in "${MUSIC[@]}"; do
    IFS='|' read -r n l p <<< "$row"
    [[ -n "$ONLY" && "$ONLY" != "$n" ]] && continue
    gen_music "$n" "$l" "$p"
  done
fi

echo "Done. Open the project in Godot so it imports the new audio."
