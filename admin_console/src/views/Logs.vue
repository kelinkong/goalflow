<template>
  <div class="logs-page">
    <nav class="navbar">
      <div class="navbar-brand">🎯 GoalFlow Admin</div>
      <div class="navbar-menu">
        <router-link to="/dashboard">仪表盘</router-link>
        <router-link to="/users">用户</router-link>
        <router-link to="/templates">模板审核</router-link>
        <router-link to="/logs" class="active">日志</router-link>
        <a @click="handleLogout" style="cursor: pointer;">退出</a>
      </div>
    </nav>

    <div class="container">
      <h1>📜 系统日志</h1>
      
      <div class="card">
        <div class="card-header">
          <h2>后端运行日志 (goalflow-api)</h2>
          <div class="controls">
            <label>显示行数：</label>
            <select v-model="lines" @change="loadLogs">
              <option :value="50">50 行</option>
              <option :value="100">100 行</option>
              <option :value="200">200 行</option>
              <option :value="500">500 行</option>
            </select>
            <button @click="loadLogs" class="btn-refresh">🔄 刷新日志</button>
          </div>
        </div>
        <div class="card-body">
          <div class="log-container">
            <div v-if="loading" class="log-line">加载中...</div>
            <div v-else-if="error" class="log-line error">{{ error }}</div>
            <div v-else>
              <div 
                v-for="(line, index) in logLines" 
                :key="index" 
                class="log-line"
                :class="getLogLevelClass(line)"
              >
                {{ line }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api'

const router = useRouter()
const lines = ref(100)
const logLines = ref([])
const loading = ref(false)
const error = ref('')

onMounted(() => {
  loadLogs()
})

const loadLogs = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const response = await api.get(`/admin/logs?lines=${lines.value}`)
    const data = response.data
    
    if (data.success) {
      logLines.value = data.logs.split('\n').filter(line => line.trim())
    } else {
      error.value = data.logs || '加载失败'
    }
  } catch (err) {
    error.value = '加载日志失败：' + err.message
  } finally {
    loading.value = false
  }
}

const getLogLevelClass = (line) => {
  if (line.includes('ERROR')) return 'error'
  if (line.includes('WARN')) return 'warn'
  if (line.includes('DEBUG')) return 'debug'
  return 'info'
}

const handleLogout = () => {
  localStorage.removeItem('token')
  router.push('/login')
}
</script>

<style scoped>
.navbar {
  background: white;
  padding: 15px 30px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
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

.navbar-menu a, .navbar-menu .router-link-active {
  text-decoration: none;
  color: #666;
  padding: 8px 16px;
  border-radius: 6px;
  transition: all 0.3s;
}

.navbar-menu a:hover, .navbar-menu .router-link-active {
  background: #667eea;
  color: white;
}

.container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 30px;
}

.container h1 {
  color: #333;
  font-size: 28px;
  margin-bottom: 30px;
}

.card {
  background: white;
  border-radius: 10px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  overflow: hidden;
}

.card-header {
  padding: 20px;
  border-bottom: 1px solid #eee;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-header h2 {
  font-size: 18px;
  color: #333;
}

.controls {
  display: flex;
  align-items: center;
  gap: 10px;
}

.controls select {
  padding: 8px 12px;
  border: 2px solid #e0e0e0;
  border-radius: 6px;
}

.btn-refresh {
  padding: 8px 16px;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

.btn-refresh:hover {
  background: #5568d3;
}

.card-body {
  padding: 20px;
}

.log-container {
  background: #1e1e1e;
  color: #d4d4d4;
  padding: 20px;
  border-radius: 6px;
  font-family: 'Courier New', monospace;
  font-size: 12px;
  line-height: 1.6;
  max-height: 600px;
  overflow-y: auto;
}

.log-line {
  margin-bottom: 4px;
  white-space: pre-wrap;
  word-break: break-all;
}

.log-line.info {
  color: #4ec9b0;
}

.log-line.warn {
  color: #cca700;
}

.log-line.error {
  color: #f44747;
}

.log-line.debug {
  color: #569cd6;
}
</style>
