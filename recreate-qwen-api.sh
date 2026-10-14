#!/usr/bin/env bash
# recreate-qwen-api.sh — מקים מחדש את qwen-api עם --max-model-len 8192.
# אותם פרמטרים בדיוק כמו היום (מתוך docker inspect), שינוי אחד בלבד.
# הקונטיינר הישן נשמר בשם qwen-api-old לחזרה מהירה.
set -euo pipefail

NAME=qwen-api
OLD=qwen-api-old
IMAGE=vllm/vllm-openai:latest      # אותו image מקומי, בלי pull
MAX_LEN=8192

TS="$(date +%Y%m%d-%H%M%S)"
mkdir -p ~/qwen-backup
sudo docker inspect "$NAME" > ~/qwen-backup/qwen-api.inspect.$TS.json
echo "backup: ~/qwen-backup/qwen-api.inspect.$TS.json"

sudo docker rm -f "$OLD" 2>/dev/null || true
sudo docker stop "$NAME"
sudo docker rename "$NAME" "$OLD"

sudo docker run -d --name "$NAME" \
  --gpus all \
  -p 127.0.0.1:8000:8000 \
  --shm-size 2g \
  --restart unless-stopped \
  -v qwen-hf-cache:/root/.cache/huggingface \
  "$IMAGE" \
  Qwen/Qwen3-4B-AWQ \
  --quantization awq \
  --dtype half \
  --gpu-memory-utilization 0.80 \
  --max-model-len "$MAX_LEN" \
  --max-num-seqs 4 \
  --enforce-eager

echo "waiting for vLLM..."
for i in $(seq 1 60); do
  if curl -sf localhost:8000/v1/models >/dev/null; then
    curl -s localhost:8000/v1/models | python3 -c 'import sys,json; m=json.load(sys.stdin)["data"][0]; print("OK", m["id"], "max_model_len =", m["max_model_len"])'
    exit 0
  fi
  if [ "$(sudo docker inspect -f '{{.State.Running}}' "$NAME")" != "true" ]; then break; fi
  sleep 5
done

echo "vLLM did not come up — last log lines:"
sudo docker logs --tail 30 "$NAME"
echo
echo "rollback:  sudo docker rm -f $NAME && sudo docker rename $OLD $NAME && sudo docker start $NAME"
exit 1
