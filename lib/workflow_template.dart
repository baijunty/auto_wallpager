final template = {
  "client_id": "b92d48cce2ab485a933cb6868ce71093",
  "prompt": {
    "62": {
      "inputs": {"model": "dart-v2-moe-sft"},
      "class_type": "DanbooruTagsTransformerLoader",
      "_meta": {"title": "Dart Load"},
    },
    "63": {
      "inputs": {
        "copyright": "",
        "character": "",
        "rating": "general",
        "aspect_ratio": "wide",
        "length": "long",
        "general": "1girl,solo",
        "identity": "none",
      },
      "class_type": "DanbooruTagsTransformerComposePromptV2",
      "_meta": {"title": "Dart Compose Prompt V2"},
    },
    "64": {
      "inputs": {
        "prompt": ["63", 0],
        "seed": 3534491517,
        "ban_tags": "",
        "model": ["62", 0],
        "tokenizer": ["62", 1],
      },
      "class_type": "DanbooruTagsTransformerGenerateAdvanced",
      "_meta": {"title": "Dart Generate(Advanced)"},
    },
    "65": {
      "inputs": {
        "skip_special_tokens": true,
        "tokenizer": ["62", 1],
        "token_ids": ["64", 0],
      },
      "class_type": "DanbooruTagsTransformerDecode",
      "_meta": {"title": "Dart Decode"},
    },
    "67": {
      "inputs": {
        "names": "",
        "images": ["70", 0],
      },
      "class_type": "Image2Base64",
      "_meta": {"title": "Image to Base64"},
    },
    "69": {
      "inputs": {
        "text": ["67", 0],
      },
      "class_type": "ShowText|pysssss",
      "_meta": {"title": "Show Text 🐍"},
    },
    "70": {
      "inputs": {
        "upscale_model": ["71", 0],
        "image": ["57:8", 0],
      },
      "class_type": "ImageUpscaleWithModel",
      "_meta": {"title": "使用模型放大图像"},
    },
    "71": {
      "inputs": {"model_name": "4x-AnimeSharp.pth"},
      "class_type": "UpscaleModelLoader",
      "_meta": {"title": "加载放大模型"},
    },
    "57:30": {
      "inputs": {
        "clip_name": "qwen3-4b.safetensors",
        "type": "lumina2",
        "device": "default",
      },
      "class_type": "CLIPLoader",
      "_meta": {"title": "加载CLIP"},
    },
    "57:29": {
      "inputs": {"vae_name": "ae.safetensors"},
      "class_type": "VAELoader",
      "_meta": {"title": "加载VAE"},
    },
    "57:33": {
      "inputs": {
        "conditioning": ["57:27", 0],
      },
      "class_type": "ConditioningZeroOut",
      "_meta": {"title": "条件零化"},
    },
    "57:8": {
      "inputs": {
        "samples": ["57:3", 0],
        "vae": ["57:29", 0],
      },
      "class_type": "VAEDecode",
      "_meta": {"title": "VAE解码"},
    },
    "57:28": {
      "inputs": {
        "unet_name": "z-anime-distill-8step-aio-fp8.safetensors",
        "weight_dtype": "default",
      },
      "class_type": "UNETLoader",
      "_meta": {"title": "UNet加载器"},
    },
    "57:27": {
      "inputs": {
        "text": ["65", 0],
        "clip": ["57:30", 0],
      },
      "class_type": "CLIPTextEncode",
      "_meta": {"title": "CLIP文本编码"},
    },
    "57:13": {
      "inputs": {"width": 1280, "height": 720, "batch_size": 1},
      "class_type": "EmptySD3LatentImage",
      "_meta": {"title": "空Latent图像（SD3）"},
    },
    "57:3": {
      "inputs": {
        "seed": 267523856486707,
        "steps": 8,
        "cfg": 1,
        "sampler_name": "res_multistep",
        "scheduler": "simple",
        "denoise": 1,
        "model": ["57:11", 0],
        "positive": ["57:27", 0],
        "negative": ["57:33", 0],
        "latent_image": ["57:13", 0],
      },
      "class_type": "KSampler",
      "_meta": {"title": "K采样器"},
    },
    "57:11": {
      "inputs": {
        "shift": 3,
        "model": ["57:28", 0],
      },
      "class_type": "ModelSamplingAuraFlow",
      "_meta": {"title": "采样算法（AuraFlow）"},
    },
  },
};
