final htmlTemplate = """
<!DOCTYPE html>
<html lang="zh">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>自动壁纸配置</title>
    <style>
        :root {
            --primary-color: #4361ee;
            --secondary-color: #3f37c9;
            --success-color: #4cc9f0;
            --danger-color: #f72585;
            --warning-color: #f8961e;
            --light-color: #f8f9fa;
            --dark-color: #212529;
            --border-radius: 8px;
            --box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            --transition: all 0.3s ease;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        .container {
            width: 100%;
            max-width: 800px;
            background: rgba(255, 255, 255, 0.95);
            border-radius: var(--border-radius);
            box-shadow: var(--box-shadow);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(to right, var(--primary-color), var(--secondary-color));
            color: white;
            padding: 25px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2rem;
            margin-bottom: 10px;
        }
        
        .header p {
            opacity: 0.9;
        }
        
        .form-container {
            padding: 30px;
        }
        
        .form-group {
            margin-bottom: 25px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: var(--dark-color);
        }
        
        .form-control {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e2e8f0;
            border-radius: var(--border-radius);
            font-size: 16px;
            transition: var(--transition);
        }
        
        .form-control:focus {
            outline: none;
            border-color: var(--primary-color);
            box-shadow: 0 0 0 3px rgba(67, 97, 238, 0.2);
        }
        
        select.form-control {
            appearance: none;
            background-image: url("data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3e%3cpolyline points='6 9 12 15 18 9'%3e%3c/polyline%3e%3c/svg%3e");
            background-repeat: no-repeat;
            background-position: right 1rem center;
            background-size: 1em;
        }
        
        .checkbox-group {
            display: flex;
            align-items: center;
        }
        
        .checkbox-group input[type="checkbox"] {
            margin-right: 10px;
            transform: scale(1.3);
        }
        
        .btn {
            display: inline-block;
            font-weight: 600;
            text-align: center;
            white-space: nowrap;
            vertical-align: middle;
            user-select: none;
            border: none;
            padding: 12px 30px;
            font-size: 16px;
            border-radius: var(--border-radius);
            transition: var(--transition);
            cursor: pointer;
        }
        
        .btn-primary {
            background-color: var(--primary-color);
            color: white;
        }
        
        .btn-primary:hover {
            background-color: var(--secondary-color);
            transform: translateY(-2px);
            box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
        }
        
        .btn-block {
            display: block;
            width: 100%;
        }
        
        .card {
            border: 1px solid #e2e8f0;
            border-radius: var(--border-radius);
            padding: 20px;
            margin-top: 20px;
            background-color: #f8f9fa;
        }
        
        .card-title {
            font-size: 1.2rem;
            margin-bottom: 15px;
            color: var(--dark-color);
            border-bottom: 1px solid #dee2e6;
            padding-bottom: 10px;
        }
        
        .form-row {
            display: flex;
            flex-wrap: wrap;
            margin: 0 -10px;
        }
        
        .form-col {
            flex: 1;
            padding: 0 10px;
            min-width: 250px;
        }
        
        .form-col-full {
            width: 100%;
            padding: 0 10px;
        }
        
        @media (max-width: 768px) {
            .form-col {
                min-width: 100%;
                margin-bottom: 15px;
            }
            
            .form-container {
                padding: 20px;
            }
        }
        
        .loading {
            display: none;
            text-align: center;
            padding: 20px;
        }
        
        .spinner {
            border: 4px solid rgba(0, 0, 0, 0.1);
            border-left-color: var(--primary-color);
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 15px;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>自动壁纸配置</h1>
            <p>设置您的个性化壁纸生成参数</p>
        </div>
        
        <div class="form-container">
            <form id="configForm">
                <div class="form-group">
                    <label for="address">服务器地址</label>
                    <input type="text" class="form-control" id="address" name="address" placeholder="例如: http://127.0.0.1:8188">
                </div>
                
                <div class="form-group">
                    <label for="authorization">Authorization</label>
                    <input type="text" class="form-control" id="authorization" name="authorization" placeholder="例如: Bearer your-token-here">
                </div>
                
                <div class="form-group">
                    <label for="duration">切换间隔(分钟)</label>
                    <input type="number" class="form-control" id="duration" name="duration" min="1" placeholder="例如: 5">
                </div>
                
                <div class="form-row">
                    <div class="form-col">
                        <div class="form-group">
                            <label for="width">宽度</label>
                            <input type="number" class="form-control" id="width" name="width" min="1" placeholder="例如: 1366">
                        </div>
                    </div>
                    
                    <div class="form-col">
                        <div class="form-group">
                            <label for="height">高度</label>
                            <input type="number" class="form-control" id="height" name="height" min="1" placeholder="例如: 768">
                        </div>
                    </div>
                </div>
                
                <div class="form-row">
                    <div class="form-col">
                        <div class="form-group">
                            <label for="model">模型选择</label>
                            <select class="form-control" id="model" name="model">
                                <option value="">加载中...</option>
                            </select>
                        </div>
                    </div>
                    
                    <div class="form-col">
                        <div class="form-group">
                            <label for="tagModel">标签模型</label>
                            <select class="form-control" id="tagModel" name="tagModel">
                                <option value="dart-v2-sft">dart-v2-sft</option>
                                <option value="dart-v2-moe-sft">dart-v2-moe-sft</option>
                            </select>
                        </div>
                    </div>
                </div>
                
                <div class="form-row">
                    <div class="form-col">
                        <div class="form-group">
                            <label for="upscaleModel">放大模型</label>
                            <select class="form-control" id="upscaleModel" name="upscaleModel">
                                <option value="">加载中...</option>
                            </select>
                        </div>
                    </div>
                    
                    <div class="form-col">
                        <div class="form-group">
                            <label for="rating">评级设置</label>
                            <select class="form-control" id="rating" name="rating">
                                <option value="sfw">sfw</option>
                                <option value="general">General</option>
                                <option value="sensitive">Sensitive</option>
                                <option value="nsfw">NSFW</option>
                                <option value="questionable">Questionable</option>
                                <option value="explicit">Explicit</option>
                            </select>
                        </div>
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="blockTags">屏蔽标签 (多个标签请用逗号分隔)</label>
                    <input type="text" class="form-control" id="blockTags" name="blockTags" placeholder="例如: nsfw,bad anatomy,worst quality">
                </div>
                
                <div class="card">
                    <h3 class="card-title">目标设置</h3>
                    <div class="form-row">
                        <div class="form-col">
                            <div class="form-group">
                                <label for="targetName">名称</label>
                                <input type="text" class="form-control" id="targetName" name="targetName" placeholder="例如: 初音未来">
                            </div>
                        </div>
                        
                        <div class="form-col">
                            <div class="form-group">
                                <label for="targetSeries">系列</label>
                                <input type="text" class="form-control" id="targetSeries" name="targetSeries" placeholder="例如: VOCALOID">
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="form-group">
                    <div class="checkbox-group">
                        <input type="checkbox" id="releaseMemory" name="releaseMemory">
                        <label for="releaseMemory">生成图片后释放内存 (仅在需要时勾选)</label>
                    </div>
                </div>
                
                <button type="submit" class="btn btn-primary btn-block">保存配置</button>
            </form>
            
            <div class="loading" id="loading">
                <div class="spinner"></div>
                <p>正在保存配置...</p>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // 获取表单元素
            const form = document.getElementById('configForm');
            const loading = document.getElementById('loading');
            const modelSelect = document.getElementById('model');
            const authorization = document.getElementById('authorization');
            // 获取当前配置
            fetch('/config')
                .then(response => response.json())
                .then(function (config){
                    document.getElementById('address').value = config.address || '';
                    document.getElementById('duration').value = config.duration || 5;
                    document.getElementById('authorization').value = config.authorization || '';
                    document.getElementById('width').value = config.width || 1366;
                    document.getElementById('height').value = config.height || 768;
                    document.getElementById('tagModel').value = config.tag_model || 'dart-v2-moe-sft';
                    document.getElementById('upscaleModel').value = config.upscaleModel || '';
                    document.getElementById('rating').value = config.rating || 'general';
                    document.getElementById('blockTags').value = Array.isArray(config.block_tags) ? config.block_tags.join(', ') : '';
                        
                        if (config.target) {
                            document.getElementById('targetName').value = config.target.name || '';
                            document.getElementById('targetSeries').value = config.target.series || '';
                        }
                        
                        // 加载模型选项
                        loadModels(config.address || 'http://127.0.0.1:8188', config.model);
                        loadUpscaleModels(config.address || 'http://127.0.0.1:8188', config.upscaleModel);
                })
                .catch(error => {
                    console.error('获取配置失败:', error);
                    alert('获取配置失败，请手动填写');
                    loadModels('http://127.0.0.1:8188', null);
                });
            
            // 加载模型列表
            function loadModels(address, currentModel) {
                // 从地址中提取主机和端口
                let baseUrl = address;
                try {
                    const url = new URL(address);
                } catch (e) {
                    // 如果不是有效的URL，使用默认值
                    baseUrl = 'http://127.0.0.1:8188';
                }
                
                fetch(baseUrl + '/models/checkpoints', {headers: {"Authorization": authorization.value}})
                    .then(response => response.json())
                    .then(models => {
                        // 清空现有选项
                        modelSelect.innerHTML = '';
                        
                        // 添加空选项
                        const emptyOption = document.createElement('option');
                        emptyOption.value = '';
                        emptyOption.textContent = '请选择模型';
                        modelSelect.appendChild(emptyOption);
                        
                        // 添加模型选项
                        models.forEach(model => {
                            const option = document.createElement('option');
                            option.value = model;
                            option.textContent = model;
                            if (model === currentModel) {
                                option.selected = true;
                            }
                            modelSelect.appendChild(option);
                        });
                    })
                    .catch(error => {
                        console.error('加载模型列表失败:', error);
                        modelSelect.innerHTML = '<option value="">加载模型失败</option>';
                    });
            }
            
            // 加载放大模型列表
            function loadUpscaleModels(address, currentModel) {
                const upscaleModelSelect = document.getElementById('upscaleModel');
                
                // 从地址中提取主机和端口
                let baseUrl = address;
                try {
                    const url = new URL(address);
                } catch (e) {
                    // 如果不是有效的URL，使用默认值
                    baseUrl = 'http://127.0.0.1:8188';
                }
                
                fetch(baseUrl + '/models/upscale_models', {headers: {"Authorization": authorization.value}})
                    .then(response => response.json())
                    .then(models => {
                        // 清空现有选项
                        upscaleModelSelect.innerHTML = '';
                        
                        // 添加空选项
                        const emptyOption = document.createElement('option');
                        emptyOption.value = '';
                        emptyOption.textContent = '请选择放大模型';
                        upscaleModelSelect.appendChild(emptyOption);
                        
                        // 添加模型选项
                        models.forEach(model => {
                            const option = document.createElement('option');
                            option.value = model;
                            option.textContent = model;
                            if (model === currentModel) {
                                option.selected = true;
                            }
                            upscaleModelSelect.appendChild(option);
                        });
                    })
                    .catch(error => {
                        console.error('加载放大模型列表失败:', error);
                        upscaleModelSelect.innerHTML = '<option value="">加载放大模型失败</option>';
                    });
            }
            
            // 监听地址变化以重新加载模型
            document.getElementById('address').addEventListener('focusout', function() {
                const address = this.value.trim();
                if (address) {
                    loadModels(address, null);
                    loadUpscaleModels(address, null);
                }
            });
            
            // 表单提交处理
            form.addEventListener('submit', function(e) {
                e.preventDefault();
                
                // 显示加载状态
                loading.style.display = 'block';
                form.style.display = 'none';
                
                // 构造配置对象
                const formData = new FormData(form);
                const config = {
                    address: formData.get('address'),
                    duration: parseInt(formData.get('duration')) || 10,
                    authorization: formData.get('authorization') || '',
                    width: parseInt(formData.get('width')) || 1366,
                    height: parseInt(formData.get('height')) || 768,
                    model: formData.get('model') || undefined,
                    tag_model: formData.get('tagModel'),
                    upscaleModel: formData.get('upscaleModel') || '4x-AnimeSharp.pth',
                    rating: formData.get('rating'),
                    block_tags: formData.get('blockTags') ? 
                        formData.get('blockTags').split(',').map(tag => tag.trim()).filter(tag => tag) : [],
                    releaseMemory: formData.get('releaseMemory') !== null,
                };
                
                // 处理目标设置
                const targetName = formData.get('targetName');
                const targetSeries = formData.get('targetSeries');
                if (targetName || targetSeries) {
                    config.target = {
                        name: targetName || '',
                        series: targetSeries || ''
                    };
                }
                
                // 发送配置更新请求
                fetch('/setting', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(config)
                })
                .then(response => {
                    if (response.ok) {
                        return response.json();
                    }
                    throw new Error('保存失败');
                })
                .then(data => {
                    alert('配置保存成功！');
                })
                .catch(error => {
                    console.error('保存配置失败:', error);
                    alert('保存配置失败: ' + error.message);
                })
                .finally(() => {
                    // 恢复表单显示
                    loading.style.display = 'none';
                    form.style.display = 'block';
                });
            });
        });
    </script>
</body>
</html>
""";
