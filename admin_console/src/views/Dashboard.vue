<template>
  <div class="dashboard">
    <nav class="navbar">
      <div class="navbar-brand">🎯 GoalFlow Admin</div>
      <div class="navbar-menu">
        <router-link to="/dashboard" class="active">仪表盘</router-link>
        <router-link to="/users">用户管理</router-link>
        <router-link to="/logs">系统日志</router-link>
        <a @click="handleLogout" style="cursor: pointer;">退出登录</a>
      </div>
    </nav>

    <div class="container">
      <h1>📊 系统数据概览</h1>
      
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon">👥</div>
          <div class="stat-value">{{ stats.totalUsers || 0 }}</div>
          <div class="stat-label">总注册用户</div>
        </div>
        
        <div class="stat-card">
          <div class="stat-icon">🎯</div>
          <div class="stat-value">{{ stats.totalGoals || 0 }}</div>
          <div class="stat-label">活跃目标数</div>
        </div>
        
        <div class="stat-card">
          <div class="stat-icon">🔄</div>
          <div class="stat-value">{{ stats.totalHabits || 0 }}</div>
          <div class="stat-label">正在坚持的习惯</div>
        </div>
        
        <div class="stat-card">
          <div class="stat-icon">📝</div>
          <div class="stat-value">{{ stats.totalReviews || 0 }}</div>
          <div class="stat-label">累计复盘次数</div>
        </div>
      </div>

      <div class="content-grid">
        <div class="card">
          <div class="card-header">
            <h2>🆕 最近注册用户</h2>
          </div>
          <div class="card-body">
            <table v-if="users.length > 0">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>昵称</th>
                  <th>邮箱</th>
                  <th>注册时间</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="user in users" :key="user.id">
                  <td>{{ user.id }}</td>
                  <td>{{ user.nickname }}</td>
                  <td>{{ user.email }}</td>
                  <td>{{ formatDate(user.createdAt) }}</td>
                </tr>
              </tbody>
            </table>
            <p v-else style="color: #999; text-align: center; padding: 40px;">暂无数据</p>
            
            <div class="pagination" v-if="users.length > 0">
              <div class="page-size-selector">
                <label>每页显示：</label>
                <select v-model="userPageSize" @change="loadUsers(1)">
                  <option :value="5">5 条</option>
                  <option :value="10">10 条</option>
                  <option :value="20">20 条</option>
                  <option :value="50">50 条</option>
                  <option :value="100">100 条</option>
                </select>
              </div>
              <button :disabled="userPage === 1" @click="loadUsers(userPage - 1)">上一页</button>
              <span>第 {{ userPage }} 页{{ userTotalPages > 0 ? ' / 共 ' + userTotalPages + ' 页' : '' }}</span>
              <button :disabled="userPage >= userTotalPages" @click="loadUsers(userPage + 1)">下一页</button>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="card-header">
            <h2>🎯 目标列表</h2>
          </div>
          <div class="card-body">
            <table v-if="goals.length > 0">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>目标名称</th>
                  <th>Emoji</th>
                  <th>创建人 ID</th>
                  <th>总天数</th>
                  <th>状态</th>
                  <th>创建时间</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="goal in goals" :key="goal.id">
                  <td>{{ goal.id }}</td>
                  <td>{{ goal.name }}</td>
                  <td>{{ goal.emoji || '-' }}</td>
                  <td>{{ goal.userId }}</td>
                  <td>{{ goal.totalDays }}</td>
                  <td>
                    <span :class="['status-badge', goal.status.toLowerCase()]">
                      {{ translateStatus(goal.status) }}
                    </span>
                  </td>
                  <td>{{ formatDate(goal.createdAt) }}</td>
                </tr>
              </tbody>
            </table>
            <p v-else style="color: #999; text-align: center; padding: 40px;">暂无数据</p>
            
            <div class="pagination" v-if="goals.length > 0">
              <div class="page-size-selector">
                <label>每页显示：</label>
                <select v-model="goalPageSize" @change="loadGoals(1)">
                  <option :value="5">5 条</option>
                  <option :value="10">10 条</option>
                  <option :value="20">20 条</option>
                  <option :value="50">50 条</option>
                  <option :value="100">100 条</option>
                </select>
              </div>
              <button :disabled="goalPage === 1" @click="loadGoals(goalPage - 1)">上一页</button>
              <span>第 {{ goalPage }} 页{{ goalTotalPages > 0 ? ' / 共 ' + goalTotalPages + ' 页' : '' }}</span>
              <button :disabled="goalPage >= goalTotalPages" @click="loadGoals(goalPage + 1)">下一页</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api'

