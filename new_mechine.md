
בנוסף, NVIDIA Container Toolkit לא היה מותקן. התקנו אותו והגדרנו את Docker להשתמש ב־NVIDIA:

```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```
בדקנו שה־GPU נגיש מתוך קונטיינר:
```bash

docker run --rm --gpus all ubuntu:24.04 nvidia-smi
```



יצירת CONTAINER vllm/vllm-openai:
```bash

docker run -d \
  --name qwen-api \
  --gpus all \
  --restart unless-stopped \
  --shm-size 2g \
  -p 127.0.0.1:8000:8000 \
  -v qwen-hf-cache:/root/.cache/huggingface \
  vllm/vllm-openai:latest \
  Qwen/Qwen3-4B-AWQ \
  --quantization awq \
  --dtype half \
  --gpu-memory-utilization 0.80 \
  --max-model-len 4096 \
  --max-num-seqs 4 \
  --enforce-eager


```

LOGS
``bash

docker logs --tail 80 qwen-api

```

RUN TEST

```bash
curl -fsS http://127.0.0.1:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "Qwen/Qwen3-4B-AWQ",
    "messages": [
      {"role": "user", "content": "כתוב שלום בעברית"}
    ],
    "max_tokens": 100,
    "temperature": 0,
    "chat_template_kwargs": {"enable_thinking": false}
  }'


```



