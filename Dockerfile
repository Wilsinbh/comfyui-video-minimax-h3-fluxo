# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base

# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""

# install custom nodes into comfyui
RUN git clone https://github.com/kijai/ComfyUI-KJNodes /comfyui/custom_nodes/ComfyUI-KJNodes && cd /comfyui/custom_nodes/ComfyUI-KJNodes && (git checkout c2a47f161bdcecc1e6baf3412f1d116febc26ce3 2>/dev/null || (git fetch origin c2a47f161bdcecc1e6baf3412f1d116febc26ce3 --depth=1 && git checkout c2a47f161bdcecc1e6baf3412f1d116febc26ce3) || echo "WARN: commit c2a47f161bdcecc1e6baf3412f1d116febc26ce3 unreachable in https://github.com/kijai/ComfyUI-KJNodes, falling back to default branch HEAD")

# instala sageattn3 (wheel pré-compilado, torch2.10.0+cu130, Blackwell sm_120)
# este arquivo NAO estava no pod antigo, entao ainda precisa vir do HF
RUN pip install --no-cache-dir "huggingface_hub[cli]" && \
    HF_TOKEN=$HF_TOKEN hf download Seryoger/Sageattention-3-cu130-5090-endpoint \
    sageattn3-1.0.0-cp312-cp312-linux_x86_64.whl --local-dir /tmp/sageattn3 && \
    pip install --no-cache-dir /tmp/sageattn3/*.whl && \
    rm -rf /tmp/sageattn3

# copia os modelos que ja estao locais no repo (copiados do pod antigo antes do build)
# em vez de baixar de novo do Hugging Face
COPY models/unet/minimax_h3_fl2va_pruned_int8_convrot.safetensors /comfyui/models/unet/
COPY models/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors /comfyui/models/text_encoders/
COPY models/vae/minimax_h3_video_vae_fp16.safetensors /comfyui/models/vae/
COPY models/vae/minimax_h3_audio_vae_fp32.safetensors /comfyui/models/vae/

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/