const router = useRouter()
const stats = ref({})
const users = ref([])
const goals = ref([])
const userPage = ref(1)
const goalPage = ref(1)
const userPageSize = ref(10)
const goalPageSize = ref(10)
const userTotalPages = ref(0)
const goalTotalPages = ref(0)

onMounted(async () => {
  await loadStats()
  await loadUsers()
  await loadGoals()
})

// 监听 pageSize 变化，自动重新加载数据
watch([userPageSize, goalPageSize], () => {
  if (userPage !== 1) loadUsers(1)
  if (goalPage !== 1) loadGoals(1)
})

const loadStats = async () => {
  try {
    const response = await api.get('/admin/stats')
    stats.value = response.data
  } catch (error) {
    console.error('加载统计数据失败:', error)
  }
}

const loadUsers = async (page = 1) => {
  try {
    userPage.value = page
    const response = await api.get(`/admin/users?page=${page}&size=${userPageSize.value}`)
    users.value = response.data.content || []
    // 计算总页数
    const totalElements = response.data.totalElements || 0
    userTotalPages.value = Math.ceil(totalElements / userPageSize.value)
  } catch (error) {
    console.error('加载用户失败:', error)
  }
}

const loadGoals = async (page = 1) => {
  try {
    goalPage.value = page
    const response = await api.get(`/admin/goals?page=${page}&size=${goalPageSize.value}`)
    goals.value = response.data.content || []
    // 计算总页数
    const totalElements = response.data.totalElements || 0
    goalTotalPages.value = Math.ceil(totalElements / goalPageSize.value)
  } catch (error) {
    console.error('加载目标失败:', error)
  }
}

const formatDate = (dateStr) => {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleDateString('zh-CN')
}

const translateStatus = (status) => {
  const statusMap = {
    'ACTIVE': '进行中',
    'COMPLETED': '已完成',
    'ARCHIVED': '已归档'
  }
  return statusMap[status] || status
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

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.stat-card {
  background: white;
  padding: 25px;
  border-radius: 10px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
}

.stat-icon {
  font-size: 40px;
  margin-bottom: 10px;
}

.stat-value {
  font-size: 32px;
  font-weight: bold;
  color: #333;
  margin-bottom: 5px;
}

.stat-label {
  color: #666;
  font-size: 14px;
}

.content-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
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
}

.card-header h2 {
  font-size: 18px;
  color: #333;
}

.card-body {
  padding: 20px;
}

table {
  width: 100%;
  border-collapse: collapse;
}

th, td {
  padding: 12px;
  text-align: left;
  border-bottom: 1px solid #eee;
}

th {
  background: #f8f9fa;
  color: #666;
  font-weight: 600;
  font-size: 13px;
}

.badge {
  display: inline-block;
  padding: 4px 12px;
  background: #667eea;
  color: white;
  border-radius: 12px;
  font-size: 12px;
}

.status-badge {
  display: inline-block;
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 500;
}

.status-badge.active {
  background: #dbeafe;
  color: #1e40af;
}

.status-badge.completed {
  background: #d1fae5;
  color: #065f46;
}

.status-badge.archived {
  background: #f3f4f6;
  color: #374151;
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 15px;
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #eee;
}

.page-size-selector {
  display: flex;
  align-items: center;
  gap: 8px;
}

.page-size-selector label {
  font-size: 14px;
  color: #666;
}

.page-size-selector select {
  padding: 6px 12px;
  border: 2px solid #e0e0e0;
  border-radius: 6px;
  font-size: 14px;
  cursor: pointer;
}

.pagination button {
  padding: 8px 16px;
  border: 2px solid #e0e0e0;
  background: white;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s;
}

.pagination button:hover:not(:disabled) {
  background: #667eea;
  color: white;
  border-color: #667eea;
}

.pagination button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.progress-bar {
  background: #e0e0e0;
  border-radius: 10px;
  height: 8px;
  overflow: hidden;
  width: 100px;
  display: inline-block;
  vertical-align: middle;
  margin-right: 10px;
}

.progress-fill {
  background: linear-gradient(90deg, #667eea, #764ba2);
  height: 100%;
}
</style>
