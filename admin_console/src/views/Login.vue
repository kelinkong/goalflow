<template>
  <div class="login-container">
    <div class="login-box">
      <h1>🎯 GoalFlow</h1>
      <p style="color: #666; margin-bottom: 30px;">管理后台</p>
      
      <div v-if="error" class="error-message">{{ error }}</div>
      
      <form @submit.prevent="handleLogin">
        <div class="form-group">
          <label>邮箱</label>
          <input 
            type="email" 
            v-model="email" 
            required 
            autocomplete="username"
            placeholder="admin@goalflow.com"
          />
        </div>
        
        <div class="form-group">
          <label>密码</label>
          <input 
            type="password" 
            v-model="password" 
            required 
            autocomplete="current-password"
            placeholder="请输入密码"
          />
        </div>
        
        <button type="submit" class="btn-login">登录</button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api'

const router = useRouter()
const email = ref('')
const password = ref('')
const error = ref('')

const handleLogin = async () => {
  error.value = ''
  try {
    const response = await api.post('/auth/login', {
      email: email.value,
      password: password.value
    })
    
    if (response.data.token) {
      localStorage.setItem('token', response.data.token)
      try {
        await api.get('/admin/stats')
        router.push('/dashboard')
      } catch (authErr) {
        console.error('当前账号没有管理台权限:', authErr)
        localStorage.removeItem('token')
        const status = authErr.response?.status
        const message = authErr.response?.data?.message
        if (status === 401) {
          error.value = message || '登录状态已过期，请重新登录'
        } else if (status === 403) {
          error.value = message || '当前账号没有管理台权限'
        } else {
          error.value = message || '登录后校验管理台权限失败，请稍后重试'
        }
      }
    }
  } catch (err) {
    console.error('登录失败:', err)
    const status = err.response?.status
    const message = err.response?.data?.message
    if (status === 401) {
      error.value = message || '登录失败，请检查邮箱和密码'
    } else {
      error.value = message || '登录失败，请稍后重试'
    }
  }
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.login-box {
  background: white;
  padding: 40px;
  border-radius: 10px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
  width: 100%;
  max-width: 400px;
}

.login-box h1 {
  color: #333;
  font-size: 28px;
  margin-bottom: 10px;
  text-align: center;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  color: #555;
  font-weight: 500;
}

.form-group input {
  width: 100%;
  padding: 12px;
  border: 2px solid #e0e0e0;
  border-radius: 6px;
  font-size: 14px;
}

.form-group input:focus {
  outline: none;
  border-color: #667eea;
}

.btn-login {
  width: 100%;
  padding: 12px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
}

.btn-login:hover {
  opacity: 0.9;
}

.error-message {
  background: #fee;
  color: #c33;
  padding: 10px;
  border-radius: 6px;
  margin-bottom: 20px;
}

.default-credentials {
  margin-top: 20px;
  padding: 15px;
  background: #f5f5f5;
  border-radius: 6px;
  font-size: 13px;
  color: #666;
}
</style>
