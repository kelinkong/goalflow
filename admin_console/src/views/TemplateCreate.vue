<template>
  <div class="page">
    <nav class="navbar">
      <div class="navbar-brand">🎯 GoalFlow Admin</div>
      <div class="navbar-menu">
        <router-link to="/dashboard">仪表盘</router-link>
        <router-link to="/users">用户</router-link>
        <router-link to="/templates">模板审核</router-link>
        <router-link to="/templates/create" class="active">创建模板</router-link>
        <router-link to="/logs">日志</router-link>
        <a @click="handleLogout" style="cursor: pointer;">退出</a>
      </div>
    </nav>

    <div class="container">
      <div class="header">
        <div>
          <h1>创建模板</h1>
          <p>直接粘贴模板 JSON，校验通过后保存为模板。</p>
        </div>
        <router-link to="/templates" class="btn-secondary">返回模板审核</router-link>
      </div>

      <div v-if="error" class="message error">{{ error }}</div>
      <div v-if="success" class="message success">{{ success }}</div>

      <div class="card">
        <div class="card-header">
          <h2>模板 JSON</h2>
          <div class="actions">
            <button class="btn-secondary" @click="fillExample">填充示例</button>
            <button class="btn-secondary" @click="formatJson">格式化</button>
          </div>
        </div>

        <textarea
          v-model="jsonText"
          class="editor"
          spellcheck="false"
          placeholder='{
  "name": "英语四级 30 天冲刺",
  "description": "适合基础一般的备考者",
  "totalDays": 30,
  "visibility": "PRIVATE",
  "tags": "英语四级,备考,阅读,听力",
  "taskPlan": [["任务1", "任务2"]]
}'
        ></textarea>

        <div class="hint">
          <div>必填字段：`name`、`description`、`totalDays`、`visibility`、`tags`、`taskPlan`</div>
          <div>`taskPlan` 必须是二维数组，外层表示天数，内层表示当天任务列表。</div>
        </div>

        <div class="submit-row">
          <button class="btn-primary" :disabled="submitting" @click="submitTemplate">
            {{ submitting ? '创建中...' : '创建模板' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api'

const router = useRouter()
const jsonText = ref('')
const error = ref('')
const success = ref('')
const submitting = ref(false)

const examplePayload = {
  name: '英语四级 30 天冲刺',
  description: '适合基础一般、每天可投入 30 分钟左右的备考者，重点推进词汇、阅读、听力和复盘。',
  totalDays: 7,
  visibility: 'PRIVATE',
  tags: '英语四级,备考,阅读,听力',
  taskPlan: [
    ['梳理四级题型结构并标出薄弱项', '准备词汇、真题和错题记录工具'],
    ['完成一次词汇巩固并整理易混词', '做一篇阅读训练并复盘错因'],
    ['精听一段短对话并记录没听懂的点', '整理今天学到的表达和句型'],
    ['完成一次专项训练并补充错题清单', '复盘前三天任务完成情况'],
    ['限时完成一篇阅读并复盘节奏', '围绕高频词汇做应用练习'],
    ['完成一次听力训练并总结常错点', '输出一页复盘笔记'],
    ['做一次阶段小测并统计薄弱项', '根据结果写下下一阶段调整动作']
  ]
}

const parsePayload = () => {
  let payload
  try {
    payload = JSON.parse(jsonText.value)
  } catch {
    throw new Error('JSON 格式无效，请检查括号、引号和逗号')
  }

  const requiredFields = ['name', 'description', 'totalDays', 'visibility', 'tags', 'taskPlan']
  for (const field of requiredFields) {
    if (!(field in payload)) {
      throw new Error(`缺少字段：${field}`)
    }
  }

  if (!Array.isArray(payload.taskPlan) || payload.taskPlan.length === 0) {
    throw new Error('taskPlan 必须是非空二维数组')
  }

  if (typeof payload.totalDays !== 'number' || payload.totalDays <= 0) {
    throw new Error('totalDays 必须是大于 0 的数字')
  }

  if (payload.totalDays !== payload.taskPlan.length) {
    throw new Error('totalDays 必须和 taskPlan 的天数一致')
  }

  for (let i = 0; i < payload.taskPlan.length; i += 1) {
    const dayTasks = payload.taskPlan[i]
    if (!Array.isArray(dayTasks) || dayTasks.length === 0) {
      throw new Error(`第 ${i + 1} 天的任务必须是非空数组`)
    }
    if (dayTasks.some(task => typeof task !== 'string' || !task.trim())) {
      throw new Error(`第 ${i + 1} 天包含空任务或非字符串任务`)
    }
  }

  payload.visibility = String(payload.visibility || '').toUpperCase()
  if (!['PRIVATE', 'PUBLIC'].includes(payload.visibility)) {
    throw new Error('visibility 只能是 PRIVATE 或 PUBLIC')
  }

  return payload
}

const fillExample = () => {
  jsonText.value = JSON.stringify(examplePayload, null, 2)
  error.value = ''
  success.value = ''
}

const formatJson = () => {
  try {
    const payload = parsePayload()
    jsonText.value = JSON.stringify(payload, null, 2)
    error.value = ''
  } catch (err) {
    error.value = err.message || 'JSON 格式化失败'
  }
}

const submitTemplate = async () => {
  error.value = ''
  success.value = ''

  let payload
  try {
    payload = parsePayload()
  } catch (err) {
    error.value = err.message || '模板校验失败'
    return
  }

  submitting.value = true
  try {
    const response = await api.post('/templates', payload)
    const status = response.data?.status
    success.value = status === 'PENDING'
      ? '模板已创建并进入审核队列'
      : '模板创建成功'
    jsonText.value = JSON.stringify(response.data, null, 2)
  } catch (err) {
    error.value = err.response?.data?.message || '模板创建失败，请稍后重试'
  } finally {
    submitting.value = false
  }
}

const handleLogout = () => {
  localStorage.removeItem('token')
  router.push('/login')
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  background: #f5f7fb;
}

.navbar {
  background: white;
  padding: 15px 30px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.navbar-brand {
  font-size: 20px;
  font-weight: bold;
  color: #667eea;
}

.navbar-menu {
  display: flex;
  gap: 20px;
}

.navbar-menu a,
.navbar-menu .router-link-active {
  text-decoration: none;
  color: #666;
  padding: 8px 16px;
  border-radius: 6px;
  transition: all 0.3s;
}

.navbar-menu a:hover,
.navbar-menu .router-link-active,
.navbar-menu a.active {
  background: #667eea;
  color: white;
}

.container {
  max-width: 1100px;
  margin: 0 auto;
  padding: 32px 24px 48px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  margin-bottom: 20px;
}

.header h1 {
  margin: 0 0 8px;
  color: #333;
}

.header p {
  margin: 0;
  color: #666;
}

.card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  margin-bottom: 16px;
}

.card-header h2 {
  margin: 0;
}

.actions {
  display: flex;
  gap: 10px;
}

.editor {
  width: 100%;
  min-height: 520px;
  padding: 16px;
  border: 1px solid #d8deea;
  border-radius: 10px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 14px;
  line-height: 1.6;
  resize: vertical;
  box-sizing: border-box;
}

.editor:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.12);
}

.hint {
  margin-top: 14px;
  color: #666;
  font-size: 13px;
  line-height: 1.7;
}

.submit-row {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}

.btn-primary,
.btn-secondary {
  border: none;
  border-radius: 8px;
  padding: 10px 16px;
  font-size: 14px;
  cursor: pointer;
}

.btn-primary {
  background: #667eea;
  color: white;
}

.btn-primary:disabled {
  cursor: not-allowed;
  opacity: 0.65;
}

.btn-secondary {
  background: #eef2ff;
  color: #4c5bd4;
  text-decoration: none;
}

.message {
  border-radius: 10px;
  padding: 12px 14px;
  margin-bottom: 16px;
}

.message.error {
  background: #fff1f1;
  color: #c0392b;
  border: 1px solid #f5c2c2;
}

.message.success {
  background: #eefaf1;
  color: #1e8e3e;
  border: 1px solid #c6ebd0;
}
</style>
