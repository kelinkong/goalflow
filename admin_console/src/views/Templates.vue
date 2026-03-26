<template>
  <div class="templates-page">
    <nav class="navbar">
      <div class="navbar-brand">🎯 GoalFlow Admin</div>
      <div class="navbar-menu">
        <router-link to="/dashboard">仪表盘</router-link>
        <router-link to="/users">用户</router-link>
        <router-link to="/templates" class="active">模板审核</router-link>
        <router-link to="/logs">日志</router-link>
        <a @click="handleLogout" style="cursor: pointer;">退出</a>
      </div>
    </nav>

      <div class="container">
      <div class="page-header">
        <h1>📋 模板审核</h1>
        <router-link to="/templates/create" class="btn-create">+ 创建模板</router-link>
      </div>
      
      <div class="tabs">
        <button 
          :class="{ active: activeTab === 'pending' }" 
          @click="activeTab = 'pending'"
        >
          待审核 ({{ pendingCount }})
        </button>
        <button 
          :class="{ active: activeTab === 'approved' }" 
          @click="activeTab = 'approved'"
        >
          已通过
        </button>
        <button 
          :class="{ active: activeTab === 'rejected' }" 
          @click="activeTab = 'rejected'"
        >
          已拒绝
        </button>
      </div>

      <!-- 待审核列表 -->
      <div v-if="activeTab === 'pending'" class="tab-content">
        <div class="card" v-for="template in pendingTemplates" :key="template.id">
          <div class="card-header">
            <h2>{{ template.name }}</h2>
            <span class="badge">{{ template.totalDays }}天</span>
          </div>
          <div class="card-body">
            <p class="description">{{ template.description }}</p>
            
            <div class="meta-info">
              <div><strong>创建者 ID:</strong> {{ template.ownerId }}</div>
              <div><strong>可见性:</strong> {{ template.visibility }}</div>
              <div><strong>标签:</strong> {{ template.tags || '-' }}</div>
              <div><strong>创建时间:</strong> {{ formatDate(template.createdAt) }}</div>
            </div>

            <div class="actions">
              <button class="btn-approve" @click="approveTemplate(template.id)">
                ✅ 通过
              </button>
              <button class="btn-reject" @click="showRejectModal(template.id)">
                ❌ 拒绝
              </button>
              <button class="btn-delete" @click="deleteTemplate(template.id)">
                🗑 删除
              </button>
            </div>
          </div>
        </div>
        
        <div v-if="pendingTemplates.length === 0" class="empty-state">
          <p>🎉 没有待审核的模板</p>
        </div>
      </div>

      <!-- 已通过列表 -->
      <div v-if="activeTab === 'approved'" class="tab-content">
        <div class="card" v-for="template in approvedTemplates" :key="template.id">
          <div class="card-header">
            <h2>{{ template.name }}</h2>
            <span class="badge success">✅ 已通过</span>
          </div>
          <div class="card-body">
            <p class="description">{{ template.description }}</p>
            <div class="meta-info">
              <div><strong>审核时间:</strong> {{ formatDateTime(template.reviewedAt) }}</div>
              <div><strong>审核人 ID:</strong> {{ template.reviewedBy }}</div>
            </div>
            <div class="actions">
              <button class="btn-delete" @click="deleteTemplate(template.id)">
                🗑 删除
              </button>
            </div>
          </div>
        </div>
        
        <div v-if="approvedTemplates.length === 0" class="empty-state">
          <p>暂无已通过的模板</p>
        </div>
      </div>

      <!-- 已拒绝列表 -->
      <div v-if="activeTab === 'rejected'" class="tab-content">
        <div class="card" v-for="template in rejectedTemplates" :key="template.id">
          <div class="card-header">
            <h2>{{ template.name }}</h2>
            <span class="badge danger">❌ 已拒绝</span>
          </div>
          <div class="card-body">
            <p class="description">{{ template.description }}</p>
            <div class="meta-info">
              <div><strong>拒绝原因:</strong> <span class="reject-reason">{{ template.rejectReason }}</span></div>
              <div><strong>审核时间:</strong> {{ formatDateTime(template.reviewedAt) }}</div>
              <div><strong>审核人 ID:</strong> {{ template.reviewedBy }}</div>
            </div>
            <div class="actions">
              <button class="btn-delete" @click="deleteTemplate(template.id)">
                🗑 删除
              </button>
            </div>
          </div>
        </div>
        
        <div v-if="rejectedTemplates.length === 0" class="empty-state">
          <p>暂无被拒绝的模板</p>
        </div>
      </div>
    </div>

    <!-- 拒绝原因弹窗 -->
    <div v-if="showRejectDialog" class="modal-overlay" @click.self="closeRejectModal">
      <div class="modal">
        <h3>拒绝原因</h3>
        <textarea 
          v-model="rejectReason" 
          placeholder="请输入拒绝原因..."
          rows="4"
        ></textarea>
        <div class="modal-actions">
          <button @click="closeRejectModal">取消</button>
          <button class="btn-danger" @click="submitReject">确认拒绝</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api'

const router = useRouter()
const activeTab = ref('pending')
const pendingTemplates = ref([])
const approvedTemplates = ref([])
const rejectedTemplates = ref([])
const showRejectDialog = ref(false)
const rejectReason = ref('')
const currentTemplateId = ref(null)

