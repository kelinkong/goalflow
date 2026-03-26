<template>
  <div class="users-page">
    <nav class="navbar">
      <div class="navbar-brand">🎯 GoalFlow Admin</div>
      <div class="navbar-menu">
        <router-link to="/dashboard">仪表盘</router-link>
        <router-link to="/users" class="active">用户</router-link>
        <router-link to="/templates">模板审核</router-link>
        <router-link to="/logs">日志</router-link>
        <a @click="handleLogout" style="cursor: pointer;">退出</a>
      </div>
    </nav>

    <div class="container">
      <h1>👥 用户管理</h1>
      
      <div class="card">
        <div class="card-header">
          <h2>所有用户</h2>
        </div>
        <div class="card-body">
          <table v-if="users.length > 0">
            <thead>
              <tr>
                <th>ID</th>
                <th>昵称</th>
                <th>邮箱</th>
                <th>头像</th>
                <th>注册时间</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="user in users" :key="user.id">
                <td>{{ user.id }}</td>
                <td>{{ user.nickname }}</td>
                <td>{{ user.email }}</td>
                <td>
                  <img v-if="user.avatar" :src="user.avatar" :alt="user.nickname" style="width: 30px; height: 30px; border-radius: 50%;">
                  <span v-else style="color: #999;">无</span>
                </td>
                <td>{{ formatDate(user.createdAt) }}</td>
              </tr>
            </tbody>
          </table>
          <p v-else style="color: #999; text-align: center; padding: 40px;">暂无数据</p>
          
          <div class="pagination" v-if="users.length > 0">
            <div class="page-size-selector">
              <label>每页显示：</label>
              <select v-model="pageSize" @change="loadUsers(1)">
                <option :value="5">5 条</option>
                <option :value="10">10 条</option>
                <option :value="20">20 条</option>
                <option :value="50">50 条</option>
                <option :value="100">100 条</option>
              </select>
            </div>
            <button :disabled="currentPage === 1" @click="loadUsers(currentPage - 1)">上一页</button>
            <span>第 {{ currentPage }} 页{{ totalPages > 0 ? ' / 共 ' + totalPages + ' 页' : '' }}</span>
            <button :disabled="currentPage >= totalPages" @click="loadUsers(currentPage + 1)">下一页</button>
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
const users = ref([])
const currentPage = ref(1)
const totalPages = ref(0)
const pageSize = ref(10)

onMounted(async () => {
  await loadUsers()
})

// 监听 pageSize 变化，自动重新加载数据
watch(pageSize, () => {
  loadUsers(1)  // 改变每页大小时，回到第一页
})

const loadUsers = async (page = 1) => {
  try {
    currentPage.value = page
    const response = await api.get(`/admin/users?page=${page}&size=${pageSize.value}`)
    users.value = response.data.content || []
    // 计算总页数
    const totalElements = response.data.totalElements || 0
    totalPages.value = Math.ceil(totalElements / pageSize.value)
  } catch (error) {
    console.error('加载用户失败:', error)
  }
}

const formatDate = (dateStr) => {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleDateString('zh-CN')
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
</style>