const pendingCount = computed(() => pendingTemplates.value.length)

onMounted(async () => {
  await loadPendingTemplates()
})

const loadPendingTemplates = async () => {
  try {
    const response = await api.get('/admin/templates/pending')
    pendingTemplates.value = response.data
  } catch (error) {
    console.error('加载待审核模板失败:', error)
  }
}

const loadApprovedTemplates = async () => {
  try {
    const response = await api.get('/admin/templates/reviewed?status=APPROVED')
    approvedTemplates.value = response.data
  } catch (error) {
    console.error('加载已通过模板失败:', error)
  }
}

const loadRejectedTemplates = async () => {
  try {
    const response = await api.get('/admin/templates/reviewed?status=REJECTED')
    rejectedTemplates.value = response.data
  } catch (error) {
    console.error('加载已拒绝模板失败:', error)
  }
}

// Tab 切换时加载对应数据
watch(activeTab, (newTab) => {
  if (newTab === 'approved') {
    loadApprovedTemplates()
  } else if (newTab === 'rejected') {
    loadRejectedTemplates()
  }
}, { immediate: true })

const approveTemplate = async (id) => {
  if (!confirm('确定要通过这个模板吗？')) return
  
  try {
    await api.post(`/admin/templates/${id}/approve`)
    alert('模板已通过！')
    await loadPendingTemplates()
  } catch (error) {
    alert('操作失败：' + error.message)
  }
}

const showRejectModal = (id) => {
  currentTemplateId.value = id
  rejectReason.value = ''
  showRejectDialog.value = true
}

const closeRejectModal = () => {
  showRejectDialog.value = false
  currentTemplateId.value = null
  rejectReason.value = ''
}

const submitReject = async () => {
  if (!rejectReason.value.trim()) {
    alert('请输入拒绝原因')
    return
  }
  
  try {
    await api.post(`/admin/templates/${currentTemplateId.value}/reject`, {
      reason: rejectReason.value
    })
    alert('模板已拒绝')
    closeRejectModal()
    await loadPendingTemplates()
  } catch (error) {
    alert('操作失败：' + error.message)
  }
}

const deleteTemplate = async (id) => {
  if (!confirm('确定要删除这个模板吗？已使用该模板创建的目标会保留，但会解除模板和排行榜关联。')) {
    return
  }

  try {
    await api.delete(`/admin/templates/${id}`)
    alert('模板已删除')
    if (activeTab.value === 'pending') {
      await loadPendingTemplates()
    } else if (activeTab.value === 'approved') {
      await loadApprovedTemplates()
    } else {
      await loadRejectedTemplates()
    }
  } catch (error) {
    const message = error.response?.data?.error || error.response?.data?.message || error.message
    alert('删除失败：' + message)
  }
}

const handleLogout = () => {
  localStorage.removeItem('token')
  router.push('/login')
}

const formatDate = (dateStr) => {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleDateString('zh-CN')
}

const formatDateTime = (dateStr) => {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleString('zh-CN')
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
  max-width: 1200px;
  margin: 0 auto;
  padding: 30px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  margin-bottom: 20px;
}

.page-header h1 {
  margin: 0;
}

.btn-create {
  text-decoration: none;
  background: #667eea;
  color: white;
  padding: 10px 16px;
  border-radius: 8px;
  font-weight: 600;
}

.container h1 {
  color: #333;
  font-size: 28px;
  margin-bottom: 30px;
}

.tabs {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}

.tabs button {
  padding: 10px 20px;
  border: 2px solid #e0e0e0;
  background: white;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
}

.tabs button.active {
  background: #667eea;
  color: white;
  border-color: #667eea;
}

.card {
  background: white;
  border-radius: 10px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  margin-bottom: 20px;
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
  margin: 0;
}

.badge {
  padding: 4px 12px;
  background: #667eea;
  color: white;
  border-radius: 12px;
  font-size: 12px;
}

.badge.success {
  background: #10b981;
}

.badge.danger {
  background: #ef4444;
}

.card-body {
  padding: 20px;
}

.description {
  color: #666;
  line-height: 1.6;
  margin-bottom: 20px;
}

.meta-info {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 6px;
  margin-bottom: 20px;
}

.meta-info div {
  margin-bottom: 8px;
  font-size: 14px;
}

.meta-info div:last-child {
  margin-bottom: 0;
}

.reject-reason {
  color: #ef4444;
}

.actions {
  display: flex;
  gap: 10px;
}

.btn-approve, .btn-reject, .btn-delete {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
}

.btn-approve {
  background: #10b981;
  color: white;
}

.btn-reject {
  background: #ef4444;
  color: white;
}

.btn-delete {
  background: #4b5563;
  color: white;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #999;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: white;
  padding: 30px;
  border-radius: 10px;
  width: 100%;
  max-width: 500px;
}

.modal h3 {
  margin-bottom: 20px;
  color: #333;
}

.modal textarea {
  width: 100%;
  padding: 12px;
  border: 2px solid #e0e0e0;
  border-radius: 6px;
  font-family: inherit;
  resize: vertical;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 20px;
}

.modal-actions button {
  padding: 10px 20px;
  border: 2px solid #e0e0e0;
  background: white;
  border-radius: 6px;
  cursor: pointer;
}

.modal-actions .btn-danger {
  background: #ef4444;
  color: white;
  border-color: #ef4444;
}
</style>
